import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zakstreamer/schedule_service.dart';

class ShowProgressBar extends StatefulWidget {
  final ScheduleEntry entry;

  const ShowProgressBar({super.key, required this.entry});

  @override
  State<ShowProgressBar> createState() => _ShowProgressBarState();
}

class _ShowProgressBarState extends State<ShowProgressBar> {
  late Timer _updateTimer;

  @override
  void initState() {
    super.initState();
    _startUpdateTimer();
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _updateTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.entry.progressPercent;
    final minutesRemaining = widget.entry.minutesRemaining;
    final startDateTime = widget.entry.startDateTime;
    final endDateTime = widget.entry.endDateTime;

    // Format start and end times as HH:MM
    final startTimeStr = startDateTime != null
        ? '${startDateTime.hour.toString().padLeft(2, '0')}:${startDateTime.minute.toString().padLeft(2, '0')}'
        : '--:--';
    final endTimeStr = endDateTime != null
        ? '${endDateTime.hour.toString().padLeft(2, '0')}:${endDateTime.minute.toString().padLeft(2, '0')}'
        : '--:--';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Start time, remaining time in center, and end time on one line
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  startTimeStr,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Expanded(
                  child: Text(
                    'pozostało $minutesRemaining min',
                    style: Theme.of(context).textTheme.labelLarge,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(endTimeStr, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
