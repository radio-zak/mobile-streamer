import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';

import 'network_checker.dart';
import 'notifications.dart';

Future<AudioHandler> initAudioService() async {
  return await AudioService.init<AudioHandler>(
    builder: () {
      final streamer = Streamer();
      // Fire and forget initialization.
      streamer.init();
      return streamer;
    },
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
  late final AudioPlayer _audioPlayer;
  late final NetworkChecker _networkChecker;
  late final NotificationsManager _notificationsManager;
  Timer? _connectionTimer;
  Timer? _bufferingTimer;
  bool _isConnecting = false;
  bool _bufferingErrorActive = false;

  final mediaLibrary = MediaLibrary();

  Streamer({
    AudioPlayer? audioPlayer,
    NetworkChecker? networkChecker,
    NotificationsManager? notificationsManager,
  }) {
    _audioPlayer = audioPlayer ?? AudioPlayer();
    _networkChecker = networkChecker ?? NetworkChecker();
    _notificationsManager = notificationsManager ?? NotificationsManager();
  }

  Future<void> init() async {
    final getMediaItem = mediaLibrary.items[MediaLibrary.albumsRootId]!;
    final streamSources =
        getMediaItem.map((item) => AudioSource.uri(Uri.parse(item.id))).toList();

    try {
      await _audioPlayer.setAudioSource(
        ConcatenatingAudioSource(children: streamSources),
        initialIndex: 0,
      );
      mediaItem.add(getMediaItem[0]);
      _notifyAudioHandlerAboutPlaybackEvents();
    } on PlayerException catch (e, stacktrace) {
      log.severe('Error setting audio source', e, stacktrace);
      _handleStreamError(); // Handle as a generic stream error
    } catch (e, stacktrace) {
      log.severe('Error during streamer initialization', e, stacktrace);
    }
  }

  Future<void> _handleStreamError() async {
    if (_bufferingErrorActive) {
      return; // Ignore if a buffering error is already active
    }
    log.severe('A stream error occurred.');
    _isConnecting = false;
    _connectionTimer?.cancel();
    _bufferingTimer?.cancel();

    final errorMessage = await _determineStreamErrorMessage();

    customEvent.add({'type': 'error', 'message': errorMessage});

    _notificationsManager.showNotification(
      title: 'Błąd połączenia',
      body: errorMessage,
      payload: 'reconnect',
    );
  }

  Future<String> _determineStreamErrorMessage() async {
    final hasConnection = await _networkChecker.isConnected();
    if (hasConnection) {
      return 'Strumień jest obecnie niedostępny. Spróbuj ponownie później.';
    } else {
      return 'Brak połączenia z internetem. Sprawdź ustawienia sieci.';
    }
  }

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _audioPlayer.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _audioPlayer.playing;

      // For live streams, unexpectedly entering the 'completed' state is an error.
      if (event.processingState == ProcessingState.completed &&
          mediaItem.value?.isLive == true) {
        if (!_audioPlayer.playing) return; // Ignore if already paused/stopped
        log.warning('Live stream completed unexpectedly, handling as error.');
        _handleStreamError();
        return; // Stop processing this event further
      }

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
            if (_audioPlayer.playing &&
                _audioPlayer.processingState == ProcessingState.buffering) {
              _bufferingErrorActive = true;
              final message = 'Połączenie ze strumieniem zostało przerwane.';
              customEvent.add({'type': 'error', 'message': message});
              _notificationsManager.showNotification(
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
  Future<void> play() async {
    customEvent.add({'type': 'clear_error'});
    _bufferingErrorActive = false; // Reset flag
    _isConnecting = true;
    _connectionTimer = Timer(const Duration(seconds: 10), () {
      if (_isConnecting) {
        _isConnecting = false;
        final message = 'Przekroczono czas oczekiwania na połączenie.';
        customEvent.add({'type': 'error', 'message': message});
        _notificationsManager.showNotification(
          title: 'Błąd połączenia',
          body: message,
          payload: 'reconnect',
        );
      }
    });
    try {
      await _audioPlayer.play();
    } on PlayerException catch (e) {
      log.severe('Error on play()', e);
      _handleStreamError();
    }
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
    await stop();
  }

  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    return mediaLibrary.items[parentMediaId]!;
  }

  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {
    try {
      await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(mediaId)));
      await _audioPlayer.play();
    } on PlayerException catch (e) {
      log.severe('Error in playFromMediaId', e);
      _handleStreamError();
    }
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
