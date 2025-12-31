import 'package:flutter/material.dart';
import 'service_locator.dart';
import 'schedule_service.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  Future<Map<String, List<ScheduleEntry>>>? _scheduleFuture;

  @override
  void initState() {
    super.initState();
    _scheduleFuture = getIt<ScheduleService>().fetchSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ramówka'),
      ),
      body: FutureBuilder<Map<String, List<ScheduleEntry>>>(
        future: _scheduleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Nie udało się załadować ramówki.\nBłąd: ${snapshot.error}', textAlign: TextAlign.center),
            ));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Brak danych ramówki.'));
          }

          final schedule = snapshot.data!;
          final days = schedule.keys.toList();

          return DefaultTabController(
            length: days.length,
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                  tabs: days.map((day) => Tab(text: day)).toList(),
                ),
                Expanded(
                  child: TabBarView(
                    children: days.map((day) {
                      final entries = schedule[day]!;
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                        itemCount: entries.length,
                        separatorBuilder: (context, index) => const Divider(height: 24),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.time} - ${entry.title}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              if (entry.hosts.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'Prowadzący: ${entry.hosts}',
                                    style: TextStyle(fontSize: 14, color: Colors.white70),
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
