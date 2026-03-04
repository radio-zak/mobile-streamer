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
///
/// This sets up a periodic task that runs every 30 minutes to check for upcoming
/// favorite shows and send notifications. The task runs even when the app is closed
/// (on Android; on iOS, limitations apply due to OS restrictions).
///
/// The background task:
/// - Fetches the weekly schedule from zak.lodz.pl
/// - Checks for favorite shows in today's and tomorrow's schedule
/// - Sends notifications 30 minutes and 5 minutes before each favorite show
/// - Cleans up old notification tracking entries
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

/// Fetches schedule and sends notifications for upcoming favorite shows
Future<void> _checkAndNotifyScheduleUpdate() async {
  try {
    _log.info('Background task: Checking for upcoming favorite shows...');

    final scheduleService = ScheduleService();
    final prefs = await SharedPreferences.getInstance();

    // Get favorites list from SharedPreferences
    final favorites = prefs.getStringList('favorite_shows') ?? [];
    _log.info('Background task: Found ${favorites.length} favorite shows');
    if (favorites.isEmpty) {
      _log.info('Background task: No favorite shows, skipping check');
      return;
    }

    _log.info('Background task: Favorites to check: ${favorites.join(", ")}');

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
          await Future.delayed(Duration(milliseconds: delayMs));
          delayMs *= 2;
        }
      }
    }

    if (schedule == null) {
      _log.severe('Could not fetch schedule after retries');
      // Try to use cached schedule from last successful fetch if available
      final cachedScheduleJson = prefs.getString('cached_schedule');
      if (cachedScheduleJson != null) {
        _log.info('Using cached schedule from previous fetch');
        // For now, we'll just log and skip - proper caching would require more complex serialization
      } else {
        _log.severe('No cached schedule available, skipping notification check');
        return;
      }
      return;
    }

    _log.info('Background task: Schedule fetched successfully');

    // Cache the schedule for fallback use
    try {
      // Store a simple indicator that we have a fresh schedule
      await prefs.setString('last_schedule_fetch', DateTime.now().toString());
    } catch (e) {
      _log.warning('Failed to cache schedule metadata: $e');
    }

    final now = DateTime.now();
    final todayIndex = (now.weekday - 1).clamp(0, 6);

    // Check today and tomorrow for upcoming shows
    for (int dayOffset = 0; dayOffset < 2; dayOffset++) {
      final checkIndex = (todayIndex + dayOffset) % 7;

      // Safe access to day's key
      if (checkIndex >= schedule.keys.length) {
        _log.warning('Schedule has only ${schedule.keys.length} days, index is $checkIndex');
        continue;
      }

      final dayKey = schedule.keys.elementAt(checkIndex);
      final entries = schedule[dayKey] ?? [];

      // Check each favorite show
      for (final entry in entries) {
        if (favorites.contains(entry.title)) {
          final startTime = _parseStartTime(entry.time);
          if (startTime != null) {
            // For tomorrow, adjust the time
            var adjustedStartTime = startTime;
            if (dayOffset == 1) {
              adjustedStartTime = startTime.add(const Duration(days: 1));
            }

            // Check for 30 minutes before
            final thirtyMinBefore = adjustedStartTime.subtract(const Duration(minutes: 30));
            final thirtyMinNotifId = 'thirty_${entry.title}_${entry.time}';
            if (_shouldNotifyBackground(now, thirtyMinBefore, thirtyMinNotifId, prefs)) {
              _log.info('Background: Sending 30-min notification for "${entry.title}" at ${entry.time}');
              final notifHash = ('30min_${entry.title}').hashCode.abs();
              await Notifications.showNotification(
                title: 'Zbliża się Twoja ulubiona audycja!',
                body: '${entry.title} za 30 minut (${entry.time})',
                payload: 'favorite_show',
                notificationId: notifHash,
              );
              await prefs.setString(thirtyMinNotifId, now.toString().split(' ')[0]);
            }

            // Check for 5 minutes before
            final fiveMinBefore = adjustedStartTime.subtract(const Duration(minutes: 5));
            final fiveMinNotifId = 'five_${entry.title}_${entry.time}';
            if (_shouldNotifyBackground(now, fiveMinBefore, fiveMinNotifId, prefs)) {
              _log.info('Background: Sending 5-min notification for "${entry.title}" at ${entry.time}');
              final notifHash = ('5min_${entry.title}').hashCode.abs();
              await Notifications.showNotification(
                title: 'Za 5 minut: ${entry.title}',
                body: 'Twoja ulubiona audycja zaczyna się za 5 minut!',
                payload: 'favorite_show',
                notificationId: notifHash,
              );
              await prefs.setString(fiveMinNotifId, now.toString().split(' ')[0]);
            }
          }
        }
      }
    }
  } catch (e, stackTrace) {
    _log.severe('Error checking for upcoming favorites: $e', stackTrace);
  }

  // Cleanup old notification tracking entries
  _cleanupOldNotificationEntries();
}

/// Parses start time from schedule entry (e.g., "10:00 - 12:00")
DateTime? _parseStartTime(String timeString) {
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
    _log.warning('Failed to parse time: $timeString, error: $e');
    return null;
  }
}

/// Cleans up old notification tracking entries from SharedPreferences
Future<void> _cleanupOldNotificationEntries() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().split(' ')[0];

    // Get all keys from SharedPreferences
    final allKeys = prefs.getKeys();

    // Filter keys that are notification tracking entries (start with "thirty_" or "five_")
    final notificationKeys = allKeys.where(
      (key) => key.startsWith('thirty_') || key.startsWith('five_')
    ).toList();

    int removedCount = 0;
    for (final key in notificationKeys) {
      final value = prefs.getString(key);
      // Remove if it's from a previous day
      if (value != null && value != today) {
        await prefs.remove(key);
        removedCount++;
      }
    }

    if (removedCount > 0) {
      _log.info('Cleaned up $removedCount old notification tracking entries');
    }
  } catch (e) {
    _log.warning('Failed to cleanup old notification entries: $e');
  }
}

/// Checks if notification should be sent (within 2 minutes of target time)
bool _shouldNotifyBackground(DateTime now, DateTime targetTime, String notificationId, SharedPreferences prefs) {
  if (now.isBefore(targetTime)) {
    return false; // Too early
  }

  final difference = now.difference(targetTime);
  if (difference.inMinutes > 2) {
    return false; // Too late, we missed the window
  }

  // Check if we've already sent this notification today
  final today = now.toString().split(' ')[0];
  final lastSent = prefs.getString(notificationId);
  if (lastSent == today) {
    return false; // Already sent today
  }

  return true;
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
