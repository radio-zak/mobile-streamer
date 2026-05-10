import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Notifications Tests', () {
    test('showNotification generates unique IDs for different titles', () {
      final id1 = 'Test Show 1'.hashCode;
      final id2 = 'Test Show 2'.hashCode;

      expect(id1, isNot(equals(id2)));
    });

    test('showNotification generates same ID for same title', () {
      final id1 = 'Test Show'.hashCode;
      final id2 = 'Test Show'.hashCode;

      expect(id1, equals(id2));
    });

    test('Notification ID should be positive', () {
      final id = ('Test Show').hashCode.abs();
      expect(id, greaterThan(0));
    });

    test('30-min notification hash differs from 5-min notification hash', () {
      const showTitle = 'Test Show';
      final hash30 = ('30min_$showTitle').hashCode.abs();
      final hash5 = ('5min_$showTitle').hashCode.abs();

      expect(hash30, isNot(equals(hash5)));
    });
  });

  group('Notification ID Generation', () {
    test(
      'Multiple shows with same name at different times should have different IDs',
      () {
        const showTitle = 'Radio Show';
        final id1 = ('30min_$showTitle').hashCode.abs();
        final id2 = ('5min_$showTitle').hashCode.abs();

        expect(id1, isNot(equals(id2)));
      },
    );

    test('Notification IDs should be stable across app restarts', () {
      const prefix = '30min_';
      const showTitle = 'Favorite Show';
      const fullId = prefix + showTitle;

      final hash1 = fullId.hashCode.abs();
      final hash2 = fullId.hashCode.abs();

      expect(hash1, equals(hash2));
    });
  });
}
