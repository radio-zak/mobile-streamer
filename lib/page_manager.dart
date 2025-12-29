import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'service_locator.dart';
import 'schedule_service.dart' as schedule_service;

enum ButtonState { playing, paused, loading, error }

class PlayButtonNotifier extends ValueNotifier<ButtonState> {
  PlayButtonNotifier() : super(_initialValue);
  static const _initialValue = ButtonState.paused;
}

class PageManager {
  final playButtonNotifier = PlayButtonNotifier();
  final currentProgramNotifier = ValueNotifier<schedule_service.Program?>(null);

  final _audioHandler = getIt<AudioHandler>();

  // --- Schedule Handling ---
  Map<String, List<schedule_service.Program>>? _cachedSchedule;
  Completer<Map<String, List<schedule_service.Program>>>? _scheduleCompleter;
  Timer? _scheduleCheckTimer;

  void init() {
    _listenToPlaybackState();
    _scheduleCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateCurrentProgramFromCache();
    });
    getFullSchedule();
  }

  void dispose() {
    _scheduleCheckTimer?.cancel();
    playButtonNotifier.dispose();
    currentProgramNotifier.dispose();
  }
  void play() => _audioHandler.play();
  void pause() => _audioHandler.pause();

  Future<Map<String, List<schedule_service.Program>>> getFullSchedule() {
    if (_cachedSchedule != null) {
      return Future.value(_cachedSchedule!);
    }
    if (_scheduleCompleter == null) {
      _scheduleCompleter = Completer();
      schedule_service.fetchSchedule().then((fetchedSchedule) {
        _cachedSchedule = fetchedSchedule;
        log.info('Schedule successfully fetched and cached.');
        _scheduleCompleter!.complete(fetchedSchedule);
        _updateCurrentProgramFromCache();
      }).catchError((error) {
        log.severe("Failed to fetch schedule: $error");
        _scheduleCompleter!.completeError(error);
        _scheduleCompleter = null;
      });
    }
    return _scheduleCompleter!.future;
  }

  // --- Private methods ---

  void _listenToPlaybackState() {
    _audioHandler.playbackState.listen((playbackState) {
      final isPlaying = playbackState.playing;
      final processingState = playbackState.processingState;
      if (processingState == AudioProcessingState.loading ||
          processingState == AudioProcessingState.buffering) {
        playButtonNotifier.value = ButtonState.loading;
      } else if (!isPlaying) {
        playButtonNotifier.value = ButtonState.paused;
      } else if (processingState == AudioProcessingState.error) {
        playButtonNotifier.value = ButtonState.error;
        showDisconnectionNotification();
      } else {
        playButtonNotifier.value = ButtonState.playing;
      } else {
        _audioHandler.pause();
      }
    });
  }

  void play() => _audioHandler.play();
  void pause() => _audioHandler.pause();
      }
      }
    });
  }

  void _updateCurrentProgramFromCache() {
    if (_cachedSchedule == null) return;
    final now = DateTime.now();
    final todayKey = _cachedSchedule!.keys.elementAt(now.weekday - 1);
    final todayPrograms = _cachedSchedule![todayKey] ?? [];

    schedule_service.Program? liveProgram;
    for (var program in todayPrograms) {
      if (schedule_service.isProgramLive(program, now.weekday)) {
        liveProgram = program;
        break;
      }
    }
    
    if (currentProgramNotifier.value?.title != liveProgram?.title) {
        currentProgramNotifier.value = liveProgram;

        // Also update the notification in the background
        _audioHandler.customAction('updateMetadata', {
          'title': liveProgram?.title,
          'artist': liveProgram?.author,
        });

        if (liveProgram != null) {
            log.info("Current program updated: ${liveProgram.title}");
        } else {
            log.info("No program is currently live.");
        }
    }
  }
}
