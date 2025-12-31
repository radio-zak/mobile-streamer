import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'service_locator.dart';

enum ButtonState { playing, paused, loading }

class PlayButtonNotifier extends ValueNotifier<ButtonState> {
  PlayButtonNotifier() : super(_initialValue);
  static const _initialValue = ButtonState.paused;
}

class PageManager {
  final playButtonNotifier = PlayButtonNotifier();
  void init() {
    _listenToPlaybackState();
  }

  final _audioHandler = getIt<AudioHandler>();
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
}
