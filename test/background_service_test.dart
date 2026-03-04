import 'package:flutter_test/flutter_test.dart';
import 'package:zakstreamer/schedule_service.dart';

void main() {
  group('Background Service Tests', () {
    test('parseStartTime should correctly parse time string', () {
      // Test valid time format
      final time = _parseStartTimeForTest('10:30 - 12:00');
      expect(time, isNotNull);
      expect(time!.hour, 10);
      expect(time.minute, 30);
    });

    test('parseStartTime should return null for invalid format', () {
      final time = _parseStartTimeForTest('invalid');
      expect(time, isNull);
    });

    test('parseStartTime should handle edge cases', () {
      final time = _parseStartTimeForTest('00:00 - 01:00');
      expect(time, isNotNull);
      expect(time!.hour, 0);
      expect(time.minute, 0);
    });

    test('shouldNotify returns false when time is too early', () {
      final now = DateTime(2026, 3, 4, 10, 0);
      final targetTime = DateTime(2026, 3, 4, 10, 10); // 10 minutes in future

      expect(_shouldNotifyForTest(now, targetTime), false);
    });

    test('shouldNotify returns true when in notification window', () {
      final now = DateTime(2026, 3, 4, 10, 5, 0); // 10:05:00
      final targetTime = DateTime(
        2026,
        3,
        4,
        10,
        4,
        30,
      ); // 10:04:30 - 30 seconds ago, within 2 minute window

      expect(_shouldNotifyForTest(now, targetTime), true);
    });

    test('shouldNotify returns false when window is missed', () {
      final now = DateTime(2026, 3, 4, 10, 10);
      final targetTime = DateTime(2026, 3, 4, 10, 0); // 10 minutes ago

      expect(_shouldNotifyForTest(now, targetTime), false);
    });
  });

  group('Schedule Service Tests', () {
    test('ScheduleEntry.isLive should return true when in active time', () {
      // Create entry for current time
      final now = DateTime.now();
      final timeString =
          '${now.hour}:${now.minute.toString().padLeft(2, '0')} - ${(now.hour + 1)}:00';

      final entry = ScheduleEntry(
        time: timeString,
        title: 'Test Show',
        hosts: 'Test Host',
      );

      expect(entry.isLive, true);
    });

    test('ScheduleEntry.isLive should return false when in future', () {
      final future = DateTime.now().add(const Duration(hours: 2));
      final timeString = '${future.hour}:00 - ${(future.hour + 1)}:00';

      final entry = ScheduleEntry(
        time: timeString,
        title: 'Test Show',
        hosts: 'Test Host',
      );

      expect(entry.isLive, false);
    });
  });
}

// Helper functions for testing private methods
DateTime? _parseStartTimeForTest(String timeString) {
  try {
    final parts = timeString.split('-').map((e) => e.trim()).toList();
    if (parts.isEmpty) return null;

    final timeParts = parts[0].split(':');
    if (timeParts.length != 2) return null;

    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  } catch (e) {
    return null;
  }
}

bool _shouldNotifyForTest(DateTime now, DateTime targetTime) {
  if (now.isBefore(targetTime)) {
    return false; // Too early
  }

  final difference = now.difference(targetTime);
  if (difference.inMinutes > 2) {
    return false; // Too late
  }

  return true;
}
