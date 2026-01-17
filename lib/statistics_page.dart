import 'package:flutter/material.dart';
import 'package:zakstreamer/service_locator.dart';
import 'package:zakstreamer/statistics_service.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsData {
  final DateTime? installDate;
  final int totalListeningTime;
  final int longestSession;
  final int shortestSession;
  final String mostListenedDay;

  const _StatisticsData({
    required this.installDate,
    required this.totalListeningTime,
    required this.longestSession,
    required this.shortestSession,
    required this.mostListenedDay,
  });
}

class _StatisticsPageState extends State<StatisticsPage> {
  final StatisticsService _statisticsService = getIt<StatisticsService>();
  _StatisticsData? _data;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final results = await Future.wait([
      _statisticsService.getInstallDate(),
      _statisticsService.getTotalListeningTime(),
      _statisticsService.getLongestSession(),
      _statisticsService.getShortestSession(),
      _statisticsService.getMostListenedDay(),
    ]);

    if (!mounted) return;

    setState(() {
      _data = _StatisticsData(
        installDate: results[0] as DateTime?,
        totalListeningTime: results[1] as int,
        longestSession: results[2] as int,
        shortestSession: results[3] as int,
        mostListenedDay: results[4] as String,
      );
    });
  }

  String _pluralize(int count, String one, String few, String many) {
    if (count == 1) return one;
    if (count % 100 >= 11 && count % 100 <= 19) return many;
    final lastDigit = count % 10;
    if (lastDigit >= 2 && lastDigit <= 4) return few;
    return many;
  }

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    final hoursString = '$hours ${_pluralize(hours, 'godzina', 'godziny', 'godzin')}';
    final minutesString = '$minutes ${_pluralize(minutes, 'minuta', 'minuty', 'minut')}';

    if (hours > 0) {
      if (minutes == 0) return hoursString;
      return '$hoursString $minutesString';
    } else {
      return minutesString;
    }
  }

  String _formatInstallDate(DateTime? date) {
    if (date == null) return '';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day.$month.$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statystyki'),
      ),
      body: _data == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (_data!.totalListeningTime > 0) ...[
                  _StatisticRow(
                    label: 'Słuchasz Żaka już łącznie:',
                    value: _formatDuration(_data!.totalListeningTime),
                  ),
                  const Divider(),
                ],
                if (_data!.longestSession > 0) ...[
                  _StatisticRow(
                    label: 'Najdłuższa sesja:',
                    value: _formatDuration(_data!.longestSession),
                  ),
                  const Divider(),
                ],
                if (_data!.shortestSession > 0) ...[
                  _StatisticRow(
                    label: 'Najkrótsza sesja:',
                    value: _formatDuration(_data!.shortestSession),
                  ),
                  const Divider(),
                ],
                if (_data!.mostListenedDay != 'Brak danych') ...[
                  _StatisticRow(
                    label: 'Dzień, kiedy najczęściej słuchasz Żaka to:',
                    value: _data!.mostListenedDay,
                  ),
                  const Divider(),
                ],
                if (_data!.installDate != null) ...[
                  _StatisticRow(
                    label: 'Data instalacji ŻAK Playera:',
                    value: _formatInstallDate(_data!.installDate),
                  ),
                ],
              ],
            ),
    );
  }
}

class _StatisticRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatisticRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(value, style: textTheme.headlineSmall),
        ],
      ),
    );
  }
}
