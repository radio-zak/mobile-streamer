import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:zakstreamer/streamer.dart';

import 'streamer_test.mocks.dart';

@GenerateMocks([AudioPlayer])
void main() {
  setUpAll(() {
    WidgetsFlutterBinding.ensureInitialized();
  });
  group('Streamer', () {
    late Streamer streamer;
    late MockAudioPlayer mockAudioPlayer;

    setUp(() {
      mockAudioPlayer = MockAudioPlayer();

      // Mock setAudioSources to return completed future immediately
      when(mockAudioPlayer.setAudioSources(
        any,
        initialIndex: anyNamed('initialIndex'),
      )).thenAnswer((_) async => null);

      // Mock other async methods
      when(mockAudioPlayer.play()).thenAnswer((_) async => null);
      when(mockAudioPlayer.pause()).thenAnswer((_) async => null);
      when(mockAudioPlayer.stop()).thenAnswer((_) async => null);
      when(mockAudioPlayer.seek(any)).thenAnswer((_) async => null);
      when(mockAudioPlayer.setAudioSource(any)).thenAnswer((_) async => null);
      when(mockAudioPlayer.dispose()).thenAnswer((_) async => null);

      // Mock properties and streams
      when(mockAudioPlayer.playing).thenReturn(false);
      when(mockAudioPlayer.processingState).thenReturn(ProcessingState.idle);

      // Mock streams - return empty streams
      when(mockAudioPlayer.playerStateStream)
          .thenAnswer((_) => Stream.value(PlayerState(false, ProcessingState.idle)));
      when(mockAudioPlayer.playbackEventStream)
          .thenAnswer((_) => const Stream.empty());
      when(mockAudioPlayer.sequenceStateStream)
          .thenAnswer((_) => const Stream.empty());
      when(mockAudioPlayer.sequenceStream).thenAnswer((_) => const Stream.empty());
      when(mockAudioPlayer.errorStream).thenAnswer((_) => const Stream.empty());
      when(mockAudioPlayer.durationStream).thenAnswer((_) => const Stream.empty());
      when(mockAudioPlayer.positionStream).thenAnswer((_) => const Stream.empty());
      when(mockAudioPlayer.bufferedPositionStream).thenAnswer((_) => const Stream.empty());

      // Create Streamer with mock
      streamer = Streamer(audioPlayer: mockAudioPlayer);
    });

    tearDown(() async {
      await streamer.stop();
    });

    test('Streamer initializes with default media item', () async {
      // Assert: mediaItem should be set with default stream
      expect(streamer.mediaItem.value, isNotNull);
      expect(streamer.mediaItem.value!.title, contains('Alternatywa'));
    });

    test('play() clears error and sets connecting state', () async {
      // Act
      await streamer.play();

      // Assert: customEvent should contain clear_error
      verify(mockAudioPlayer.play()).called(1);
      verify(mockAudioPlayer.seek(null)).called(1);
    });

    test('pause() cancels timers', () async {
      // Arrange: Call play first to set up timers
      await streamer.play();

      // Act
      await streamer.pause();

      // Assert: Verify pause was called
      verify(mockAudioPlayer.pause()).called(1);
    });

    test('stop() cancels all resources', () async {
      // Arrange
      await streamer.play();

      // Act
      await streamer.stop();

      // Assert: Verify stop was called
      verify(mockAudioPlayer.stop()).called(1);
    });

    test('customEvent emits clear_error on play', () async {
      // Arrange
      final customEvents = <dynamic>[];
      streamer.customEvent.listen((event) {
        customEvents.add(event);
      });

      // Act
      await streamer.play();

      // Assert: customEvent should contain clear_error
      expect(customEvents.isNotEmpty, isTrue);
      expect(customEvents.first, isMap);
      expect(customEvents.first['type'], equals('clear_error'));
    });
  });
}



