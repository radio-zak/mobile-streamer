import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zakstreamer/schedule_service.dart';

class ShowProgressBar extends StatefulWidget {
  final ScheduleEntry entry;

  const ShowProgressBar({
    super.key,
    required this.entry,
  });

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
    _updateTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        setState(() {});
      },
    );
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
    final startTime = widget.entry.startTime;
    final endTime = widget.entry.endTime;
    final now = DateTime.now();
    final startDateTime = widget.entry.startDateTime;

    // Format current time as HH:MM
    final currentTimeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Determine status text
    String statusText;
    if (startDateTime != null && now.isBefore(startDateTime)) {
      statusText = 'za $minutesRemaining min';
    } else if (progress >= 1.0) {
      statusText = 'zakończone';
    } else {
      statusText = 'min pozostało: $minutesRemaining';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Time information
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentTimeStr,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                '$startTime - $endTime',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                endTime,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Status text
          Text(
            statusText,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }
}



