import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'now_playing.dart';
import 'service_locator.dart';

enum ButtonState { playing, paused, loading }

class PlayButtonNotifier extends ValueNotifier<ButtonState> {
  PlayButtonNotifier() : super(_initialValue);
  static const _initialValue = ButtonState.paused;
}

class PageManager {
  // Notifiers
  final playButtonNotifier = PlayButtonNotifier();
  final errorNotifier = ValueNotifier<String>('');
  // Dependencies
  final _audioHandler = getIt<AudioHandler>();
  final _nowPlaying = getIt<NowPlaying>();
  StreamSubscription<dynamic>? _customEventSubscription;

  void init() {
    _listenToPlaybackState();
    _nowPlaying.initializeNowPlayingFeature();
    _listenToCustomEvents();
  }

  void _listenToPlaybackState() {
    _audioHandler.playbackState.listen((playbackState) {
      if (errorNotifier.value.isNotEmpty) return;
      final isPlaying = playbackState.playing;
      final processingState = playbackState.processingState;
      if (processingState == AudioProcessingState.loading ||
          processingState == AudioProcessingState.buffering) {
        playButtonNotifier.value = ButtonState.loading;
      } else if (!isPlaying) {
        playButtonNotifier.value = ButtonState.paused;
      } else {
        playButtonNotifier.value = ButtonState.playing;
      }
    });
  }

  void _listenToCustomEvents() {
    _customEventSubscription = _audioHandler.customEvent.listen((event) {
      if (event is Map && event['type'] == 'error') {
        errorNotifier.value = event['message'] as String;
        playButtonNotifier.value = ButtonState.paused;
      } else if (event is Map && event['type'] == 'clear_error') {
        errorNotifier.value = '';
      }
    });
  }

  void play() => {_audioHandler.play(), _nowPlaying.updateNowPlaying()};
  void pause() => _audioHandler.pause();

  void dispose() {
    _customEventSubscription?.cancel();
    _nowPlaying.cancelTimer();
  }
}
