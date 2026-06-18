import 'package:http/http.dart' as http;
import 'dart:convert';

class RecentlyPlayedEntry {
  final String time;
  final String artist;
  final String title;
  final String? imageUrl;

  RecentlyPlayedEntry({
    required this.time,
    required this.artist,
    required this.title,
    this.imageUrl,
  });

  RecentlyPlayedEntry copyWith({String? imageUrl}) {
    return RecentlyPlayedEntry(
      time: time,
      artist: artist,
      title: title,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  String toString() => '$time: $artist - $title';
}

class RecentlyPlayedService {
  final String _url = 'https://www.zak.lodz.pl/ostatnio_wyemitowane.txt';

  // Cache zapobiegający wielokrotnym zapytaniom o ten sam utwór
  static final Map<String, String?> _artworkCache = {};

  Future<List<RecentlyPlayedEntry>> fetchRecentlyPlayed() async {
    try {
      final response = await http
          .get(
            Uri.parse(_url),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Błąd serwera: ${response.statusCode}');
      }

      final content = utf8.decode(response.bodyBytes, allowMalformed: true);
      final baseEntries = _parseContent(content);

      // Optymalizacja: pobieramy okładki tylko dla 15 najnowszych utworów
      final recentEntries = baseEntries.take(15).toList();
      final olderEntries = baseEntries.skip(15).toList();

      final entriesWithArt = await Future.wait(
        recentEntries.map((entry) async {
          final cacheKey = '${entry.artist}-${entry.title}';
          if (_artworkCache.containsKey(cacheKey)) {
            return entry.copyWith(imageUrl: _artworkCache[cacheKey]);
          }

          try {
            final artUrl = await _getArtwork(
              entry.artist,
              entry.title,
            ).timeout(const Duration(seconds: 2));
            _artworkCache[cacheKey] = artUrl;
            return entry.copyWith(imageUrl: artUrl);
          } catch (_) {
            return entry; // W razie błędu/timeoutu zwracamy wpis bez zdjęcia
          }
        }),
      );

      return [...entriesWithArt, ...olderEntries];
    } catch (e) {
      print('RecentlyPlayedService Error: $e');
      rethrow;
    }
  }

  Future<String?> _getArtwork(String artist, String title) async {
    if (artist == 'Radio Żak' ||
        artist.isEmpty ||
        artist.toLowerCase().contains('żak'))
      return null;

    // 1. Try iTunes
    final itunesUrl = await _fetchFromItunes(artist, title);
    if (itunesUrl != null) return itunesUrl;

    // 2. Fallback to Deezer
    return await _fetchFromDeezer(artist, title);
  }

  Future<String?> _fetchFromItunes(String artist, String title) async {
    try {
      final query = Uri.encodeComponent('$artist $title');
      final response = await http
          .get(
            Uri.parse(
              'https://itunes.apple.com/search?term=$query&entity=song&limit=1',
            ),
          )
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['resultCount'] > 0) {
          final artwork = data['results'][0]['artworkUrl100'] as String;
          // Upgrade to 300x300 for better quality but keeping it light
          return artwork.replaceAll('100x100bb', '300x300bb');
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _fetchFromDeezer(String artist, String title) async {
    try {
      final query = Uri.encodeComponent('artist:"$artist" track:"$title"');
      final response = await http
          .get(Uri.parse('https://api.deezer.com/search?q=$query&limit=1'))
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && (data['data'] as List).isNotEmpty) {
          return data['data'][0]['album']['cover_medium'] as String;
        }
      }
    } catch (_) {}
    return null;
  }

  List<RecentlyPlayedEntry> _parseContent(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    final List<RecentlyPlayedEntry> entries = [];

    // Regex capturing only HH:mm (Group 1). Optional seconds are matched but outside the group.
    final regex = RegExp(
      r'^\d{4}\.\d{2}\.\d{2}\s+(\d{2}:\d{2})(?::\d{2})?\s+(.*?):\s+(.*)$',
    );

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      final match = regex.firstMatch(line);
      if (match != null) {
        entries.add(
          RecentlyPlayedEntry(
            time: match.group(1)!, // HH:mm
            artist: match.group(2)!.trim(),
            title: match.group(3)!.trim(),
          ),
        );
      } else {
        final colonIndex = line.indexOf(':');
        if (colonIndex != -1) {
          final firstPart = line.substring(0, colonIndex).trim();
          final title = line.substring(colonIndex + 1).trim();

          final timeMatch = RegExp(
            r'(\d{2}:\d{2})(?::\d{2})?$',
          ).firstMatch(firstPart);
          if (timeMatch != null) {
            final time = timeMatch.group(1)!; // HH:mm
            final fullTimeStr = timeMatch.group(0)!;
            final artist = firstPart.replaceFirst(fullTimeStr, '').trim();
            entries.add(
              RecentlyPlayedEntry(
                time: time,
                artist: artist.isEmpty ? 'Radio Żak' : artist,
                title: title,
              ),
            );
          }
        }
      }
    }
    return entries.reversed.toList();
  }
}
