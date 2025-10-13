import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';

enum ButtonState { paused, playing, loading }

Future<AudioHandler> initAudioService() async {
  final audioHandler = await AudioService.init(
    builder: () => Streamer(),
    config: const AudioServiceConfig(
      androidNotificationChannelId:
          'com.ryanheise.audioservice.AudioServiceActivity',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/launcher_icon',
    ),
  );

  return audioHandler;
}

class Streamer extends BaseAudioHandler {
  final log = Logger('Streamer');
  final buttonNotifier = ValueNotifier<ButtonState>(ButtonState.paused);
  final stream = AudioSource.uri(
    Uri.parse('http://ra.man.lodz.pl:8000/radiozak6.mp3'),
    tag: MediaItem(
      // Specify a unique ID for each media item:
      id: 'http://ra.man.lodz.pl:8000/radiozak6.mp3',
      // Metadata to display in the notification:
      album: "Studenckie Radio ŻAK Politechniki Łódzkiej",
      title: "Słuchasz na żywo",
      isLive: true,
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

  @override
  Future<void> play() async {
    playbackState.add(
      playbackState.value.copyWith(
        playing: true,
        controls: [MediaControl.stop],
      ),
    );
    await _audioPlayer.play();
  }

  @override
  Future<void> pause() async {
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        controls: [MediaControl.play],
      ),
    );
    await _audioPlayer.stop();
  }
}
