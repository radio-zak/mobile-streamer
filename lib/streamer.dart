import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';

import 'notifications.dart';

Future<AudioHandler> initAudioService() async {
  return await AudioService.init(
    builder: () => Streamer(),
    config: const AudioServiceConfig(
      androidShowNotificationBadge: true,
      androidNotificationChannelId: 'com.zakstreamer.notification',
      androidNotificationChannelName: 'Zakstreamer',
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'mipmap/launcher_icon',
    ),
  );
}

class Streamer extends BaseAudioHandler {
  final log = Logger('Streamer');
  final _audioPlayer = AudioPlayer();
  Timer? _connectionTimer;
  Timer? _bufferingTimer;
  bool _isConnecting = false;
  bool _bufferingErrorActive = false;

  final mediaLibrary = MediaLibrary();
  Streamer() {
    final getMediaItem = mediaLibrary.items[MediaLibrary.albumsRootId]!;

    final streamSources = List<AudioSource>.empty(growable: true);
    for (var item in getMediaItem) {
      streamSources.add(AudioSource.uri(Uri.parse(item.id)));
    }
    _audioPlayer.setAudioSources(streamSources, initialIndex: 0);
    mediaItem.add(getMediaItem[0]);

    _audioPlayer.errorStream.listen((PlayerException e) async {
      if (_bufferingErrorActive) return; // Ignore if a buffering error is already active

      log.severe('PlayerException code: ${e.code}, message: ${e.message}');
      _isConnecting = false;
      _connectionTimer?.cancel();
      _bufferingTimer?.cancel();
      
      final errorMessage = await _mapErrorToMessage(e);

      customEvent.add({'type': 'error', 'message': errorMessage});
      
      Notifications.showNotification(
        title: 'Błąd Połączenia',
        body: errorMessage,
        payload: 'reconnect',
      );
    });

    _notifyAudioHandlerAboutPlaybackEvents();
  }

  Future<String> _mapErrorToMessage(PlayerException e) async {
    if (e.message != null && e.message!.toLowerCase().contains('source error')) {
      try {
        // Actively check for internet connectivity.
        final socket = await Socket.connect('8.8.8.8', 53, timeout: const Duration(seconds: 3));
        socket.destroy();
        // If connection succeeds, it's a server/stream issue.
        return 'Strumień jest obecnie niedostępny. Spróbuj ponownie później.';
      } on SocketException catch (_) {
        // If connection fails, there is no internet.
        return 'Brak połączenia z internetem. Sprawdź ustawienia sieci.';
      }
    }
    // Fallback for any other unexpected errors.
    return 'Wystąpił nieoczekiwany błąd odtwarzania. Spróbuj ponownie.';
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
        customEvent.add({'type': 'clear_error'});
      }

      if (playing && event.processingState == ProcessingState.buffering) {
        if (_bufferingTimer == null || !_bufferingTimer!.isActive) {
          _bufferingTimer = Timer(const Duration(seconds: 10), () {
            if (_audioPlayer.playing && _audioPlayer.processingState == ProcessingState.buffering) {
              _bufferingErrorActive = true;
              final message = 'Połączenie ze strumieniem zostało przerwane.';
              customEvent.add({'type': 'error', 'message': message});
              Notifications.showNotification(
                title: 'Utrata połączenia',
                body: message,
                payload: 'reconnect',
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
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'updateMetadata') {
      final title = extras?['title'] as String?;
      final artist = extras?['artist'] as String?;

      if (title != null && artist != null) {
        final currentItem = mediaItem.value;
        if (currentItem != null) {
          mediaItem.add(currentItem.copyWith(title: title, artist: artist));
        }
      }
    }
  }

  @override
  Future<void> play() async {
    customEvent.add({'type': 'clear_error'});
    _bufferingErrorActive = false; // Reset flag
    _isConnecting = true;
    _connectionTimer = Timer(const Duration(seconds: 10), () {
      if (_isConnecting) {
        _isConnecting = false;
        final message = 'Przekroczono czas oczekiwania na połączenie.';
        customEvent.add({'type': 'error', 'message': message});
        Notifications.showNotification(
          title: 'Błąd połączenia',
          body: message,
          payload: 'reconnect',
        );
      }
    });
    await _audioPlayer.seek(null);
    await _audioPlayer.play();
  }

  @override
  Future<void> pause() async {
    customEvent.add({'type': 'clear_error'});
    _bufferingErrorActive = false; // Reset flag
    _isConnecting = false;
    _connectionTimer?.cancel();
    _bufferingTimer?.cancel();
    await _audioPlayer.pause();
  }

  @override
  Future<void> stop() async {
    customEvent.add({'type': 'clear_error'});
    _bufferingErrorActive = false; // Reset flag
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
