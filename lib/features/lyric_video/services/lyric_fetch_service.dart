// lib/features/lyric_video/services/lyric_fetch_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:http/http.dart' as http;

import '../models/lyric_line.dart';
import '../models/track.dart';
import 'lyricsify_scraper_service.dart';

class LyricFetchService {
  LyricFetchService._();

  static const _lrcLibUrl = 'https://lrclib.net/api/search';
  static const _rentanAdviserBase =
      'https://www.rentanadviser.com/en/subtitles/getsubtitle.aspx';
  static const _rentanAdviserSearch =
      'https://www.rentanadviser.com/subtitles/subtitlesforsongs.aspx';

  /// Fetches synced lyrics from LRCLIB, RentAnAdviser, and Lyricsify
  /// simultaneously.  The first non‑empty result wins.
  static Future<List<LyricLine>> fetchLyrics({
    required String trackName,
    required String artistName,
  }) async {
    final completer = Completer<List<LyricLine>>();

    int pending = 3;
    Object? lastError;

    void onResult(List<LyricLine>? lines) {
      if (completer.isCompleted) return;
      pending--;
      if (lines != null && lines.isNotEmpty) {
        completer.complete(lines);
      } else if (pending == 0) {
        completer.completeError(
          lastError ??
              Exception(
                  'No synced lyrics found for "$trackName" by "$artistName"'),
        );
      }
    }

    void onError(Object e) {
      if (completer.isCompleted) return;
      pending--;
      lastError = e;
      if (pending == 0) {
        completer.completeError(lastError!);
      }
    }

    _fetchFromLrcLib(trackName, artistName).then(onResult, onError: onError);
    _fetchFromRentanAdviser(trackName, artistName)
        .then(onResult, onError: onError);
    _fetchFromLyricsify(trackName, artistName)
        .then(onResult, onError: onError);

    return completer.future;
  }

  // ---------------------------------------------------------------------------
  // LRCLIB
  // ---------------------------------------------------------------------------
  static Future<List<LyricLine>?> _fetchFromLrcLib(
      String trackName, String artistName) async {
    final query = '$trackName $artistName';
    final uri = Uri.parse('$_lrcLibUrl?q=${Uri.encodeQueryComponent(query)}');
    dev.log('LRCLIB request: $uri');
    final response = await http.get(uri);
    if (response.statusCode != 200) return null;
    final List<dynamic> results;
    try {
      results = jsonDecode(response.body) as List<dynamic>;
    } catch (_) {
      return null;
    }
    if (results.isEmpty) return null;
    dynamic best;
    for (final r in results) {
      if (r is Map<String, dynamic> && r['syncedLyrics'] != null) {
        best = r;
        break;
      }
    }
    if (best == null) return null;
    final raw = best['syncedLyrics'] as String?;
    if (raw == null || raw.trim().isEmpty) return null;
    return parseLrc(raw);
  }

  // ---------------------------------------------------------------------------
  // RentAnAdviser direct fetch
  // ---------------------------------------------------------------------------
  static Future<List<LyricLine>?> _fetchFromRentanAdviser(
      String artist, String song) async {
    final uri = Uri.parse(
        '$_rentanAdviserBase?artist=${Uri.encodeQueryComponent(artist)}'
        '&song=${Uri.encodeQueryComponent(song)}&type=lrc');
    dev.log('RentAnAdviser request: $uri');
    final response = await http.get(uri, headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Referer': 'https://www.rentanadviser.com/',
    });
    if (response.statusCode != 200) return null;
    return _extractLrcFromHtml(response.body);
  }

  // ---------------------------------------------------------------------------
  // Lyricsify
  // ---------------------------------------------------------------------------
  static Future<List<LyricLine>?> _fetchFromLyricsify(
      String title, String artist) async {
    final raw = await LyricsifyScraperService.fetchLrc(title, artist);
    if (raw == null || raw.trim().isEmpty) return null;
    return parseLrc(raw);
  }

  // ---------------------------------------------------------------------------
  // RentAnAdviser search
  // ---------------------------------------------------------------------------
  static Future<List<Track>> searchRentanAdviser(String query) async {
    final uri = Uri.parse(
        '$_rentanAdviserSearch?search=${Uri.encodeQueryComponent(query)}');
    dev.log('RentAnAdviser search: $uri');
    final response = await http.get(uri, headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Referer': 'https://www.rentanadviser.com/',
    });
    if (response.statusCode != 200) {
      throw Exception(
          'RentAnAdviser search failed with status ${response.statusCode}');
    }
    final body = response.body;
    final linkPattern = RegExp(
      r'<a\s+(?:[^>]*?\s+)?href="(/en/subtitles/getsubtitle\.aspx\?artist=[^&]*&song=[^&]*&type=lrc)"[^>]*>(.*?)</a>',
      caseSensitive: false,
      dotAll: true,
    );
    final tracks = <Track>[];
    final seen = <String>{};
    for (final match in linkPattern.allMatches(body)) {
      final href = match.group(1)!;
      final text = _stripHtml(match.group(2)!);
      String artist = '';
      String title = '';
      if (text.contains(' - ')) {
        final parts = text.split(' - ');
        artist = parts[0].trim();
        title = parts.sublist(1).join(' - ').trim();
      } else {
        title = text.trim();
      }
      final fullUrl = 'https://www.rentanadviser.com$href';
      final key = '$artist|$title';
      if (seen.contains(key)) continue;
      seen.add(key);
      tracks.add(Track(
        id: fullUrl,
        title: title.isNotEmpty ? title : text.trim(),
        artist: artist.isNotEmpty ? artist : 'Unknown',
        thumbnailUrl: '',
      ));
    }
    if (tracks.isEmpty) {
      throw Exception('No results found on RentAnAdviser for "$query".');
    }
    return tracks;
  }

  static Future<List<LyricLine>> fetchLrcFromUrl(String url) async {
    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Referer': 'https://www.rentanadviser.com/',
    });
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to fetch lyrics from RentAnAdviser (${response.statusCode})');
    }
    final lyrics = _extractLrcFromHtml(response.body);
    if (lyrics == null || lyrics.isEmpty) {
      throw Exception('No synced lyrics found at $url');
    }
    return lyrics;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static List<LyricLine>? _extractLrcFromHtml(String html) {
    final timestampPattern = RegExp(r'^\[(\d{2}):(\d{2})\.(\d{2})\](.*?)$',
        multiLine: true);
    final matches = timestampPattern.allMatches(html).toList();
    if (matches.isEmpty) return null;
    final buffer = StringBuffer();
    for (final m in matches) {
      buffer.writeln(m.group(0)!.trim());
    }
    return parseLrc(buffer.toString());
  }

  static List<LyricLine> parseLrc(String lrc) {
    final lines = <LyricLine>[];
    final timestampRegex = RegExp(r'\[(\d{1,3}):(\d{2})(?:\.(\d{1,3}))?\]');
    for (final raw in lrc.split('\n')) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      final matches = timestampRegex.allMatches(trimmed).toList();
      if (matches.isEmpty) continue;
      int lastMatchEnd = 0;
      for (final m in matches) {
        lastMatchEnd = m.end;
      }
      final text = trimmed.substring(lastMatchEnd).trim();
      if (text.isEmpty) continue;
      for (final m in matches) {
        final minutes = int.parse(m.group(1)!);
        final seconds = int.parse(m.group(2)!);
        final centis = m.group(3) != null
            ? int.parse(m.group(3)!.padRight(2, '0'))
            : 0;
        final totalMs = (minutes * 60 + seconds) * 1000 + (centis * 10);
        lines.add(LyricLine(milliseconds: totalMs, text: text));
      }
    }
    lines.sort((a, b) => a.milliseconds.compareTo(b.milliseconds));
    return lines;
  }

  static String _stripHtml(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }
}