import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:zakstreamer/streamer.dart';

import 'streamer_test.mocks.dart';

@GenerateMocks([AudioPlayer])
void main() {
  group('Streamer', () {
    late Streamer streamer;
    late MockAudioPlayer mockAudioPlayer;

    setUp(() {
      mockAudioPlayer = MockAudioPlayer();
      // Mock the stream controllers
      when(mockAudioPlayer.playbackStateStream).thenAnswer((_) => Stream.value(PlaybackState(true, ProcessingState.idle)));
      when(mockAudioPlayer.processingStateStream).thenAnswer((_) => Stream.value(ProcessingState.idle));
      when(mockAudioPlayer.playingStream).thenAnswer((_) => Stream.value(false));
      when(mockAudioPlayer.durationStream).thenAnswer((_) => Stream.value(Duration.zero));
      when(mockAudioPlayer.positionStream).thenAnswer((_) => Stream.value(Duration.zero));
      when(mockAudioPlayer.bufferedPositionStream).thenAnswer((_) => Stream.value(Duration.zero));
      when(mockAudioPlayer.sequenceStateStream).thenAnswer((_) => Stream.value(null));
      when(mockAudioPlayer.sequenceStream).thenAnswer((_) => Stream.value(null));
      when(mockAudioPlayer.icyMetadataStream).thenAnswer((_) => Stream.value(null));

      // Mock the setAudioSource method to complete successfully
      when(mockAudioPlayer.setAudioSource(any)).thenAnswer((_) async => Duration.zero);

      streamer = Streamer(audioPlayer: mockAudioPlayer);
    });

    test('correctly sets audio source on initialization', () async {
      // The Streamer's constructor is called in setUp.
      // We need to wait for the asynchronous operations within the constructor to complete.
      await streamer.init();

      // Verify that setAudioSource was called with the correct URL.
      final verificationResult = verify(mockAudioPlayer.setAudioSource(captureAny));
      final captured = verificationResult.captured.single as LockCachingAudioSource;

      expect(captured.uri.toString(), equals('https://stream.radiozak.pl:8443/zak.aac'));
    });
  });
}
