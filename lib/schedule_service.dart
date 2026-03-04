import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

class ScheduleEntry {
  final String time;
  final String title;
  final String hosts;

  ScheduleEntry({required this.time, required this.title, required this.hosts});

  bool get isLive {
    try {
      final now = DateTime.now();
      final parts = time.split('-').map((e) => e.trim()).toList();
      if (parts.length != 2) return false;

      final startTimeParts = parts[0].split(':');
      final endTimeParts = parts[1].split(':');
      if (startTimeParts.length != 2 || endTimeParts.length != 2) return false;

      final startHour = int.parse(startTimeParts[0]);
      final startMinute = int.parse(startTimeParts[1]);
      final endHour = int.parse(endTimeParts[0]);
      final endMinute = int.parse(endTimeParts[1]);

      final startTime = DateTime(
        now.year,
        now.month,
        now.day,
        startHour,
        startMinute,
      );
      // The end time could be on the next day
      var endTime = DateTime(now.year, now.month, now.day, endHour, endMinute);

      if (endTime.isBefore(startTime)) {
        endTime = endTime.add(const Duration(days: 1));
      }

      return now.isAfter(startTime) && now.isBefore(endTime);
    } catch (e) {
      return false;
    }
  }

  @override
  String toString() => '[$time] $title (Hosts: $hosts)';
}

class ScheduleService {
  final _logger = Logger('Main');
  final _baseUrl = 'https://www.zak.lodz.pl';
  final _dayPaths = {
    'Poniedziałek': '/ramowka/plan/1/poniedzialek/',
    'Wtorek': '/ramowka/plan/2/wtorek/',
    'Środa': '/ramowka/plan/3/sroda/',
    'Czwartek': '/ramowka/plan/4/czwartek/',
    'Piątek': '/ramowka/plan/5/piatek/',
    'Sobota': '/ramowka/plan/6/sobota/',
    'Niedziela': '/ramowka/plan/7/niedziela/',
  };

  Future<Map<String, List<ScheduleEntry>>> fetchSchedule() async {
    final scheduleMap = <String, List<ScheduleEntry>>{};
    final headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36',
    };

    for (var dayName in _dayPaths.keys) {
      final path = _dayPaths[dayName]!;
      final response = await http.get(
        Uri.parse(_baseUrl + path),
        headers: headers,
      );

      if (response.statusCode == 200) {
        _logger.info('zak.lodz.pl responded with status code 200, parsing...');
        final document = parser.parse(utf8.decode(response.bodyBytes));
        final entries = <ScheduleEntry>[];

        final entryElements = document.querySelectorAll('ul#ramowka > li.row');

        for (var entryElement in entryElements) {
          final time =
              entryElement.querySelector('div.godziny')?.text.trim() ?? '';

          String title = '';
          final aTag = entryElement.querySelector('h3.tytul > a');
          if (aTag != null) {
            final aClone = aTag.clone(true);
            aClone.querySelector('span.show-for-small')?.remove();
            title = aClone.text.trim();
          }

          String hosts = '';
          final opisDiv = entryElement.querySelector('div.opis');
          if (opisDiv != null) {
            final descPrefixSpans = opisDiv.querySelectorAll(
              'span.desc-prefix',
            );
            for (var span in descPrefixSpans) {
              if (span.text.trim().startsWith('prowadz')) {
                final hostSpan = span.nextElementSibling;
                if (hostSpan != null && hostSpan.localName == 'span') {
                  hosts = hostSpan.text.trim();
                  break;
                }
              }
            }
          }

          if (time.isNotEmpty && title.isNotEmpty) {
            entries.add(ScheduleEntry(time: time, title: title, hosts: hosts));
          }
        }
        if (entries.isNotEmpty) {
          scheduleMap[dayName] = entries;
        }
      } else {
        _logger.severe(
          'Failed to load schedule for $dayName. Status code: ${response.statusCode}',
        );
      }
    }

    if (scheduleMap.isEmpty) {
      _logger.severe('Failed to fetch schedule from zak.lodz.pl');
    }

    // IMPORTANT: Always return all 7 days in order, even if some are empty
    // This prevents IndexOutOfBounds errors when accessing by weekday
    final sortedScheduleMap = <String, List<ScheduleEntry>>{};
    for (var day in _dayPaths.keys) {
      if (scheduleMap.containsKey(day)) {
        sortedScheduleMap[day] = scheduleMap[day]!;
      } else {
        // Add empty list for days that failed to load
        sortedScheduleMap[day] = [];
      }
    }
    _logger.info("Schedule fetched (${sortedScheduleMap.values.where((e) => e.isNotEmpty).length}/7 days have entries)");
    return sortedScheduleMap;
  }

  /// Fetches schedule for background isolate with relaxed SSL verification
  /// Used by background_service.dart since it doesn't have access to HARICA certificate
  Future<Map<String, List<ScheduleEntry>>> fetchScheduleBackground() async {
    try {
      // Create HTTP client with disabled certificate verification for background isolate
      final client = http.Client();

      // For background isolate, we'll use a custom HttpClient that accepts all certificates
      final httpClient = HttpClient();
      httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) => true;

      final scheduleMap = <String, List<ScheduleEntry>>{};

      for (var dayName in _dayPaths.keys) {
        try {
          final path = _dayPaths[dayName]!;
          final uri = Uri.parse(_baseUrl + path);

          final request = httpClient.getUrl(uri);
          final resolvedRequest = await request;
          resolvedRequest.headers.add('User-Agent',
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36');

          final response = await resolvedRequest.close();

          if (response.statusCode == 200) {
            _logger.info('zak.lodz.pl (background) responded with status code 200, parsing...');

            final bodyBytes = await response.fold<List<int>>(<int>[], (acc, chunk) => acc..addAll(chunk));
            final document = parser.parse(utf8.decode(bodyBytes));
            final entries = <ScheduleEntry>[];

            final entryElements = document.querySelectorAll('ul#ramowka > li.row');

            for (var entryElement in entryElements) {
              final time = entryElement.querySelector('div.godziny')?.text.trim() ?? '';
              String title = '';
              final aTag = entryElement.querySelector('h3.tytul > a');
              if (aTag != null) {
                final aClone = aTag.clone(true);
                aClone.querySelector('span.show-for-small')?.remove();
                title = aClone.text.trim();
              }

              String hosts = '';
              final opisDiv = entryElement.querySelector('div.opis');
              if (opisDiv != null) {
                final hostSpan = opisDiv.querySelector('span');
                if (hostSpan != null) {
                  hosts = hostSpan.text.trim();
                  if (hosts.startsWith('Prowadzący: ')) {
                    hosts = hosts.substring('Prowadzący: '.length);
                  }
                }
              }

              if (time.isNotEmpty && title.isNotEmpty) {
                entries.add(ScheduleEntry(time: time, title: title, hosts: hosts));
              }
            }
            if (entries.isNotEmpty) {
              scheduleMap[dayName] = entries;
            }
          } else {
            _logger.severe(
              'Failed to load schedule for $dayName. Status code: ${response.statusCode}',
            );
          }
        } catch (e) {
          _logger.warning('Error fetching schedule for $dayName: $e');
        }
      }

      httpClient.close();

      if (scheduleMap.isEmpty) {
        _logger.severe('Failed to fetch schedule from zak.lodz.pl (background)');
      }

      // IMPORTANT: Always return all 7 days in order, even if some are empty
      // This prevents IndexOutOfBounds errors when accessing by weekday
      final sortedScheduleMap = <String, List<ScheduleEntry>>{};
      for (var day in _dayPaths.keys) {
        if (scheduleMap.containsKey(day)) {
          sortedScheduleMap[day] = scheduleMap[day]!;
        } else {
          // Add empty list for days that failed to load
          sortedScheduleMap[day] = [];
        }
      }
      _logger.info("Schedule fetched (background, ${sortedScheduleMap.values.where((e) => e.isNotEmpty).length}/7 days have entries)");
      return sortedScheduleMap;
    } catch (e) {
      _logger.severe('Error in fetchScheduleBackground: $e');
      rethrow;
    }
  }
}

