import 'dart:convert';
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

      final startTime = DateTime(now.year, now.month, now.day, startHour, startMinute);
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
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36',
    };

    for (var dayName in _dayPaths.keys) {
      final path = _dayPaths[dayName]!;
      final response = await http.get(Uri.parse(_baseUrl + path), headers: headers);

      if (response.statusCode == 200) {
        _logger.info('zak.lodz.pl responded with status code 200, parsing...');
        final document = parser.parse(utf8.decode(response.bodyBytes));
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
            final descPrefixSpans = opisDiv.querySelectorAll('span.desc-prefix');
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

    // Sort the final map to ensure the days are in the correct order
    final sortedScheduleMap = <String, List<ScheduleEntry>>{};
    for (var day in _dayPaths.keys) {
      if (scheduleMap.containsKey(day)) {
        sortedScheduleMap[day] = scheduleMap[day]!;
      }
    }
    _logger.info("Schedule fetched");
    return sortedScheduleMap;
  }
}
