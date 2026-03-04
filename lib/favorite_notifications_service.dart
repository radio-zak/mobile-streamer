import 'dart:async';
import 'package:logging/logging.dart';
import 'notifications.dart';
import 'schedule_service.dart';
import 'favorites_service.dart';
import 'background_service.dart';

class FavoriteNotificationsService {
  final _logger = Logger('FavoriteNotificationsService');
  final FavoritesService favoritesService;
  final ScheduleService scheduleService;

  Timer? _checkTimer;
  final List<String> _sentNotifications = [];

  /// Cache for the schedule to avoid too many network requests
  Map<String, List<dynamic>>? _scheduleCache;
  DateTime? _scheduleCacheTime;
  final Duration _scheduleCacheDuration = const Duration(minutes: 5);

  FavoriteNotificationsService({
    required this.favoritesService,
    required this.scheduleService,
  });

  /// Initializes the service and starts checking for upcoming favorites
  Future<void> init() async {
    _logger.info('Initializing FavoriteNotificationsService');
    _startChecking();
  }

  /// Disposes the service and cancels the timer
  void dispose() {
    _checkTimer?.cancel();
    _logger.info('FavoriteNotificationsService disposed');
  }

  /// Starts a periodic check for upcoming favorite shows
  void _startChecking() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      await _checkForUpcomingFavorites();
    });
    // Do initial check immediately (non-blocking)
    _checkForUpcomingFavorites().catchError((e) {
      _logger.warning('Initial favorite check failed: $e');
    });
  }

  /// Checks for upcoming favorite shows and sends notifications
  Future<void> _checkForUpcomingFavorites() async {
    try {
      final favorites = favoritesService.getFavorites();
      if (favorites.isEmpty) {
        return;
      }

      // Fetch schedule from cache or network
      Map<String, List<dynamic>>? schedule;
      if (_isScheduleCacheValid()) {
        schedule = _scheduleCache;
      } else {
        schedule = await _fetchScheduleWithRetry();
      }

      if (schedule == null) {
        _logger.warning('Could not fetch schedule, skipping favorite check');
        return;
      }

      final now = DateTime.now();
      final today = (DateTime.now().weekday - 1).clamp(0, 6);

      // Safe access to today's key
      if (today >= schedule.keys.length) {
        _logger.warning('Schedule has only ${schedule.keys.length} days, today index is $today');
        return;
      }

      final todayKey = schedule.keys.elementAt(today);
      final entriesToday = schedule[todayKey] ?? [];

      for (final entry in entriesToday) {
        if (favorites.contains(entry.title)) {
          final startTime = _parseStartTime(entry.time);
          if (startTime != null) {
            // Check for 30 minutes before
            final thirtyMinBefore = startTime.subtract(
              const Duration(minutes: 30),
            );
            if (_shouldNotify(now, thirtyMinBefore, 'thirty')) {
              _sendNotification(
                title: 'Zbliża się Twoja ulubiona audycja!',
                body: '${entry.title} za 30 minut (${entry.time})',
                notificationId: 'thirty_${entry.title}',
              );
            }

            // Check for 5 minutes before
            final fiveMinBefore = startTime.subtract(
              const Duration(minutes: 5),
            );
            if (_shouldNotify(now, fiveMinBefore, 'five')) {
              _sendNotification(
                title: 'Za 5 minut: ${entry.title}',
                body: 'Twoja ulubiona audycja zaczyna się za 5 minut!',
                notificationId: 'five_${entry.title}',
              );
            }
          }
        }
      }
    } catch (e, stackTrace) {
      _logger.severe('Error checking for upcoming favorites: $e', stackTrace);
    }
  }

  /// Parses the start time from the schedule entry time string (e.g., "10:00 - 12:00")
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
      _logger.warning('Failed to parse time: $timeString, error: $e');
      return null;
    }
  }

  /// Checks if a notification should be sent
  /// Returns true if we're within 2 minutes of the target time and haven't sent it yet
  bool _shouldNotify(
    DateTime now,
    DateTime targetTime,
    String notificationType,
  ) {
    if (now.isBefore(targetTime)) {
      return false; // Too early
    }

    final difference = now.difference(targetTime);
    if (difference.inMinutes > 2) {
      return false; // Too late, we missed the window
    }

    return true;
  }

  /// Sends a notification
  Future<void> _sendNotification({
    required String title,
    required String body,
    required String notificationId,
  }) async {
    try {
      // Check if we've already sent this notification today
      final today = DateTime.now().toString().split(' ')[0];
      final fullId = '$today:$notificationId';

      if (_sentNotifications.contains(fullId)) {
        return; // Already sent
      }

      await Notifications.showNotification(
        title: title,
        body: body,
        payload: 'favorite_show',
      );

      _sentNotifications.add(fullId);
      _logger.info('Sent notification: $title - $body');

      // Clean old entries from today that are now in the past
      _cleanOldNotifications();
    } catch (e) {
      _logger.severe('Failed to send notification: $e');
    }
  }

  /// Cleans up old notification IDs from the list
  void _cleanOldNotifications() {
    final today = DateTime.now().toString().split(' ')[0];
    _sentNotifications.removeWhere((id) => !id.startsWith(today));
  }

  /// Refreshes the favorites and restarts checking
  Future<void> refreshFavorites() async {
    _sentNotifications.clear(); // Clear sent notifications to allow resending if needed
    await resetNotificationTracking(); // Reset background service tracking
    await _checkForUpcomingFavorites();
  }

  /// Checks if the schedule cache is still valid
  bool _isScheduleCacheValid() {
    if (_scheduleCacheTime == null) return false;
    return DateTime.now().isBefore(_scheduleCacheTime!.add(_scheduleCacheDuration));
  }

  /// Fetches the schedule with retry logic and caches the result
  Future<Map<String, List<dynamic>>?> _fetchScheduleWithRetry() async {
    // Fetch schedule with retry logic
    int retries = 3;
    int delayMs = 500;

    while (retries > 0) {
      try {
        final schedule = await scheduleService.fetchSchedule().timeout(
          const Duration(seconds: 30),
        );

        // Cache the schedule and update the cache time
        _scheduleCache = schedule;
        _scheduleCacheTime = DateTime.now();

        return schedule;
      } catch (e) {
        retries--;
        _logger.warning('Schedule fetch failed (retries left: $retries): $e');

        if (retries > 0) {
          // Wait before retrying with exponential backoff
          await Future.delayed(Duration(milliseconds: delayMs));
          delayMs *= 2;
        } else {
          // Last resort: try fetchScheduleBackground() if all retries failed
          try {
            _logger.info('Trying background fetch method as fallback...');
            final schedule = await scheduleService.fetchScheduleBackground().timeout(
              const Duration(seconds: 30),
            );

            // Cache the schedule and update the cache time
            _scheduleCache = schedule;
            _scheduleCacheTime = DateTime.now();

            return schedule;
          } catch (e2) {
            _logger.severe('Fallback background fetch also failed: $e2');
          }
        }
      }
    }

    return null;
  }
}
