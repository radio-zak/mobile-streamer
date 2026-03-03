import 'dart:async';
import 'package:logging/logging.dart';
import 'notifications.dart';
import 'schedule_service.dart';
import 'favorites_service.dart';

class FavoriteNotificationsService {
  final _logger = Logger('FavoriteNotificationsService');
  final FavoritesService favoritesService;
  final ScheduleService scheduleService;

  Timer? _checkTimer;
  final List<String> _sentNotifications = [];

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

      final schedule = await scheduleService.fetchSchedule();
      final now = DateTime.now();
      final today = (DateTime.now().weekday - 1).clamp(0, 6);
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
    } catch (e) {
      _logger.severe('Error checking for upcoming favorites: $e');
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
    _sentNotifications
        .clear(); // Clear sent notifications to allow resending if needed
    await _checkForUpcomingFavorites();
  }
}
