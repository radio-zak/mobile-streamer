import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'service_locator.dart';
import 'main.dart';

enum ButtonState { playing, paused, loading, error }

class PlayButtonNotifier extends ValueNotifier<ButtonState> {
  PlayButtonNotifier() : super(_initialValue);
  static const _initialValue = ButtonState.paused;
}

class PageManager {
  final playButtonNotifier = PlayButtonNotifier();
  void init() async {
    await _listenToPlaybackState();
  }

  final _audioHandler = getIt<AudioHandler>();
  Future<void> _listenToPlaybackState() async {
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
      }
    });
  }

  void play() => _audioHandler.play();
  void pause() => _audioHandler.pause();
}
