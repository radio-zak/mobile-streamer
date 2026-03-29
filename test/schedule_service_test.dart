import 'package:flutter_test/flutter_test.dart';
import 'package:zakstreamer/schedule_service.dart';

void main() {
  group('ScheduleEntry', () {
    group('Time calculations', () {
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

        expect(testEntry.secondsElapsed, inInclusiveRange(0, 59));
      });

      test('totalSecondsElapsed returns total seconds from start', () {
        final now = DateTime.now();
        final startTime = now.subtract(Duration(minutes: 10, seconds: 45));
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

        // Should be approximately 10 minutes and 45 seconds = 645 seconds
        // However test execution time varies, so we need a wider range
        expect(testEntry.totalSecondsElapsed, inInclusiveRange(600, 700));
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

        expect(testEntry.secondsRemaining, inInclusiveRange(0, 59));
      });

      test('totalSecondsRemaining returns total remaining seconds', () {
        final now = DateTime.now();
        final startTime = now.subtract(const Duration(minutes: 5));
        final endTime = now.add(Duration(minutes: 15, seconds: 30));

        final formattedStart =
            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
        final formattedEnd =
            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

        final testEntry = ScheduleEntry(
          time: '$formattedStart - $formattedEnd',
          title: 'Test Program',
          hosts: 'Test Host',
        );

        // Should be approximately 15 minutes and 30 seconds = 930 seconds
        // However test execution time varies, so we need a wider range
        expect(testEntry.totalSecondsRemaining, inInclusiveRange(850, 1000));
      });

      test('secondsElapsed returns 0 before event starts', () {
        final futureStart = DateTime.now().add(const Duration(hours: 1));
        final futureEnd = futureStart.add(const Duration(hours: 1));

        final formattedStart =
            '${futureStart.hour.toString().padLeft(2, '0')}:${futureStart.minute.toString().padLeft(2, '0')}';
        final formattedEnd =
            '${futureEnd.hour.toString().padLeft(2, '0')}:${futureEnd.minute.toString().padLeft(2, '0')}';

        final testEntry = ScheduleEntry(
          time: '$formattedStart - $formattedEnd',
          title: 'Test Program',
          hosts: 'Test Host',
        );

        expect(testEntry.secondsElapsed, equals(0));
      });

      test('totalSecondsElapsed returns 0 before event starts', () {
        final futureStart = DateTime.now().add(const Duration(hours: 1));
        final futureEnd = futureStart.add(const Duration(hours: 1));

        final formattedStart =
            '${futureStart.hour.toString().padLeft(2, '0')}:${futureStart.minute.toString().padLeft(2, '0')}';
        final formattedEnd =
            '${futureEnd.hour.toString().padLeft(2, '0')}:${futureEnd.minute.toString().padLeft(2, '0')}';

        final testEntry = ScheduleEntry(
          time: '$formattedStart - $formattedEnd',
          title: 'Test Program',
          hosts: 'Test Host',
        );

        expect(testEntry.totalSecondsElapsed, equals(0));
      });

      test('secondsRemaining returns 0 after event ends', () {
        final pastStart = DateTime.now().subtract(const Duration(hours: 2));
        final pastEnd = DateTime.now().subtract(const Duration(hours: 1));

        final formattedStart =
            '${pastStart.hour.toString().padLeft(2, '0')}:${pastStart.minute.toString().padLeft(2, '0')}';
        final formattedEnd =
            '${pastEnd.hour.toString().padLeft(2, '0')}:${pastEnd.minute.toString().padLeft(2, '0')}';

        final testEntry = ScheduleEntry(
          time: '$formattedStart - $formattedEnd',
          title: 'Test Program',
          hosts: 'Test Host',
        );

        expect(testEntry.secondsRemaining, equals(0));
      });

      test('totalSecondsRemaining returns 0 after event ends', () {
        final pastStart = DateTime.now().subtract(const Duration(hours: 2));
        final pastEnd = DateTime.now().subtract(const Duration(hours: 1));

        final formattedStart =
            '${pastStart.hour.toString().padLeft(2, '0')}:${pastStart.minute.toString().padLeft(2, '0')}';
        final formattedEnd =
            '${pastEnd.hour.toString().padLeft(2, '0')}:${pastEnd.minute.toString().padLeft(2, '0')}';

        final testEntry = ScheduleEntry(
          time: '$formattedStart - $formattedEnd',
          title: 'Test Program',
          hosts: 'Test Host',
        );

        expect(testEntry.totalSecondsRemaining, equals(0));
      });
    });

    group('DateTime getters', () {
      test('startDateTime returns correct DateTime', () {
        final entry = ScheduleEntry(
          time: '14:30 - 16:45',
          title: 'Test Program',
          hosts: 'Test Host',
        );

        final startDT = entry.startDateTime;
        expect(startDT, isNotNull);
        expect(startDT!.hour, equals(14));
        expect(startDT.minute, equals(30));
      });

      test('endDateTime returns correct DateTime', () {
        final entry = ScheduleEntry(
          time: '14:30 - 16:45',
          title: 'Test Program',
          hosts: 'Test Host',
        );

        final endDT = entry.endDateTime;
        expect(endDT, isNotNull);
        expect(endDT!.hour, equals(16));
        expect(endDT.minute, equals(45));
      });

      test('endDateTime handles overnight time correctly', () {
        final entry = ScheduleEntry(
          time: '23:00 - 02:00',
          title: 'Late Night Show',
          hosts: 'Test Host',
        );

        final startDT = entry.startDateTime;
        final endDT = entry.endDateTime;

        expect(startDT, isNotNull);
        expect(endDT, isNotNull);
        expect(endDT!.isAfter(startDT!), isTrue);
      });
    });

    group('isLive detection', () {
      test('returns true when current time is within event time', () {
        final now = DateTime.now();
        final startTime = now.subtract(const Duration(minutes: 30));
        final endTime = now.add(const Duration(minutes: 30));

        final formattedStart =
            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
        final formattedEnd =
            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

        final entry = ScheduleEntry(
          time: '$formattedStart - $formattedEnd',
          title: 'Live Program',
          hosts: 'Test Host',
        );

        expect(entry.isLive, isTrue);
      });

      test('returns false when current time is before event', () {
        final futureStart = DateTime.now().add(const Duration(hours: 1));
        final futureEnd = futureStart.add(const Duration(hours: 2));

        final formattedStart =
            '${futureStart.hour.toString().padLeft(2, '0')}:${futureStart.minute.toString().padLeft(2, '0')}';
        final formattedEnd =
            '${futureEnd.hour.toString().padLeft(2, '0')}:${futureEnd.minute.toString().padLeft(2, '0')}';

        final entry = ScheduleEntry(
          time: '$formattedStart - $formattedEnd',
          title: 'Future Program',
          hosts: 'Test Host',
        );

        expect(entry.isLive, isFalse);
      });

      test('returns false when current time is after event', () {
        final pastStart = DateTime.now().subtract(const Duration(hours: 2));
        final pastEnd = DateTime.now().subtract(const Duration(hours: 1));

        final formattedStart =
            '${pastStart.hour.toString().padLeft(2, '0')}:${pastStart.minute.toString().padLeft(2, '0')}';
        final formattedEnd =
            '${pastEnd.hour.toString().padLeft(2, '0')}:${pastEnd.minute.toString().padLeft(2, '0')}';

        final entry = ScheduleEntry(
          time: '$formattedStart - $formattedEnd',
          title: 'Past Program',
          hosts: 'Test Host',
        );

        expect(entry.isLive, isFalse);
      });
    });

    group('minutesRemaining calculations', () {
      test('minutesRemaining excludes partial seconds', () {
        final now = DateTime.now();
        final startTime = now.subtract(const Duration(minutes: 5));
        final endTime = now.add(Duration(minutes: 30, seconds: 45));

        final formattedStart =
            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
        final formattedEnd =
            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

        final entry = ScheduleEntry(
          time: '$formattedStart - $formattedEnd',
          title: 'Test Program',
          hosts: 'Test Host',
        );

        expect(entry.minutesRemaining, inInclusiveRange(25, 35));
      });

      test('minutesRemaining returns 0 after event ends', () {
        final pastStart = DateTime.now().subtract(const Duration(hours: 2));
        final pastEnd = DateTime.now().subtract(const Duration(hours: 1));

        final formattedStart =
            '${pastStart.hour.toString().padLeft(2, '0')}:${pastStart.minute.toString().padLeft(2, '0')}';
        final formattedEnd =
            '${pastEnd.hour.toString().padLeft(2, '0')}:${pastEnd.minute.toString().padLeft(2, '0')}';

        final entry = ScheduleEntry(
          time: '$formattedStart - $formattedEnd',
          title: 'Test Program',
          hosts: 'Test Host',
        );

        expect(entry.minutesRemaining, equals(0));
      });
    });

    group('String getters', () {
      test('startTime extracts start time string correctly', () {
        final entry = ScheduleEntry(
          time: '09:15 - 11:30',
          title: 'Test Program',
          hosts: 'Test Host',
        );

        expect(entry.startTime, equals('09:15'));
      });

      test('endTime extracts end time string correctly', () {
        final entry = ScheduleEntry(
          time: '09:15 - 11:30',
          title: 'Test Program',
          hosts: 'Test Host',
        );

        expect(entry.endTime, equals('11:30'));
      });
    });

    group('Title handling', () {
      test('title is not truncated', () {
        final longTitle =
            'Very Long Program Title That Should Not Be Truncated In Now Playing';
        final entry = ScheduleEntry(
          time: '10:00 - 12:00',
          title: longTitle,
          hosts: 'Test Host',
        );

        expect(entry.title, equals(longTitle));
      });

      test('title preserves original value', () {
        final entry = ScheduleEntry(
          time: '10:00 - 12:00',
          title: 'Original Title',
          hosts: 'Test Host',
        );

        expect(entry.title, equals('Original Title'));
      });
    });

    group('Host information handling', () {
      test('hosts property contains only host name without time', () {
        final entry = ScheduleEntry(
          time: '10:00 - 12:00',
          title: 'Test Program',
          hosts: 'Jan Kowalski',
        );

        expect(entry.hosts, equals('Jan Kowalski'));
        expect(entry.hosts.contains(':'), isFalse);
      });

      test('hosts property preserved correctly', () {
        final hostName = 'Multiple Hosts Names';
        final entry = ScheduleEntry(
          time: '10:00 - 12:00',
          title: 'Test Program',
          hosts: hostName,
        );

        expect(entry.hosts, equals(hostName));
      });
    });
  });
}
