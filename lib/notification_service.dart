import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';

// Centralized notifications management.

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Stream to handle notification responses when app is running
final StreamController<String?> selectNotificationStream =
    StreamController<String?>.broadcast();

Future<void> initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('mipmap/launcher_icon');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      Logger('Notifications').info("Notification tapped. Payload: ${response.payload}");
      selectNotificationStream.add(response.payload);
    },
  );
}

Future<void> showDisconnectionNotification() async {
  debugPrint('showDisconnectionNotification() called.');
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'disconnection_channel',
    'Disconnection Notifications',
    channelDescription: 'Channel for disconnection notifications',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
  );
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
  try {
    await flutterLocalNotificationsPlugin.show(
        0,
        'Błąd połączenia',
        'Nie udało się połączyć ze streamem. Dotknij, aby spróbować ponownie.',
        platformChannelSpecifics,
        payload: 'retry');
  } catch (e) {
    debugPrint('Error showing notification: $e');
  }
}
