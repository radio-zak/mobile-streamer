import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:logging/logging.dart';

// Data model for a single program
class Program {
  final String time;
  final String title;
  final String author;

  const Program({required this.time, required this.title, required this.author});
}

/// Fetches the schedule for all days of the week.
Future<Map<String, List<Program>>> fetchSchedule() async {
  final log = Logger('ScheduleFetcher');
  final headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36',
  };

  final days = {
    'Poniedziałek': 'poniedzialek',
    'Wtorek': 'wtorek',
    'Środa': 'sroda',
    'Czwartek': 'czwartek',
    'Piątek': 'piatek',
    'Sobota': 'sobota',
    'Niedziela': 'niedziela',
  };

  final scheduleMap = <String, List<Program>>{};

  for (int i = 0; i < days.keys.length; i++) {
    final dayName = days.keys.elementAt(i);
    final dayUrlPart = days.values.elementAt(i);
    final url = Uri.parse('https://www.zak.lodz.pl/ramowka/plan/${i + 1}/$dayUrlPart/');

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode != 200) {
        log.warning('Failed to load schedule for $dayName. Status: ${response.statusCode}');
        scheduleMap[dayName] = [];
        continue;
      }

      final document = html.parse(utf8.decode(response.bodyBytes));
      final programs = <Program>[];

      final programList = document.querySelector('ul#ramowka');
      if (programList == null) {
        log.warning('Could not find program list for $dayName');
        scheduleMap[dayName] = [];
        continue;
      }

      final programElements = programList.querySelectorAll('li.row');

      for (var element in programElements) {
        final time = element.querySelector('.godziny')?.text.trim() ?? '';
        final titleElement = element.querySelector('h3.tytul a');
        final fullTitle = titleElement?.text.trim() ?? '';
        final title = fullTitle.replaceFirst(RegExp(r'^\d{2}:\d{2} - \d{2}:\d{2}:\s*'), '');
        
        final descriptionDiv = element.querySelector('.opis');
        String author = '';
        if (descriptionDiv != null) {
            final authorPrefix = descriptionDiv.children.where((e) => e.text.contains('prowadzi:')).firstOrNull;
            if (authorPrefix != null) {
                final authorNode = authorPrefix.nextElementSibling;
                if(authorNode != null) {
                    author = authorNode.text.trim();
                }
            }
        }

        if (time.isNotEmpty && title.isNotEmpty) {
          programs.add(Program(time: time, title: title, author: author));
        }
      }
      scheduleMap[dayName] = programs;
    } catch (e) {
      log.severe('Error fetching or parsing schedule for $dayName', e);
      scheduleMap[dayName] = [];
    }
  }

  return scheduleMap;
}

/// Helper to check if a program is currently live based on its time string.
bool isProgramLive(Program program, int weekday) {
  final now = DateTime.now();
  if (now.weekday != weekday) return false;

  try {
    final parts = program.time.split(' - ');
    if (parts.length != 2) return false;

    final startTimeParts = parts[0].split(':');
    final endTimeParts = parts[1].split(':');

    final startHour = int.parse(startTimeParts[0]);
    final startMinute = int.parse(startTimeParts[1]);
    final endHour = int.parse(endTimeParts[0]);
    final endMinute = int.parse(endTimeParts[1]);

    final start = DateTime(now.year, now.month, now.day, startHour, startMinute);
    var end = DateTime(now.year, now.month, now.day, endHour, endMinute);

    // Handle overnight programs (e.g., 22:00 - 02:00)
    if (end.isBefore(start)) {
      end = end.add(const Duration(days: 1));
    }

    return now.isAfter(start) && now.isBefore(end);
  } catch (e) {
    return false;
  }
}
