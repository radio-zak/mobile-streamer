import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';

import 'notifications.dart';

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
  Timer? _connectionTimer;
  Timer? _bufferingTimer;
  bool _isConnecting = false;

  final mediaLibrary = MediaLibrary();
  Streamer() {
    final getMediaItem = mediaLibrary.items[MediaLibrary.albumsRootId]!;

    final streamSources = List<AudioSource>.empty(growable: true);
    for (var item in getMediaItem) {
      streamSources.add(AudioSource.uri(Uri.parse(item.id)));
    }
    _audioPlayer.setAudioSources(streamSources, initialIndex: 0);
    mediaItem.add(getMediaItem[0]);
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
      
      final successfullyConnected = playing &&
          (event.processingState == ProcessingState.ready ||
              event.processingState == ProcessingState.buffering);

      if (successfullyConnected && _isConnecting) {
        _isConnecting = false;
        _connectionTimer?.cancel();
      }

      if (playing && event.processingState == ProcessingState.buffering) {
        if (_bufferingTimer == null || !_bufferingTimer!.isActive) {
          _bufferingTimer = Timer(const Duration(seconds: 10), () {
            if (_audioPlayer.playing && _audioPlayer.processingState == ProcessingState.buffering) {
              Notifications.showNotification(
                title: 'Utrata połączenia',
                body: 'Połączenie ze strumieniem zostało przerwane.',
              );
            }
          });
        }
      } else {
        _bufferingTimer?.cancel();
      }

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
    _isConnecting = true;
    _connectionTimer = Timer(const Duration(seconds: 10), () {
      if (_isConnecting) {
        _isConnecting = false;
        Notifications.showNotification(
          title: 'Brak połączenia',
          body: 'Nie udało się połączyć z serwerem. Spróbuj ponownie.',
        );
      }
    });
    await _audioPlayer.seek(null);
    await _audioPlayer.play();
  }

  @override
  Future<void> pause() async {
    _isConnecting = false;
    _connectionTimer?.cancel();
    _bufferingTimer?.cancel();
    await _audioPlayer.pause();
  }

  @override
  Future<void> stop() async {
    _isConnecting = false;
    _connectionTimer?.cancel();
    _bufferingTimer?.cancel();
    await _audioPlayer.stop();
  }

  @override
  Future<void> onTaskRemoved() async {
    await _audioPlayer.stop();
  }

  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    final mediaChildren = mediaLibrary.items[parentMediaId]!;
    return mediaChildren;
  }

  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {
    _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(mediaId)));
    final mediaItems = mediaLibrary.items[MediaLibrary.albumsRootId]!;
    for (var item in mediaItems) {
      if (item.id == mediaId) {
        mediaItem.add(item);
      }
    }
    await _audioPlayer.play();
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
