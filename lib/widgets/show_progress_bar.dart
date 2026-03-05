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
      statusText = 'pozostało $minutesRemaining min';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar - very slim
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 3),
          // Current time and status in one line
          Text(
            '$currentTimeStr • $statusText',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  height: 1.0,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}











