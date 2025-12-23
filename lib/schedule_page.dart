import 'dart:async';
import 'package:flutter/material.dart';
import 'service_locator.dart';
import 'page_manager.dart';
import 'schedule_service.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({Key? key}) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late final Future<Map<String, List<Program>>> _scheduleFuture;

  @override
  void initState() {
    super.initState();
    _scheduleFuture = getIt<PageManager>().getFullSchedule();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ramówka'),
      ),
      body: FutureBuilder<Map<String, List<Program>>>(
        future: _scheduleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Błąd ładowania ramówki: ${snapshot.error}'));
          } else if (snapshot.hasData &&
              snapshot.data!.values.any((day) => day.isNotEmpty)) {
            final scheduleData = snapshot.data!;
            return DefaultTabController(
              length: scheduleData.keys.length,
              initialIndex: DateTime.now().weekday - 1,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    tabs: scheduleData.keys.map((day) => Tab(text: day)).toList(),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: scheduleData.keys.map((day) {
                        final programs = scheduleData[day]!;
                        final dayIndex = scheduleData.keys.toList().indexOf(day) + 1;
                        // Pass the list of programs and the day index to a new widget
                        return _DayScheduleView(programs: programs, dayIndex: dayIndex);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: Text('Nie udało się wczytać ramówki.'));
          }
        },
      ),
    );
  }
}

// A new stateful widget to manage the scrolling for a single day
class _DayScheduleView extends StatefulWidget {
  final List<Program> programs;
  final int dayIndex;

  const _DayScheduleView({required this.programs, required this.dayIndex});

  @override
  State<_DayScheduleView> createState() => _DayScheduleViewState();
}

class _DayScheduleViewState extends State<_DayScheduleView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // After the frame is built, scroll to the live program if it exists
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLiveProgram());
  }

  void _scrollToLiveProgram() {
    if (!mounted) return;

    final liveProgramIndex = widget.programs.indexWhere(
      (p) => isProgramLive(p, widget.dayIndex),
    );

    if (liveProgramIndex != -1) {
      // Estimate the height of each item. ListTile(dense: true) is about 56.0 pixels high.
      const double itemHeight = 56.0;
      final scrollOffset = itemHeight * liveProgramIndex;

      _scrollController.animateTo(
        scrollOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.programs.isEmpty) {
      return const Center(child: Text('Brak audycji tego dnia.'));
    }

    return ListView.separated(
      controller: _scrollController,
      itemCount: widget.programs.length,
      itemBuilder: (context, index) {
        final program = widget.programs[index];
        final isLive = isProgramLive(program, widget.dayIndex);
        return ListTile(
          tileColor: isLive ? Colors.teal.withOpacity(0.3) : null,
          leading: isLive ? const Icon(Icons.volume_up, color: Colors.tealAccent) : null,
          title: Text('${program.time} - ${program.title}'),
          subtitle:
              Text(program.author.isNotEmpty ? 'Prowadzący: ${program.author}' : ' '),
          dense: true,
        );
      },
      separatorBuilder: (context, index) => const Divider(),
    );
  }
}
