import 'dart:async';
import 'package:flutter/foundation.dart';
import 'service_locator.dart';
import 'package:audio_service/audio_service.dart';
import 'schedule_service.dart';

enum NowPlayingState { inactive, loading, active }

class NowPlaying {
  final _audioHandler = getIt<AudioHandler>();
  final nowPlayingContents = ValueNotifier<ScheduleEntry?>(null);
  final nowPlayingNotifier = ValueNotifier<NowPlayingState>(
    NowPlayingState.inactive,
  );
  final _scheduleService = getIt<ScheduleService>();

  // State
  Timer? _nowPlayingTimer;
  Map<String, List<ScheduleEntry>>? _fullSchedule;
  Future<void> initializeNowPlayingFeature() async {
    try {
      // Fetch the schedule once.
      nowPlayingNotifier.value = NowPlayingState.loading;
      // Perform the first check immediately.
      await updateNowPlaying();
      // Start a timer to check every minute.
      _nowPlayingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        updateNowPlaying();
      });
    } catch (e) {
      debugPrint("Failed to initialize Now Playing feature: $e");
      nowPlayingNotifier.value = NowPlayingState.inactive;
    }
  }

  Future<void> updateNowPlaying() async {
    try {
      _fullSchedule = await _scheduleService.fetchSchedule();
    } catch (e) {
      debugPrint("Failed to fetch Now Playing data: $e");
      nowPlayingNotifier.value = NowPlayingState.inactive;
    }

    if (nowPlayingContents.value == null) {
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

    // Only notify listeners and update metadata if the show has actually changed.
    if (nowPlayingContents.value?.title != liveEntry?.title) {
      nowPlayingNotifier.value = NowPlayingState.active;
      nowPlayingContents.value = liveEntry;
      _audioHandler.customAction('updateMetadata', {
        'title': liveEntry?.title ?? 'Alternatywa na żywo',
        'artist': liveEntry?.hosts.isNotEmpty == true
            ? liveEntry!.hosts
            : 'Studenckie Radio "ŻAK" Politechniki Łódzkiej',
      });
    }
  }

  void cancelTimer() {
    _nowPlayingTimer?.cancel();
  }
}
