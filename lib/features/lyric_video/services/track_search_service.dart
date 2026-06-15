// lib/features/lyric_video/services/track_search_service.dart

import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:ytmusicapi_dart/enums.dart';
import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

import '../models/track.dart';

/// Full‑service track search + audio extraction using YouTube Music.
/// Downloads audio to a local file to permanently bypass 403 errors.
class TrackSearchService {
  TrackSearchService._();

  static YTMusic? _ytMusicInstance;
  static final _ytExplode = yt.YoutubeExplode();

  static Future<YTMusic> _ensureInitialized() async {
    _ytMusicInstance ??= await YTMusic.create();
    return _ytMusicInstance!;
  }

  /// Searches YouTube Music for [query] and returns up to 15 tracks.
  static Future<List<Track>> search(String query) async {
    final ytMusic = await _ensureInitialized();

    final results = await ytMusic.search(query, filter: SearchFilter.songs);
    final tracks = <Track>[];

    for (final item in results) {
      if (item is! Map<String, dynamic>) continue;

      final videoId = item['videoId'] as String?;
      final title = item['title'] as String? ?? '';
      final artist = (item['artists'] as List<dynamic>?)
              ?.map((a) => (a as Map<String, dynamic>)['name'] as String)
              .join(', ') ??
          '';
      final thumb = (item['thumbnails'] as List<dynamic>?)
              ?.last?['url'] as String? ??
          '';

      if (videoId != null && title.isNotEmpty) {
        tracks.add(Track(
          id: videoId,
          title: title,
          artist: artist,
          thumbnailUrl: thumb,
        ));
      }
      if (tracks.length >= 15) break;
    }

    if (tracks.isEmpty) {
      throw Exception('No results found for "$query".');
    }

    return tracks;
  }

  /// Returns a direct, signed audio stream URL for the given [videoId].
  /// Prefers M4A container to avoid 403.
  static Future<String?> getAudioStreamUrl(String videoId) async {
    try {
      final manifest =
          await _ytExplode.videos.streams.getManifest(yt.VideoId(videoId));

      // FIX: force M4A container for continuous download
      final audioOnly = manifest.audioOnly;
      final m4aStreams = audioOnly.where((e) => e.container.name == 'm4a');
      if (m4aStreams.isNotEmpty) {
        return m4aStreams.withHighestBitrate().url.toString();
      }

      // fallback to any audio
      if (audioOnly.isEmpty) return null;
      return audioOnly.withHighestBitrate().url.toString();
    } catch (e) {
      dev.log('getAudioStreamUrl error: $e');
      return null;
    }
  }

  /// Returns the HTTP headers that must be passed to the audio player.
  static Map<String, String> getRequestHeaders() {
    return {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Referer': 'https://youtube.com',
      'Origin': 'https://youtube.com',
    };
  }

  /// Downloads the audio stream to a local file.
  /// Returns the local file path, or null on failure.
  /// Optionally accepts [cookies] string for authenticated access.
  static Future<String?> downloadAudio({
    required String videoId,
    String? cookies,
  }) async {
    try {
      final url = await getAudioStreamUrl(videoId);
      if (url == null) return null;

      final headers = Map<String, String>.from(getRequestHeaders());
      if (cookies != null) {
        headers['Cookie'] = cookies;
      }

      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(headers);
      final httpClient = http.Client();
      final streamedResponse = await httpClient.send(request);

      if (streamedResponse.statusCode != 200) {
        throw Exception('Server error: ${streamedResponse.statusCode}');
      }

      final dir = await getTemporaryDirectory();
      final filePath = p.join(dir.path, 'audio_${videoId}.m4a');
      final file = File(filePath);
      final sink = file.openWrite();

      await for (final chunk in streamedResponse.stream) {
        sink.add(chunk);
      }

      await sink.close();
      httpClient.close();
      return filePath;
    } catch (e) {
      dev.log('Audio download error: $e');
      return null;
    }
  }

  /// Releases native resources.
  static void dispose() {
    _ytMusicInstance?.close();
    _ytExplode.close();
  }
}