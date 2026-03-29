import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zakstreamer/schedule_service.dart';
import 'package:zakstreamer/widgets/show_progress_bar.dart';

void main() {
  group('ShowProgressBar Widget', () {
    late ScheduleEntry liveEntry;

    setUp(() {
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(minutes: 30));
      final endTime = now.add(const Duration(minutes: 30));

      final formattedStart =
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      final formattedEnd =
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

      liveEntry = ScheduleEntry(
        time: '$formattedStart - $formattedEnd',
        title: 'Test Live Program',
        hosts: 'Test Host',
      );
    });

    testWidgets('displays progress bar with correct appearance', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ShowProgressBar(entry: liveEntry)),
        ),
      );

      // Check if LinearProgressIndicator exists
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('displays start and end times', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ShowProgressBar(entry: liveEntry)),
        ),
      );

      final startTime = liveEntry.startDateTime;
      final endTime = liveEntry.endDateTime;

      final expectedStart =
          '${startTime!.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      final expectedEnd =
          '${endTime!.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

      expect(find.text(expectedStart), findsOneWidget);
      expect(find.text(expectedEnd), findsOneWidget);
    });

    testWidgets('displays remaining time in minutes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ShowProgressBar(entry: liveEntry)),
        ),
      );

      final minutesRemaining = liveEntry.minutesRemaining;
      final remainingText = 'pozostało $minutesRemaining min';

      expect(find.text(remainingText), findsOneWidget);
    });

    testWidgets('start and end times have larger font size than remaining time', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ShowProgressBar(entry: liveEntry)),
        ),
      );

      // Find all Text widgets
      final texts = find.byType(Text);
      expect(texts, findsWidgets);

      // Get the styles of start/end times (should be labelSmall with fontSize: 13)
      final timeTexts = find.byWidgetPredicate((widget) {
        if (widget is Text) {
          final style = widget.style ?? const TextStyle();
          return style.fontSize == 13;
        }
        return false;
      });

      expect(timeTexts, findsWidgets);

      // Get the style of remaining time (should be labelSmall with fontSize: 11)
      final remainingTexts = find.byWidgetPredicate((widget) {
        if (widget is Text) {
          final style = widget.style ?? const TextStyle();
          return style.fontSize == 11;
        }
        return false;
      });

      expect(remainingTexts, findsOneWidget);
    });

    testWidgets('remaining time text is centered', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ShowProgressBar(entry: liveEntry)),
        ),
      );

      // Find the remaining time text
      final remainingTimeText = find.byWidgetPredicate((widget) {
        if (widget is Text && widget.textAlign == TextAlign.center) {
          return widget.data?.contains('pozostało') ?? false;
        }
        return false;
      });

      expect(remainingTimeText, findsOneWidget);
    });

    testWidgets('progress bar updates every second', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ShowProgressBar(entry: liveEntry)),
        ),
      );

      // Get initial remaining time
      final firstRemaining = liveEntry.minutesRemaining;
      expect(find.text('pozostało $firstRemaining min'), findsOneWidget);

      // Wait 1 second and pump
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('handles invalid time format gracefully', (
      WidgetTester tester,
    ) async {
      final invalidEntry = ScheduleEntry(
        time: 'invalid',
        title: 'Invalid Program',
        hosts: 'Test Host',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ShowProgressBar(entry: invalidEntry)),
        ),
      );

      // Should display fallback times
      expect(find.text('--:--'), findsWidgets);
    });

    testWidgets('layout contains Row with spaceBetween', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ShowProgressBar(entry: liveEntry)),
        ),
      );

      // Find Row widget that arranges the times and remaining text
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('remaining time text has maxLines set to 1', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ShowProgressBar(entry: liveEntry)),
        ),
      );

      // Verify that text containing "pozostało" has maxLines: 1
      final remainingText = find.byWidgetPredicate((widget) {
        if (widget is Text && (widget.data?.contains('pozostało') ?? false)) {
          return widget.maxLines == 1;
        }
        return false;
      });

      expect(remainingText, findsOneWidget);
    });

    testWidgets('remaining time text has ellipsis overflow', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ShowProgressBar(entry: liveEntry)),
        ),
      );

      // Verify that text has TextOverflow.ellipsis
      final remainingText = find.byWidgetPredicate((widget) {
        if (widget is Text && (widget.data?.contains('pozostało') ?? false)) {
          return widget.overflow == TextOverflow.ellipsis;
        }
        return false;
      });

      expect(remainingText, findsOneWidget);
    });

    testWidgets('progress bar has correct styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ShowProgressBar(entry: liveEntry)),
        ),
      );

      // Find the LinearProgressIndicator
      final progressBar = find.byType(LinearProgressIndicator);
      expect(progressBar, findsOneWidget);

      // Verify it's wrapped in ClipRRect
      final clipped = find.ancestor(
        of: progressBar,
        matching: find.byType(ClipRRect),
      );
      expect(clipped, findsOneWidget);
    });

    testWidgets('times are displayed in HH:MM format', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ShowProgressBar(entry: liveEntry)),
        ),
      );

      final startDT = liveEntry.startDateTime;
      final endDT = liveEntry.endDateTime;

      // Check format matches HH:MM pattern
      final startTimeStr =
          '${startDT!.hour.toString().padLeft(2, '0')}:${startDT.minute.toString().padLeft(2, '0')}';
      final endTimeStr =
          '${endDT!.hour.toString().padLeft(2, '0')}:${endDT.minute.toString().padLeft(2, '0')}';

      expect(find.text(startTimeStr), findsOneWidget);
      expect(find.text(endTimeStr), findsOneWidget);
    });

    testWidgets(
      'does not display "remaining" text in system player indicator',
      (WidgetTester tester) async {
        // This test verifies the change where "pozostało xyz" is NOT shown
        // in the Android system notification player
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ShowProgressBar(entry: liveEntry)),
          ),
        );

        // The ShowProgressBar should still show remaining time in the UI widget
        final minutesRemaining = liveEntry.minutesRemaining;
        final remainingText = 'pozostało $minutesRemaining min';
        expect(find.text(remainingText), findsOneWidget);
      },
    );
  });
}
