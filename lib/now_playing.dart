import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'service_locator.dart';
import 'package:audio_service/audio_service.dart';
import 'schedule_service.dart';

enum NowPlayingState { inactive, loading, active }

class NowPlaying {
  final _logger = Logger('Main');
  final _audioHandler = getIt<AudioHandler>();
  final nowPlayingContents = ValueNotifier<ScheduleEntry?>(null);
  final nowPlayingNotifier = ValueNotifier<NowPlayingState>(
    NowPlayingState.inactive,
  );
  final _scheduleService = getIt<ScheduleService>();

  // State
  Timer? _nowPlayingTimer;
  Timer? _metadataUpdateTimer;
  Map<String, List<ScheduleEntry>>? _fullSchedule;
  Future<void> initializeNowPlayingFeature() async {
    try {
      // Fetch the schedule once.
      nowPlayingNotifier.value = NowPlayingState.loading;
      _logger.info("Attempting to fetch schedule (init)...");
      // Perform the first check immediately.
      await updateNowPlaying();
      // Start a timer to check every minute.
      _nowPlayingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        updateNowPlaying();
      });
      // Start a timer to update metadata every second with current progress
      _startMetadataUpdateTimer();
    } catch (e) {
      _logger.severe("Failed to initialize Now Playing feature: $e");
      nowPlayingNotifier.value = NowPlayingState.inactive;
    }
  }

  void _startMetadataUpdateTimer() {
    _metadataUpdateTimer?.cancel();
    _metadataUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final currentEntry = nowPlayingContents.value;
      if (currentEntry != null && currentEntry.isLive) {
        _updateProgressBar(currentEntry);
      }
    });
  }

  void _updateProgressBar(ScheduleEntry entry) {
    final elapsed = entry.minutesElapsed;
    final remaining = entry.minutesRemaining;
    final total = elapsed + remaining;

    _audioHandler.customAction('updateProgress', {
      'elapsedSeconds': elapsed * 60,
      'totalSeconds': total * 60,
    });
  }

  void _updateMetadata(ScheduleEntry entry) {
    _audioHandler.customAction('updateMetadata', {
      'title': entry.title,
      'artist': entry.hosts,
    });
  }

  Future<void> updateNowPlaying() async {
    try {
      _logger.info("Attempting to fetch schedule on update...");
      _fullSchedule = await _scheduleService.fetchSchedule();
    } catch (e) {
      _logger.severe("Failed to fetch Now Playing data: $e", e);
      nowPlayingNotifier.value = NowPlayingState.inactive;
      _logger.severe(nowPlayingNotifier.value);
    }

    if (nowPlayingContents.value == null) {
      _logger.info(
        'Now Playing fetched content empty. Setting Now Playing to inactive.',
      );
      nowPlayingNotifier.value = NowPlayingState.inactive;
    }

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

    nowPlayingNotifier.value = NowPlayingState.active;
    // Only notify listeners and update metadata if the show has actually changed.
    if (nowPlayingContents.value?.title != liveEntry?.title) {
      _logger.info("Updating notification metadata with fetched schedule data");
      nowPlayingContents.value = liveEntry;
      if (liveEntry != null) {
        _updateMetadata(liveEntry);
      }
    }
  }

  void cancelTimer() {
    _nowPlayingTimer?.cancel();
    _metadataUpdateTimer?.cancel();
  }
}
