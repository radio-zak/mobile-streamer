import 'package:flutter/material.dart';
import 'package:zakstreamer/service_locator.dart';
import 'package:zakstreamer/statistics_service.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final StatisticsService _statisticsService = getIt<StatisticsService>();
  DateTime? _installDate;
  int _totalListeningTime = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final installDate = await _statisticsService.getInstallDate();
    final totalListeningTime = await _statisticsService.getTotalListeningTime();
    setState(() {
      _installDate = installDate;
      _totalListeningTime = totalListeningTime;
    });
  }

  String _formatTotalTime(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours godzin $minutes minut';
    } else {
      return '$minutes minut';
    }
  }

  String _formatInstallDate(DateTime? date) {
    if (date == null) return 'Brak danych';
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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _StatisticRow(
            label: 'Słuchasz Żaka już łącznie:',
            value: _formatTotalTime(_totalListeningTime),
          ),
          const Divider(),
          // TODO: Implement other statistics
          _StatisticRow(
            label: 'Data instalacji ŻAK Playera:',
            value: _formatInstallDate(_installDate),
          ),
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
