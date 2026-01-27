import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:zakstreamer/network_checker.dart';
import 'package:zakstreamer/streamer.dart';

import 'streamer_test.mocks.dart';

// Generate mocks for AudioPlayer and NetworkChecker
@GenerateMocks([AudioPlayer, NetworkChecker])
void main() {
  group('Streamer', () {
    late Streamer streamer;
    late MockAudioPlayer mockAudioPlayer;
    late MockNetworkChecker mockNetworkChecker;
    late StreamController<PlaybackEvent> playbackEventController;

    setUp(() {
      mockAudioPlayer = MockAudioPlayer();
      mockNetworkChecker = MockNetworkChecker();
      playbackEventController = StreamController<PlaybackEvent>.broadcast();

      // Mock the behavior of the AudioPlayer streams and methods
      when(mockAudioPlayer.playerStateStream)
          .thenAnswer((_) => Stream.value(PlayerState(false, ProcessingState.idle)));
      when(mockAudioPlayer.playbackEventStream).thenAnswer((_) => playbackEventController.stream);
      when(mockAudioPlayer.durationStream).thenAnswer((_) => const Stream.empty());
      when(mockAudioPlayer.positionStream).thenAnswer((_) => const Stream.empty());
      when(mockAudioPlayer.bufferedPositionStream).thenAnswer((_) => const Stream.empty());

      when(mockAudioPlayer.sequenceStateStream).thenAnswer((_) => Stream.value(SequenceState(
            sequence: [],
            currentIndex: 0,
            shuffleModeEnabled: false,
            shuffleIndices: [],
            loopMode: LoopMode.off,
          )));
      when(mockAudioPlayer.sequenceStream).thenAnswer((_) => Stream.value([]));

      // Mock methods that return Futures
      when(mockAudioPlayer.setAudioSource(any, initialIndex: anyNamed('initialIndex')))
          .thenAnswer((_) async => null);
      when(mockAudioPlayer.play()).thenAnswer((_) async {});
      when(mockAudioPlayer.pause()).thenAnswer((_) async {});
      when(mockAudioPlayer.stop()).thenAnswer((_) async {});

      // Default mock behavior for network checker (assume online)
      when(mockNetworkChecker.isConnected()).thenAnswer((_) async => true);

      // Create the Streamer instance, injecting the mocks
      streamer = Streamer(
        audioPlayer: mockAudioPlayer,
        networkChecker: mockNetworkChecker,
      );
      // Add a default media item for the tests
      streamer.mediaItem.add(const MediaItem(id: 'live', title: 'Live Stream', isLive: true));
      when(mockAudioPlayer.playing).thenReturn(true);
    });

    tearDown(() {
      playbackEventController.close();
    });

    test('init() correctly sets the audio source', () async {
      await streamer.init();
      final verification =
          verify(mockAudioPlayer.setAudioSource(captureAny, initialIndex: anyNamed('initialIndex')));
      final captured = verification.captured.first as ConcatenatingAudioSource;
      final firstSource = captured.children.first as UriAudioSource;
      expect(firstSource.uri.toString(), equals("http://ra.man.lodz.pl:8000/radiozak6.mp3"));
    });

    test('play() calls audioPlayer.play()', () async {
      await streamer.play();
      verify(mockAudioPlayer.play()).called(1);
    });

    test('pause() calls audioPlayer.pause()', () async {
      await streamer.pause();
      verify(mockAudioPlayer.pause()).called(1);
    });

    test('stop() calls audioPlayer.stop()', () async {
      await streamer.stop();
      verify(mockAudioPlayer.stop()).called(1);
    });

    test('handles stream error when OFFLINE', () async {
      // Arrange: Pretend we are offline
      when(mockNetworkChecker.isConnected()).thenAnswer((_) async => false);

      // Act: Simulate the live stream unexpectedly completing
      playbackEventController.add(PlaybackEvent(processingState: ProcessingState.completed));

      // Assert: Expect an error event with the 'no internet' message
      expect(
        streamer.customEvent,
        emits({'type': 'error', 'message': 'Brak połączenia z internetem. Sprawdź ustawienia sieci.'}),
      );
    });

    test('handles stream error when ONLINE', () async {
      // Arrange: Pretend we are online (this is the default in setUp)
      when(mockNetworkChecker.isConnected()).thenAnswer((_) async => true);

      // Act: Simulate the live stream unexpectedly completing
      playbackEventController.add(PlaybackEvent(processingState: ProcessingState.completed));

      // Assert: Expect an error event with the 'stream unavailable' message
      expect(
        streamer.customEvent,
        emits({'type': 'error', 'message': 'Strumień jest obecnie niedostępny. Spróbuj ponownie później.'}),
      );
    });
  });
}
