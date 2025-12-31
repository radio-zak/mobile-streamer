import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'service_locator.dart';
import 'schedule_service.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> with TickerProviderStateMixin {
  Future<Map<String, List<ScheduleEntry>>>? _scheduleFuture;
  TabController? _tabController;
  final List<ItemScrollController> _scrollControllers = List.generate(7, (_) => ItemScrollController());

  @override
  void initState() {
    super.initState();
    _scheduleFuture = getIt<ScheduleService>().fetchSchedule();
  }

  void _scrollToCurrentShow(int dayIndex, Map<String, List<ScheduleEntry>> schedule) {
    final todayIndex = DateTime.now().weekday - 1;
    if (dayIndex != todayIndex) return;

    final currentDayController = _scrollControllers[dayIndex];
    final todayEntries = schedule.values.elementAt(dayIndex);
    final currentShowIndex = todayEntries.indexWhere((entry) => entry.isLive);

    if (currentShowIndex != -1 && currentDayController.isAttached) {
      currentDayController.scrollTo(
        index: currentShowIndex,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
        alignment: 0.3,
      );
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
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
          final todayWeekday = DateTime.now().weekday;
          final initialDayIndex = (todayWeekday - 1).clamp(0, days.length - 1);

          _tabController ??= TabController(length: days.length, vsync: this, initialIndex: initialDayIndex);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToCurrentShow(initialDayIndex, schedule);
          });

          return Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
                tabs: days.map((day) => Tab(text: day)).toList(),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: schedule.entries.map((dayEntry) {
                    final dayIndex = days.indexOf(dayEntry.key);
                    final entries = dayEntry.value;
                    return ScrollablePositionedList.separated(
                      itemScrollController: _scrollControllers[dayIndex],
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      itemCount: entries.length,
                      separatorBuilder: (context, index) => const Divider(indent: 16, endIndent: 16, height: 24),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        // A show is live ONLY if the time is correct AND it's the current day of the week.
                        final bool isLive = entry.isLive && dayIndex == initialDayIndex;
                        return Container(
                          color: isLive ? Colors.teal.withOpacity(0.25) : Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 36,
                                child: isLive 
                                  ? const Icon(Icons.volume_up_outlined, color: Colors.tealAccent)
                                  : null,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${entry.time} - ${entry.title}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isLive ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    if (entry.hosts.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          'Prowadzący: ${entry.hosts}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isLive ? Colors.white : Colors.white70,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
