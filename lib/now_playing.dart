import 'dart:async';
import 'package:flutter/foundation.dart';
import 'service_locator.dart';
import 'package:audio_service/audio_service.dart';
import 'schedule_service.dart';

class NowPlaying {
  final _audioHandler = getIt<AudioHandler>();
  final nowPlayingNotifier = ValueNotifier<ScheduleEntry?>(null);
  final _scheduleService = getIt<ScheduleService>();

  // State
  Timer? _nowPlayingTimer;
  Timer? _retryTimer; // Timer for retrying on failure
  Map<String, List<ScheduleEntry>>? _fullSchedule;

  void initializeNowPlayingFeature() {
    _fetchScheduleWithRetry(); // Start the process
  }

  Future<void> _fetchScheduleWithRetry() async {
    try {
      // Attempt to fetch the schedule.
      _fullSchedule = await _scheduleService.fetchSchedule();

      // If successful, stop retrying.
      if (_retryTimer != null) {
        _retryTimer?.cancel();
        _retryTimer = null;
        print("Successfully fetched schedule. Stopping retry mechanism.");
      }

      // Perform the first check immediately.
      _updateNowPlaying();

      // Start the regular timer to check every minute.
      _nowPlayingTimer?.cancel(); // Cancel any existing timer
      _nowPlayingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        _updateNowPlaying();
      });
    } catch (e) {
      print("Failed to fetch schedule: $e. Will retry in 5 seconds.");
      // If fetching fails, start the retry mechanism if it's not already running.
      if (_retryTimer == null || !_retryTimer!.isActive) {
        _retryTimer = Timer.periodic(const Duration(seconds: 5), (_) {
          print("Retrying to fetch schedule...");
          _fetchScheduleWithRetry();
        });
      }
    }
  }

  void _updateNowPlaying() {
    if (_fullSchedule == null) return;

    final todayIndex = (DateTime.now().weekday - 1).clamp(0, 6);
    final todayKey = _fullSchedule!.keys.elementAt(todayIndex);
    final entriesToday = _fullSchedule![todayKey] ?? [];

    ScheduleEntry? liveEntry;
    for (final entry in entriesToday) {
      if (entry.isLive) {
        liveEntry = entry;
        break; // Find the first one and stop
      }
    }

    // Only notify listeners and update metadata if the show has actually changed.
    if (nowPlayingNotifier.value?.title != liveEntry?.title) {
      nowPlayingNotifier.value = liveEntry;
      _audioHandler.customAction('updateMetadata', {
        'title': liveEntry?.title ?? 'Radio Żak',
        'artist': liveEntry?.hosts.isNotEmpty == true
            ? liveEntry!.hosts
            : 'Studenckie Radio Politechniki Łódzkiej',
      });
    }
  }

  void cancelTimer() {
    _nowPlayingTimer?.cancel();
    _retryTimer?.cancel(); // Also cancel the retry timer
  }
}
