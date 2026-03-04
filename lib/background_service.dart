import 'dart:async';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'notifications.dart';
import 'schedule_service.dart';

final _log = Logger('BackgroundService');

// SharedPreferences key to track if background tasks are initialized
const String _backgroundTasksEnabledKey = 'background_tasks_enabled';

/// Initializes background tasks for schedule notifications
Future<void> initializeBackgroundTasks() async {
  await Workmanager().initialize(
    callbackDispatcher,
  );

  // Schedule periodic task every 30 minutes
  await Workmanager().registerPeriodicTask(
    'schedule_check',
    'checkScheduleUpdates',
    frequency: const Duration(minutes: 30),
    initialDelay: const Duration(minutes: 5),
  );

  // Mark that background tasks are enabled
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_backgroundTasksEnabledKey, true);

  _log.info('Background schedule check initialized');
}

/// Checks if background tasks need to be restored and restores them if needed
/// This is called on app startup to ensure background tasks persist after process kill
Future<void> restoreBackgroundTasksIfNeeded() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final areEnabled = prefs.getBool(_backgroundTasksEnabledKey) ?? false;

    if (areEnabled) {
      _log.info('Restoring background tasks after app restart');
      // Re-initialize background tasks
      await initializeBackgroundTasks();
    }
  } catch (e) {
    _log.warning('Failed to restore background tasks: $e');
  }
}

/// Background task dispatcher - called by Workmanager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      if (taskName == 'checkScheduleUpdates') {
        await _checkAndNotifyScheduleUpdate();
      }
      return true;
    } catch (e) {
      _log.severe('Background task failed: $e');
      return false;
    }
  });
}

/// Fetches schedule and sends notification if live show is different
Future<void> _checkAndNotifyScheduleUpdate() async {
  try {
    _log.info('Background task: Checking schedule updates...');

    final scheduleService = ScheduleService();

    // Try to fetch schedule with retry logic using background-compatible method
    Map<String, List<dynamic>>? schedule;
    int retries = 3;
    int delayMs = 2000;

    while (retries > 0 && schedule == null) {
      try {
        schedule = await scheduleService.fetchScheduleBackground().timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            _log.warning('Schedule fetch timeout');
            throw TimeoutException('Schedule fetch timeout');
          },
        );
        break;
      } on SocketException catch (e) {
        retries--;
        _log.warning('Network error (retries left: $retries): $e');

        if (retries > 0) {
          // Wait before retrying with exponential backoff
          await Future.delayed(Duration(milliseconds: delayMs));
          delayMs *= 2;
        }
      } on TimeoutException catch (e) {
        retries--;
        _log.warning('Timeout (retries left: $retries): $e');

        if (retries > 0) {
          await Future.delayed(Duration(milliseconds: delayMs));
          delayMs *= 2;
        }
      } catch (e) {
        retries--;
        _log.warning('Schedule fetch failed (retries left: $retries): $e');

        if (retries > 0) {
          // Wait before retrying with exponential backoff
          await Future.delayed(Duration(milliseconds: delayMs));
          delayMs *= 2;
        }
      }
    }

    if (schedule == null) {
      _log.severe('Could not fetch schedule after retries');
      return;
    }

    final todayIndex = (DateTime.now().weekday - 1).clamp(0, 6);

    // Safe access to today's key
    if (todayIndex >= schedule.keys.length) {
      _log.warning('Schedule has only ${schedule.keys.length} days, today index is $todayIndex');
      return;
    }

    final todayKey = schedule.keys.elementAt(todayIndex);
    final entriesToday = schedule[todayKey] ?? [];

    // Find live show
    final liveEntry = entriesToday.firstWhere(
      (e) => e.isLive,
      orElse: () => null as dynamic,
    ) as dynamic;

    if (liveEntry != null) {
      // Get previous live show from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final previousShow = prefs.getString('lastNotifiedShow');
      final currentShow = liveEntry.title;

      // Only notify if show has changed
      if (previousShow != currentShow) {
        _log.info('Background: New live show detected: $currentShow');

        final artist = liveEntry.hosts.isNotEmpty
            ? liveEntry.hosts
            : 'Studenckie Radio "ŻAK" Politechniki Łódzkiej';

        await Notifications.showNotification(
          title: 'Nowy program na żywo',
          body: '$currentShow\nProwadzący: $artist',
          payload: 'schedule',
        );

        // Remember this show
        await prefs.setString('lastNotifiedShow', currentShow);
      }
    } else {
      _log.info('Background: No live show at this time');
      // Clear if no live show
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('lastNotifiedShow');
    }
  } catch (e, stackTrace) {
    _log.severe('Error checking schedule: $e', stackTrace);
  }
}

/// Disables background tasks and removes them from Workmanager
Future<void> disableBackgroundTasks() async {
  try {
    _log.info('Disabling background tasks');
    await Workmanager().cancelAll();

    // Mark that background tasks are disabled
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_backgroundTasksEnabledKey, false);

    _log.info('Background tasks disabled');
  } catch (e) {
    _log.severe('Failed to disable background tasks: $e');
  }
}

/// Checks if background tasks are currently enabled
Future<bool> areBackgroundTasksEnabled() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_backgroundTasksEnabledKey) ?? false;
  } catch (e) {
    _log.warning('Failed to check background tasks status: $e');
    return false;
  }
}
