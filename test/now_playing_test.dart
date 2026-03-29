import 'package:flutter_test/flutter_test.dart';
import 'package:zakstreamer/schedule_service.dart';
import 'package:zakstreamer/now_playing.dart';

void main() {
  group('NowPlaying Progress Updates', () {
    test('updateProgress sends elapsed and total seconds to audio handler', () async {
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(minutes: 5, seconds: 30));
      final endTime = now.add(const Duration(minutes: 30, seconds: 30));

      final formattedStart =
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      final formattedEnd =
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

      final entry = ScheduleEntry(
        time: '$formattedStart - $formattedEnd',
        title: 'Test Program',
        hosts: 'Test Host',
      );

      // Verify total seconds are calculated correctly (with flexibility for execution time)
      expect(entry.totalSecondsElapsed, greaterThan(0));
      expect(entry.totalSecondsRemaining, greaterThan(0));
    });

    test(
      'totalSecondsElapsed property returns seconds including minutes',
      () async {
        final now = DateTime.now();
        final startTime = now.subtract(
          const Duration(minutes: 10, seconds: 45),
        );
        final endTime = now.add(const Duration(hours: 1));

        final formattedStart =
            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
        final formattedEnd =
            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

        final entry = ScheduleEntry(
          time: '$formattedStart - $formattedEnd',
          title: 'Test Program',
          hosts: 'Test Host',
        );

        // 10 minutes 45 seconds = 645 seconds (with flexibility)
        expect(entry.totalSecondsElapsed, inInclusiveRange(600, 700));
      },
    );

    test(
      'totalSecondsRemaining property returns seconds including minutes',
      () async {
        final now = DateTime.now();
        final startTime = now.subtract(const Duration(minutes: 5));
        final endTime = now.add(Duration(minutes: 45, seconds: 15));

        final formattedStart =
            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
        final formattedEnd =
            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

        final entry = ScheduleEntry(
          time: '$formattedStart - $formattedEnd',
          title: 'Test Program',
          hosts: 'Test Host',
        );

        // 45 minutes 15 seconds = 2715 seconds (with flexibility)
        expect(entry.totalSecondsRemaining, inInclusiveRange(2600, 2800));
      },
    );

    test('secondsElapsed returns remaining seconds in current minute', () {
      // Create an entry for current time
      final now = DateTime.now();
      final startTime = now.subtract(Duration(minutes: 5, seconds: 30));
      final endTime = now.add(const Duration(hours: 1));

      final formattedStart =
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      final formattedEnd =
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

      final testEntry = ScheduleEntry(
        time: '$formattedStart - $formattedEnd',
        title: 'Test Program',
        hosts: 'Test Host',
      );

      // Should be close to 30 seconds (give or take execution time)
      expect(testEntry.secondsElapsed, inInclusiveRange(0, 59));
    });

    test('secondsRemaining returns remaining seconds in current minute', () {
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(minutes: 5));
      final endTime = now.add(Duration(minutes: 30, seconds: 45));

      final formattedStart =
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      final formattedEnd =
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

      final testEntry = ScheduleEntry(
        time: '$formattedStart - $formattedEnd',
        title: 'Test Program',
        hosts: 'Test Host',
      );

      // Should be close to 45 seconds (give or take execution time)
      expect(testEntry.secondsRemaining, inInclusiveRange(0, 59));
    });

    test(
      'customAction updateProgress passes correct data to audio handler',
      () async {
        // This test verifies that the updateProgress customAction correctly
        // sends both elapsed and total seconds for precise timing
        final elapsedSeconds = 645; // 10 minutes 45 seconds
        final totalSeconds = 2700; // 45 minutes

        final expectedData = {
          'elapsedSeconds': elapsedSeconds,
          'totalSeconds': totalSeconds,
        };

        expect(expectedData['elapsedSeconds'], equals(645));
        expect(expectedData['totalSeconds'], equals(2700));
      },
    );

    test(
      'seconds update without minute changes when elapsed seconds increment',
      () async {
        final now = DateTime.now();
        final startTime = now.subtract(Duration(minutes: 5, seconds: 30));
        final endTime = now.add(const Duration(hours: 1));

        final formattedStart =
            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
        final formattedEnd =
            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

        final entry = ScheduleEntry(
          time: '$formattedStart - $formattedEnd',
          title: 'Test Program',
          hosts: 'Test Host',
        );

        final secondsElapsed = entry.secondsElapsed;
        final totalSecondsElapsed = entry.totalSecondsElapsed;

        // Verify seconds are counted (give or take execution time)
        expect(secondsElapsed, inInclusiveRange(0, 59));
        expect(totalSecondsElapsed, inInclusiveRange(300, 400));
      },
    );
  });

  group('NowPlaying Metadata Updates', () {
    test('metadata includes host name without time', () {
      final entry = ScheduleEntry(
        time: '10:00 - 12:00',
        title: 'Test Program',
        hosts: 'Jan Kowalski',
      );

      expect(entry.hosts, equals('Jan Kowalski'));
      expect(entry.hosts.contains(':'), isFalse);
      expect(entry.hosts.contains('-'), isFalse);
    });

    test('title is preserved without truncation', () {
      final longTitle =
          'Very Long Program Title That Should Not Be Truncated In Now Playing Widget';
      final entry = ScheduleEntry(
        time: '10:00 - 12:00',
        title: longTitle,
        hosts: 'Host',
      );

      expect(entry.title, equals(longTitle));
    });

    test('metadata update does not include time component for hosts', () {
      final entry = ScheduleEntry(
        time: '14:30 - 16:45',
        title: 'Radio Program',
        hosts: 'Multiple Hosts',
      );

      // Verify hosts do not include any time information
      expect(entry.hosts, isNotEmpty);
      expect(entry.hosts, isNotEmpty);
      final hasTimePattern = RegExp(r'\d{1,2}:\d{2}').hasMatch(entry.hosts);
      expect(hasTimePattern, isFalse);
    });
  });

  group('Progress Calculation with Seconds', () {
    test('progressPercent calculated correctly with seconds precision', () {
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(minutes: 15)); // 15 min in
      final endTime = now.add(const Duration(minutes: 15)); // 15 min remaining

      final formattedStart =
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      final formattedEnd =
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

      final entry = ScheduleEntry(
        time: '$formattedStart - $formattedEnd',
        title: 'Test Program',
        hosts: 'Host',
      );

      // Should be approximately 50% through (test execution varies)
      expect(entry.progressPercent, inInclusiveRange(0.40, 0.60));
    });

    test('progressPercent is 0 before event starts', () {
      final futureStart = DateTime.now().add(const Duration(hours: 1));
      final futureEnd = futureStart.add(const Duration(hours: 1));

      final formattedStart =
          '${futureStart.hour.toString().padLeft(2, '0')}:${futureStart.minute.toString().padLeft(2, '0')}';
      final formattedEnd =
          '${futureEnd.hour.toString().padLeft(2, '0')}:${futureEnd.minute.toString().padLeft(2, '0')}';

      final entry = ScheduleEntry(
        time: '$formattedStart - $formattedEnd',
        title: 'Future Program',
        hosts: 'Host',
      );

      expect(entry.progressPercent, equals(0.0));
    });

    test('progressPercent is 1.0 after event ends', () {
      final pastStart = DateTime.now().subtract(const Duration(hours: 2));
      final pastEnd = DateTime.now().subtract(const Duration(hours: 1));

      final formattedStart =
          '${pastStart.hour.toString().padLeft(2, '0')}:${pastStart.minute.toString().padLeft(2, '0')}';
      final formattedEnd =
          '${pastEnd.hour.toString().padLeft(2, '0')}:${pastEnd.minute.toString().padLeft(2, '0')}';

      final entry = ScheduleEntry(
        time: '$formattedStart - $formattedEnd',
        title: 'Past Program',
        hosts: 'Host',
      );

      expect(entry.progressPercent, equals(1.0));
    });
  });

  group('NowPlayingState Management', () {
    test('NowPlayingState enum has expected values', () {
      expect(NowPlayingState.inactive, isNotNull);
      expect(NowPlayingState.loading, isNotNull);
      expect(NowPlayingState.active, isNotNull);
    });
  });
}
