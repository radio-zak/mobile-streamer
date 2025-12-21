import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';
import 'dart:async';

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
  final _audioPlayer = AudioPlayer();
  Timer? _stuckTimer;

  final mediaLibrary = MediaLibrary();

  Streamer() {
    final defaultItem = mediaLibrary.items[MediaLibrary.albumsRootId]![0];
    mediaItem.add(defaultItem);
    _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(defaultItem.id)), preload: false);

    _audioPlayer.playerStateStream.listen((state) {
      playbackState.add(
        playbackState.value.copyWith(
          controls: [if (state.playing) MediaControl.pause else MediaControl.play],
          processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.completed: AudioProcessingState.completed,
            ProcessingState.ready: AudioProcessingState.ready,
          }[state.processingState]!,
          playing: state.playing,
        ),
      );

      final isStuck = state.playing && state.processingState != ProcessingState.ready;
      if (isStuck) {
        _stuckTimer ??= Timer(const Duration(seconds: 10), () {
          log.warning("Player has been stuck for 10 seconds. Setting state to error.");
          playbackState.add(playbackState.value.copyWith(processingState: AudioProcessingState.error));
          _stuckTimer = null;
        });
      } else {
        _stuckTimer?.cancel();
        _stuckTimer = null;
      }
    });

    _audioPlayer.errorStream.listen((error) {
      log.severe("A fatal error occurred: $error. Setting state to error.");
      playbackState.add(playbackState.value.copyWith(processingState: AudioProcessingState.error));
    });
  }

  void _cancelStuckTimer() {
    _stuckTimer?.cancel();
    _stuckTimer = null;
  }

  @override
  Future<void> play() async {
    _cancelStuckTimer();
    await _audioPlayer.seek(null);
    return _audioPlayer.play();
  }

  @override
  Future<void> pause() async {
    _cancelStuckTimer();
    await _audioPlayer.pause();
  }

  @override
  Future<void> stop() async {
    _cancelStuckTimer();
    await _audioPlayer.stop();
  }

  @override
  Future<void> onTaskRemoved() => stop();

  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    return mediaLibrary.items[parentMediaId]!;
  }
}

class MediaLibrary {
  static const albumsRootId = 'albums';

  final items = <String, List<MediaItem>>{
    AudioService.browsableRootId: const [
      MediaItem(id: albumsRootId, title: 'ŻAK Streamer', playable: false),
    ],
    albumsRootId: [
      MediaItem(
        id: "http://ra.man.lodz.pl:8000/radiozak6.mp3",
        title: "Alternatywa na żywo",
        artist: 'Studenckie Radio "ŻAK" Politechniki Łódzkiej',
        artUri: Uri.parse(
          'https://raw.githubusercontent.com/radio-zak/mobile-streamer/refs/heads/main/assets/zak-artwork-dark.png',
        ),
        isLive: true,
      ),
    ],
  };
}
