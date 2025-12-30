import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

class ScheduleEntry {
  final String time;
  final String title;

  ScheduleEntry({required this.time, required this.title});

  @override
  String toString() => '[$time] $title';
}

class ScheduleService {
  final _url = Uri.parse('https://www.zak.lodz.pl/ramowka');

  Future<Map<String, List<ScheduleEntry>>> fetchSchedule() async {
    final response = await http.get(_url);
    if (response.statusCode != 200) {
      throw Exception('Failed to load schedule. Status code: ${response.statusCode}');
    }

    final document = parser.parse(response.body);
    final scheduleMap = <String, List<ScheduleEntry>>{};

    final dayElements = document.querySelectorAll('.ramowka-dzien');

    for (var dayElement in dayElements) {
      final dayTitle = dayElement.querySelector('.dzien-title')?.text.trim();
      if (dayTitle != null && dayTitle.isNotEmpty) {
        final entries = <ScheduleEntry>[];
        final entryElements = dayElement.querySelectorAll('.ramowka-wpis');
        for (var entryElement in entryElements) {
          final time = entryElement.querySelector('.ramowka-godzina')?.text.trim() ?? '';
          final title = entryElement.querySelector('.ramowka-tytul')?.text.trim() ?? '';
          if (time.isNotEmpty && title.isNotEmpty) {
            entries.add(ScheduleEntry(time: time, title: title));
          }
        }
        scheduleMap[dayTitle] = entries;
      }
    }
    return scheduleMap;
  }
}
