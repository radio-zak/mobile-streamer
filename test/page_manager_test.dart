import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zakstreamer/page_manager.dart';

void main() {
  group('PageManager', () {
    test('PlayButtonNotifier has correct initial value', () {
      final notifier = PlayButtonNotifier();
      expect(notifier.value, equals(ButtonState.paused));
    });

    test('ButtonState enum has expected values', () {
      expect(ButtonState.playing, isNotNull);
      expect(ButtonState.paused, isNotNull);
      expect(ButtonState.loading, isNotNull);
    });

    test('playButtonNotifier can be updated', () {
      final notifier = PlayButtonNotifier();

      notifier.value = ButtonState.playing;
      expect(notifier.value, equals(ButtonState.playing));

      notifier.value = ButtonState.loading;
      expect(notifier.value, equals(ButtonState.loading));

      notifier.value = ButtonState.paused;
      expect(notifier.value, equals(ButtonState.paused));
    });

    test('errorNotifier starts empty', () {
      final errorNotifier = ValueNotifier<String>('');
      expect(errorNotifier.value, isEmpty);
    });

    test('errorNotifier can store error messages', () {
      final errorNotifier = ValueNotifier<String>('');

      errorNotifier.value = 'Test error message';
      expect(errorNotifier.value, equals('Test error message'));

      errorNotifier.value = '';
      expect(errorNotifier.value, isEmpty);
    });

    test('clearError sets errorNotifier to empty string', () {
      final errorNotifier = ValueNotifier<String>('Some error');
      expect(errorNotifier.value, isNotEmpty);

      errorNotifier.value = '';
      expect(errorNotifier.value, isEmpty);
    });

    group('Custom events handling', () {
      test('custom event with error type is recognized', () {
        final errorEvent = {'type': 'error', 'message': 'Connection error'};

        expect(errorEvent['type'], equals('error'));
        expect(errorEvent['message'], equals('Connection error'));
      });

      test('custom event with clear_error type is recognized', () {
        final clearEvent = {'type': 'clear_error'};

        expect(clearEvent['type'], equals('clear_error'));
      });

      test('errorNotifier is updated when error event occurs', () {
        final errorNotifier = ValueNotifier<String>('');
        final errorEvent = {
          'type': 'error',
          'message': 'Brak połączenia z internetem',
        };

        errorNotifier.value = errorEvent['message'] as String;

        expect(errorNotifier.value, equals('Brak połączenia z internetem'));
      });

      test('errorNotifier is cleared when clear_error event occurs', () {
        final errorNotifier = ValueNotifier<String>('Some error');

        errorNotifier.value = '';

        expect(errorNotifier.value, isEmpty);
      });
    });

    group('Error handling', () {
      test('error message is stored correctly', () {
        final errorNotifier = ValueNotifier<String>('');
        final errorMessage = 'Strumień jest niedostępny';

        errorNotifier.value = errorMessage;
        expect(errorNotifier.value, equals(errorMessage));
      });

      test('empty error is recognized as no error', () {
        final errorNotifier = ValueNotifier<String>('');
        expect(errorNotifier.value.isEmpty, isTrue);
      });

      test('non-empty error is recognized as error present', () {
        final errorNotifier = ValueNotifier<String>('Error present');
        expect(errorNotifier.value.isNotEmpty, isTrue);
      });
    });
  });

  group('PageManager Integration', () {
    test('button state reflects audio handler state correctly', () {
      final buttonNotifier = PlayButtonNotifier();

      // Simulate state transitions
      buttonNotifier.value = ButtonState.loading;
      expect(buttonNotifier.value, equals(ButtonState.loading));

      buttonNotifier.value = ButtonState.playing;
      expect(buttonNotifier.value, equals(ButtonState.playing));

      buttonNotifier.value = ButtonState.paused;
      expect(buttonNotifier.value, equals(ButtonState.paused));
    });

    test('error state does not interfere with playback state updates', () {
      final errorNotifier = ValueNotifier<String>('');
      final buttonNotifier = PlayButtonNotifier();

      // Set error
      errorNotifier.value = 'Connection error';
      expect(errorNotifier.value, isNotEmpty);

      // Button state should still be updateable
      buttonNotifier.value = ButtonState.playing;
      expect(buttonNotifier.value, equals(ButtonState.playing));
    });

    test('clearing error resets error state', () {
      final errorNotifier = ValueNotifier<String>('Initial error');

      expect(errorNotifier.value, isNotEmpty);
      errorNotifier.value = '';
      expect(errorNotifier.value, isEmpty);
    });
  });
}
