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
      streamer = Streamer(audioPlayer: mockAudioPlayer);
    });

    test('initial state is correct', () {
      // Test logic will go here
    });
  });
}
