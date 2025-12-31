import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:zakstreamer/schedule_service.dart';

import 'service_locator.dart';

enum ButtonState { playing, paused, loading }

class PlayButtonNotifier extends ValueNotifier<ButtonState> {
  PlayButtonNotifier() : super(_initialValue);
  static const _initialValue = ButtonState.paused;
}

class PageManager {
  // Notifiers
  final playButtonNotifier = PlayButtonNotifier();
  final nowPlayingNotifier = ValueNotifier<ScheduleEntry?>(null);

  // Dependencies
  final _audioHandler = getIt<AudioHandler>();
  final _scheduleService = getIt<ScheduleService>();

  // State
  Timer? _nowPlayingTimer;
  Map<String, List<ScheduleEntry>>? _fullSchedule;

  void init() {
    _listenToPlaybackState();
    _initializeNowPlayingFeature();
  }

  Future<void> _initializeNowPlayingFeature() async {
    try {
      // Fetch the schedule once.
      _fullSchedule = await _scheduleService.fetchSchedule();
      // Perform the first check immediately.
      _updateNowPlaying();
      // Start a timer to check every minute.
      _nowPlayingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        _updateNowPlaying();
      });
    } catch (e) {
      print("Failed to initialize Now Playing feature: $e");
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

    // Only notify listeners if the show has actually changed.
    if (nowPlayingNotifier.value?.title != liveEntry?.title) {
      nowPlayingNotifier.value = liveEntry;
    }
  }

  void _listenToPlaybackState() {
    _audioHandler.playbackState.listen((playbackState) {
      final isPlaying = playbackState.playing;
      final processingState = playbackState.processingState;
      if (processingState == AudioProcessingState.loading ||
          processingState == AudioProcessingState.buffering) {
        playButtonNotifier.value = ButtonState.loading;
      } else if (!isPlaying) {
        playButtonNotifier.value = ButtonState.paused;
      } else if (processingState != AudioProcessingState.completed) {
        playButtonNotifier.value = ButtonState.playing;
      } else {
        _audioHandler.pause();
      }
    });
  }

  void play() => _audioHandler.play();
  void pause() => _audioHandler.pause();

  void dispose() {
    _nowPlayingTimer?.cancel();
  }
}
