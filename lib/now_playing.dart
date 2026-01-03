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
  Map<String, List<ScheduleEntry>>? _fullSchedule;
  Future<void> initializeNowPlayingFeature() async {
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

    // Only notify listeners and update metadata if the show has actually changed.
    if (nowPlayingNotifier.value?.title != liveEntry?.title) {
      nowPlayingNotifier.value = liveEntry;
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
