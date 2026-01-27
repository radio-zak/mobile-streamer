import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:zakstreamer/streamer.dart';

import 'streamer_test.mocks.dart';

// Generate mocks for AudioPlayer
@GenerateMocks([AudioPlayer])
void main() {
  group('Streamer', () {
    late Streamer streamer;
    late MockAudioPlayer mockAudioPlayer;

    setUp(() {
      mockAudioPlayer = MockAudioPlayer();

      // Mock the behavior of the AudioPlayer streams and methods
      when(mockAudioPlayer.playerStateStream)
          .thenAnswer((_) => Stream.value(PlayerState(false, ProcessingState.idle)));
      when(mockAudioPlayer.playbackEventStream).thenAnswer((_) => const Stream.empty());
      when(mockAudioPlayer.durationStream).thenAnswer((_) => const Stream.empty());
      when(mockAudioPlayer.positionStream).thenAnswer((_) => const Stream.empty());
      when(mockAudioPlayer.bufferedPositionStream).thenAnswer((_) => const Stream.empty());

      // Provide a valid, non-null SequenceState using all required named parameters
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

      // Create the Streamer instance, injecting the mock AudioPlayer
      streamer = Streamer(audioPlayer: mockAudioPlayer);
    });

    test('init() correctly sets the audio source', () async {
      // Act: Call the asynchronous initialization method
      await streamer.init();

      // Assert: Verify that setAudioSource was called on the mock player
      final verification =
          verify(mockAudioPlayer.setAudioSource(captureAny, initialIndex: anyNamed('initialIndex')));

      // Check the captured audio source
      final captured = verification.captured.first as ConcatenatingAudioSource;
      final firstSource = captured.children.first as UriAudioSource;

      // Ensure it's the correct URL from the MediaLibrary
      expect(firstSource.uri.toString(), equals("http://ra.man.lodz.pl:8000/radiozak6.mp3"));
    });
  });
}
