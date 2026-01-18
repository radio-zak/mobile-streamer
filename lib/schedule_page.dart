import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'service_locator.dart';
import 'schedule_service.dart';
import 'package:zakstreamer/widgets/live_chip.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with TickerProviderStateMixin {
  // State variables to hold the data, loading, and error states
  Map<String, List<ScheduleEntry>>? _schedule;
  Object? _error;
  bool _isLoading = true;

  TabController? _tabController;
  final List<ItemScrollController> _scrollControllers = List.generate(
    7,
    (_) => ItemScrollController(),
  );

  // State variables to hold the position of the live show
  int _liveDayIndex = -1;
  int _liveShowIndex = -1;

  @override
  void initState() {
    super.initState();
    _fetchDataAndSetup();
  }

  Future<void> _fetchDataAndSetup() async {
    try {
      final scheduleData = await getIt<ScheduleService>().fetchSchedule();
      if (!mounted) return;

      // Find the live show ONCE and store its position
      final today = (DateTime.now().weekday - 1).clamp(0, 6);
      final entriesToday = scheduleData.values.elementAt(today);
      final liveIndex = entriesToday.indexWhere((e) => e.isLive);

      setState(() {
        _schedule = scheduleData;
        _isLoading = false;
        _liveDayIndex = today;
        _liveShowIndex = liveIndex;

        final days = scheduleData.keys.toList();
        _tabController = TabController(
          length: days.length,
          vsync: this,
          initialIndex: today,
        );
      });

      // Schedule the scroll to after the first frame has been built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_liveShowIndex != -1) {
          _scrollControllers[_liveDayIndex].scrollTo(
            index: _liveShowIndex,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutCubic,
            alignment: 0.3, // Scroll to 30% from the top
          );
        }
      });
    } catch (e, stackTrace) {
      print('Error fetching schedule: $e\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _error = e;
        _isLoading = false;
      });
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
        toolbarHeight: 80,
        title: Text(
          'Ramówka',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Nie udało się załadować ramówki.\nBłąd: $_error',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    if (_schedule == null || _schedule!.isEmpty) {
      return Center(
        child: Text(
          'Brak danych ramówki.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    final schedule = _schedule!;
    final days = schedule.keys.toList();

    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            tabAlignment: TabAlignment.start,
            controller: _tabController,
            isScrollable: true,
            tabs: days.map((day) => Tab(text: day)).toList(),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: schedule.entries.map((dayEntry) {
              final dayIndex = days.indexOf(dayEntry.key);
              final entries = dayEntry.value;

              return ScrollablePositionedList.separated(
                itemScrollController: _scrollControllers[dayIndex],
                itemCount: entries.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 0, color: Color(0xFF888888)),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  // The check is now simple and stable, based on pre-calculated state
                  final bool isLiveNow =
                      (dayIndex == _liveDayIndex && index == _liveShowIndex);

                  return Container(
                    color: isLiveNow
                        ? Theme.of(context).colorScheme.primaryFixedDim
                        : Theme.of(context).colorScheme.surface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,

                                children: [
                                  Text(
                                    '${entry.time}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  isLiveNow ? LiveChip() : Container(),
                                ],
                              ),
                              Text(
                                '${entry.title}',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              if (entry.hosts.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'Prowadzący: ${entry.hosts}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.tertiary,
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
  }
}
