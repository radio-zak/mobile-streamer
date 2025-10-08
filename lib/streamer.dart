import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';
import 'package:just_audio_background/just_audio_background.dart';

enum ButtonState { paused, playing, loading }

class Streamer {
  final log = Logger('Streamer');
  final buttonNotifier = ValueNotifier<ButtonState>(ButtonState.paused);
  final stream = AudioSource.uri(
    Uri.parse('http://ra.man.lodz.pl:8000/radiozak6.mp3'),
    tag: MediaItem(
      // Specify a unique ID for each media item:
      id: '1',
      // Metadata to display in the notification:
      album: "Studenckie Radio ŻAK Politechniki Łódzkiej",
      title: "Słuchasz na żywo",
    ),
  );
  late AudioPlayer _audioPlayer;
  Streamer() {
    try {
      _init();
      log.fine('Initializing streamer...');
    } catch (e) {
      log.severe("Error: ", e);
    }
  }
  Future<void> _init() async {
    _audioPlayer = AudioPlayer();
    try {
      await _audioPlayer.setAudioSource(stream);
      log.fine('Set audio source: ', stream);
    } catch (e) {
      log.severe("Error audio: ", e);
    }
    try {
      _audioPlayer.playerStateStream.listen((playerState) {
        final isPlaying = playerState.playing;
        final processingState = playerState.processingState;
        if (processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering) {
          buttonNotifier.value = ButtonState.loading;
        } else if (!isPlaying) {
          buttonNotifier.value = ButtonState.paused;
        } else {
          buttonNotifier.value = ButtonState.playing;
        }
      });
    } on PlayerException catch (e) {
      log.severe("Error code: ", e.code);
      log.severe("Error message ", e.message);
    } on PlayerInterruptedException catch (e) {
      log.severe("Connection aborted: ", e.message);
    } catch (e) {
      log.severe("An error occured: ", e);
    }

    _audioPlayer.errorStream.listen((PlayerException e) {
      log.severe('Error code: ', e.code);
      log.severe('Error message: ', e.message);
      log.severe('AudioSource index: ', e.index);
    });
  }

  void play() {
    log.fine('Playing audio from source.');
    _audioPlayer.play();
  }

  void pause() {
    log.fine('Paused audio from source.');
    _audioPlayer.pause();
  }
}
