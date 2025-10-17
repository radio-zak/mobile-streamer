import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';

Future<AudioHandler> initAudioService() async {
  final audioHandler = await AudioService.init(
    builder: () => Streamer(),
    config: const AudioServiceConfig(
      androidShowNotificationBadge: true,
      androidNotificationChannelId: 'com.zakstreamer.notification',
      androidNotificationChannelName: 'Zakstreamer',
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/launcher_icon',
    ),
  );
  return audioHandler;
}

class Streamer extends BaseAudioHandler {
  final log = Logger('Streamer');
  final stream = "http://ra.man.lodz.pl:8000/radiozak6.mp3";
  final _audioPlayer = AudioPlayer();
  Streamer() {
    mediaItem.add(
      MediaItem(
        id: stream,
        title: "Słuchasz alternatywy na żywo",
        artist: "Studenckie Radio ŻAK Politechniki Łódzkiej",
      ),
    );
    _audioPlayer.setUrl(stream);
    _audioPlayer.errorStream.listen((PlayerException e) {
      log.severe('Error code: ', e.code);
      log.severe('Error message: ', e.message);
      log.severe('AudioSource index: ', e.index);
    });
    _notifyAudioHandlerAboutPlaybackEvents();
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _audioPlayer.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _audioPlayer.playing;
      playbackState.add(
        playbackState.value.copyWith(
          controls: [if (playing) MediaControl.pause else MediaControl.play],
          processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.completed: AudioProcessingState.completed,
            ProcessingState.ready: AudioProcessingState.ready,
          }[_audioPlayer.processingState]!,
          playing: playing,
        ),
      );
    });
  }

  @override
  Future<void> play() async {
    await _audioPlayer.seek(null);
    await _audioPlayer.play();
  }

  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
    await _audioPlayer.dispose();
  }
}
