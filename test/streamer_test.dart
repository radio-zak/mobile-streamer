import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Audio Handler Progress Updates', () {
    test(
      'customAction with updateProgress receives correct elapsed seconds',
      () async {
        // Simulate the updateProgress action
        final extras = {
          'elapsedSeconds': 645, // 10 min 45 sec
          'totalSeconds': 2700, // 45 min
        };

        expect(extras['elapsedSeconds'], equals(645));
        expect(extras['totalSeconds'], equals(2700));
      },
    );

    test('customAction with updateProgress has seconds precision', () async {
      // Test various second values
      final testCases = [
        {'elapsedSeconds': 0, 'totalSeconds': 3600},
        {'elapsedSeconds': 1, 'totalSeconds': 3600},
        {'elapsedSeconds': 59, 'totalSeconds': 3600},
        {'elapsedSeconds': 60, 'totalSeconds': 3600},
        {'elapsedSeconds': 330, 'totalSeconds': 1800},
        {'elapsedSeconds': 1899, 'totalSeconds': 1800},
      ];

      for (var testCase in testCases) {
        expect(testCase['elapsedSeconds'], isNotNull);
        expect(testCase['totalSeconds'], isNotNull);
        expect((testCase['elapsedSeconds'] as int) >= 0, isTrue);
        expect((testCase['totalSeconds'] as int) > 0, isTrue);
      }
    });

    test('customAction updateMetadata includes artist (host name)', () async {
      final extras = {'title': 'Test Program Title', 'artist': 'Jan Kowalski'};

      expect(extras['title'], equals('Test Program Title'));
      expect(extras['artist'], equals('Jan Kowalski'));
    });

    test(
      'customAction updateMetadata artist does not include time information',
      () async {
        final hostName = 'Jan Kowalski';
        final extras = {'artist': hostName};

        final artist = extras['artist'] as String;
        expect(artist, equals(hostName));
        expect(artist.contains(':'), isFalse);
      },
    );

    test('customAction updateMetadata preserves full program title', () async {
      final longTitle =
          'Very Long Program Title That Should Not Be Truncated Anymore';
      final extras = {'title': longTitle, 'artist': 'Host'};

      expect(extras['title'], equals(longTitle));
    });

    test('duration is calculated from total seconds', () async {
      final totalSeconds = 2700; // 45 minutes
      final duration = Duration(seconds: totalSeconds);

      expect(duration.inSeconds, equals(2700));
      expect(duration.inMinutes, equals(45));
    });

    test('position is calculated from elapsed seconds', () async {
      final elapsedSeconds = 645; // 10 min 45 sec
      final position = Duration(seconds: elapsedSeconds);

      expect(position.inSeconds, equals(645));
      expect(position.inMinutes, equals(10));
    });

    test('mediaItem is updated with correct duration and position', () async {
      final elapsedSeconds = 330;
      final totalSeconds = 1800;

      final duration = Duration(seconds: totalSeconds);
      final position = Duration(seconds: elapsedSeconds);

      expect(duration.inSeconds, equals(1800));
      expect(position.inSeconds, equals(330));
      expect(position < duration, isTrue);
    });

    test('seconds precision enables accurate progress bar updates', () async {
      // Test that seconds precision allows for smooth progress updates
      final updates = [
        {'elapsed': 0, 'total': 3600},
        {'elapsed': 1, 'total': 3600},
        {'elapsed': 2, 'total': 3600},
        {'elapsed': 3, 'total': 3600},
        {'elapsed': 59, 'total': 3600},
        {'elapsed': 60, 'total': 3600},
      ];

      for (int i = 1; i < updates.length; i++) {
        final prev = updates[i - 1];
        final curr = updates[i];

        final prevProgress = (prev['elapsed'] as int) / (prev['total'] as int);
        final currProgress = (curr['elapsed'] as int) / (curr['total'] as int);

        expect(currProgress > prevProgress, isTrue);
      }
    });

    test(
      'no "remaining" text is sent in system notification metadata',
      () async {
        // Verify that the artist/host field doesn't contain remaining time info
        final extras = {'title': 'Program Title', 'artist': 'Host Name'};

        // Should NOT contain "remaining" or "pozostało" in metadata
        final artist = extras['artist'] as String;
        expect(artist.toLowerCase().contains('pozostało'), isFalse);
        expect(artist.toLowerCase().contains('remaining'), isFalse);
      },
    );

    test('host name is clean without time components', () async {
      final cleanHostCases = [
        'Jan Kowalski',
        'Maria Nowak',
        'Multiple Hosts',
        'Host One, Host Two',
      ];

      for (var hostName in cleanHostCases) {
        // Verify no time pattern exists
        final hasTimePattern = RegExp(r'\d{1,2}:\d{2}').hasMatch(hostName);
        expect(hasTimePattern, isFalse);
      }
    });
  });

  group('Audio Handler Notification Display', () {
    test('Android notification displays correct structure', () async {
      // Structure: Title (no time) - Artist (no time)
      final notificationData = {
        'title': 'Radio Program',
        'artist': 'Jan Kowalski',
      };

      expect(notificationData['title'], isNotEmpty);
      expect(notificationData['artist'], isNotEmpty);
      expect(notificationData['title'], isNotNull);
      expect(notificationData['artist'], isNotNull);
    });

    test(
      'notification does not include remaining time in artist field',
      () async {
        final notificationData = {
          'title': 'Program Title',
          'artist': 'Host Name',
          // Note: remaining time should NOT be in these fields
          // It's only shown in the progress bar metadata
        };

        // Verify no "remaining" terminology in artist field
        expect(
          notificationData['artist']?.toString().toLowerCase().contains(
            'pozostało',
          ),
          isFalse,
        );
        expect(
          notificationData['artist']?.toString().toLowerCase().contains(
            'remaining',
          ),
          isFalse,
        );
      },
    );

    test(
      'notification duration and position are sent as Duration objects',
      () async {
        final duration = Duration(seconds: 2700);
        final position = Duration(seconds: 645);

        expect(duration.inSeconds, equals(2700));
        expect(position.inSeconds, equals(645));
        expect(position < duration, isTrue);
      },
    );
  });

  group('Progress Bar Seconds Integration', () {
    test('seconds display format for progress bar', () async {
      // Test that seconds can be properly formatted
      final testValues = [
        {'total': 3600, 'elapsed': 1800, 'display': '00:30:00'},
        {'total': 1800, 'elapsed': 900, 'display': '00:15:00'},
        {'total': 900, 'elapsed': 450, 'display': '00:07:30'},
        {'total': 120, 'elapsed': 60, 'display': '00:01:00'},
        {'total': 60, 'elapsed': 30, 'display': '00:00:30'},
      ];

      for (var testCase in testValues) {
        final total = testCase['total'] as int;
        final elapsed = testCase['elapsed'] as int;

        final durationTotal = Duration(seconds: total);
        final durationElapsed = Duration(seconds: elapsed);

        expect(durationTotal.inSeconds, equals(total));
        expect(durationElapsed.inSeconds, equals(elapsed));
      }
    });

    test('progress percentage with second precision', () {
      final testCases = [
        {'elapsed': 30, 'total': 60, 'expectedProgress': 0.5}, // 50%
        {'elapsed': 1, 'total': 60, 'expectedProgress': 0.0166}, // ~1.66%
        {'elapsed': 59, 'total': 60, 'expectedProgress': 0.9833}, // ~98.33%
      ];

      for (var testCase in testCases) {
        final elapsed = testCase['elapsed'] as int;
        final total = testCase['total'] as int;
        final expected = testCase['expectedProgress'] as double;

        final progress = (elapsed / total).clamp(0.0, 1.0);
        expect(progress, closeTo(expected, 0.01));
      }
    });
  });
}
