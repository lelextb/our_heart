import 'dart:developer' as dev;

import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

class LyricsifyScraperService {
  LyricsifyScraperService._();

  static const String _baseUrl = 'https://www.lyricsify.com';

  /// Searches Lyricsify for the given [title] and [artist] and returns
  /// raw LRC text if found, or `null` otherwise.
  static Future<String?> fetchLrc(String title, String artist) async {
    try {
      final searchQuery = Uri.encodeComponent('$artist $title');
      final searchUrl = '$_baseUrl/search?q=$searchQuery';

      final headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      };

      final searchResponse =
          await http.get(Uri.parse(searchUrl), headers: headers);
      if (searchResponse.statusCode != 200) return null;

      final searchDocument = parser.parse(searchResponse.body);

      // Try common selectors used by Lyricsify
      final songLinkElement = searchDocument.querySelector(
          'a.song-title, .search-results a, a[href^="/lyrics/"]');
      if (songLinkElement == null) {
        dev.log('Song not found on Lyricsify.');
        return null;
      }

      final partialPath = songLinkElement.attributes['href'];
      if (partialPath == null || partialPath.isEmpty) return null;

      final targetSongUrl = partialPath.startsWith('http')
          ? partialPath
          : '$_baseUrl$partialPath';

      final lyricPageResponse =
          await http.get(Uri.parse(targetSongUrl), headers: headers);
      if (lyricPageResponse.statusCode != 200) return null;

      final lyricDocument = parser.parse(lyricPageResponse.body);

      final lyricDiv = lyricDocument.querySelector(
          '#lyrics, .lyrics-body, div.lyrics');
      if (lyricDiv == null) return null;

      final rawLyricsText = lyricDiv.text.trim();

      if (rawLyricsText.contains('[') && rawLyricsText.contains(']')) {
        dev.log('Successfully scraped LRC from Lyricsify!');
        return rawLyricsText;
      }

      dev.log('Lyricsify container found but no timestamps.');
      return null;
    } catch (e) {
      dev.log('Lyricsify scraping failure: $e');
      return null;
    }
  }
}