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
    final getMediaItem = mediaLibrary.items[MediaLibrary.albumsRootId]!;
    final streamSources = getMediaItem.map((item) => AudioSource.uri(Uri.parse(item.id))).toList();
    
    _audioPlayer.setAudioSources(streamSources, initialIndex: 0, preload: false);
    mediaItem.add(getMediaItem[0]);

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
    // This is called by the system to get the list of playable items.
    return mediaLibrary.items[parentMediaId]!;
  }

  @override
  Future<void> playFromMediaId(String mediaId, [Map<String, dynamic>? extras]) async {
    final mediaItems = mediaLibrary.items[MediaLibrary.albumsRootId]!;
    final itemToPlay = mediaItems.firstWhere((item) => item.id == mediaId, orElse: () => mediaItems.first);
    mediaItem.add(itemToPlay);

    final index = mediaItems.indexOf(itemToPlay);
    if (index != -1) {
      await _audioPlayer.seek(Duration.zero, index: index);
    }
    await play();
  }
}

class MediaLibrary {
  static const albumsRootId = 'streams';

  final items = <String, List<MediaItem>>{
    AudioService.browsableRootId: const [
      MediaItem(id: albumsRootId, title: 'Strumienie', playable: false),
    ],
    albumsRootId: [
      MediaItem(
        id: "http://ra.man.lodz.pl:8000/radiozak6.mp3",
        title: "Strumień MP3",
        artist: 'Wysoka jakość',
        artUri: Uri.parse(
          'https://raw.githubusercontent.com/radio-zak/mobile-streamer/refs/heads/main/assets/zak-artwork-dark.png',
        ),
        isLive: true,
      ),
      MediaItem(
        id: "http://ra.man.lodz.pl:8000/radiozak.aac",
        title: "Strumień AAC",
        artist: 'Niska jakość',
        artUri: Uri.parse(
          'https://raw.githubusercontent.com/radio-zak/mobile-streamer/refs/heads/main/assets/zak-artwork-dark.png',
        ),
        isLive: true,
      ),
    ],
  };
}
