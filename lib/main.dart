import 'package:flutter/material.dart';
import 'package:audio_session/audio_session.dart';
import "package:logging/logging.dart";
import 'package:simple_animations/animation_builder/custom_animation_builder.dart';
import 'page_manager.dart';
import 'service_locator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

// v1.5 - Robust notification tap handling

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Stream to handle notification responses when app is running
final StreamController<String?> selectNotificationStream =
    StreamController<String?>.broadcast();

Future<void> main() async {
  final log = Logger('Main');
  Logger.root.level = Level.ALL; 
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  WidgetsFlutterBinding.ensureInitialized();

  // Check if the app was launched from a notification
  final NotificationAppLaunchDetails? notificationAppLaunchDetails = await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  String? initialPayload;
  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    initialPayload = notificationAppLaunchDetails!.notificationResponse?.payload;
    log.info("App launched from notification with payload: $initialPayload");
  }

  try {
    await setupServiceLocator();
    await initNotifications();
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());
    runApp(ZakStreamer(notificationPayload: initialPayload));
  } catch (e) {
    log.severe('Streamer failed', e);
  }
}

Future<void> initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('mipmap/launcher_icon');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
        Logger('main').info("Notification tapped while app is running. Payload: ${response.payload}");
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
        'Błąd Połączenia',
        'Nie udało się połączyć ze streamem. Dotknij, aby spróbować ponownie.',
        platformChannelSpecifics,
        payload: 'retry');
  } catch (e) {
    debugPrint('Error showing notification: $e');
  }
}

class ZakStreamer extends StatefulWidget {
  final String? notificationPayload;
  const ZakStreamer({super.key, this.notificationPayload});

  @override
  State<ZakStreamer> createState() => _ZakStreamerState();
}

class _ZakStreamerState extends State<ZakStreamer> {
  @override
  void initState() {
    super.initState();
    getIt<PageManager>().init();

    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Handle notification that launched the app from a terminated state
    if (widget.notificationPayload == 'retry') {
        Logger('main').info("Handling 'retry' payload from terminated state.");
        WidgetsBinding.instance.addPostFrameCallback((_) {
            getIt<PageManager>().play();
        });
    }

    // Handle notification tapped while the app is in the foreground or background
    selectNotificationStream.stream.listen((String? payload) {
      if (payload == 'retry') {
        Logger('main').info("Handling 'retry' payload from running state.");
        getIt<PageManager>().play();
      }
    });
  }

  @override
  void dispose() {
    selectNotificationStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      title: 'Żak Streamer',
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Wciśnij Kropkę, aby włączyć alternatywę.'),
              SizedBox(height: 75),
              PlayButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class PlayButton extends StatelessWidget {
  const PlayButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<ButtonState>(
      valueListenable: pageManager.playButtonNotifier,
      builder: (_, value, __) {
        switch (value) {
          case ButtonState.loading:
            return SizedBox(
              width: 300,
              height: 300,
              child: const CircularProgressIndicator(
                strokeWidth: 15,
                strokeCap: StrokeCap.round,
                color: Colors.tealAccent,
              ),
            );
          case ButtonState.paused:
            return Opacity(
              opacity: 0.4,
              child: SizedBox(
                width: 300,
                height: 300,
                child: IconButton(
                  icon: Image.asset('assets/zak-kropka-niebieska-biale.png'),
                  onPressed: pageManager.play,
                ),
              ),
            );
          case ButtonState.playing:
            return CustomAnimationBuilder<double>(
              builder: (context, value, children) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: value,
                      height: value,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(255),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.tealAccent.withOpacity(0.5),
                            blurRadius: 25,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      height: 300,
                      child: IconButton(
                        icon: Image.asset(
                          'assets/zak-kropka-niebieska-biale.png',
                        ),
                        onPressed: pageManager.pause,
                      ),
                    ),
                  ],
                );
              },
              tween: Tween(begin: 275, end: 300),
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
              startPosition: 0.5,
              control: Control.mirror,
            );
          case ButtonState.error:
            return SizedBox(
                width: 300,
                height: 300,
                child: IconButton(
                  icon: Icon(Icons.replay_circle_filled, size: 100, color: Colors.redAccent),
                  onPressed: pageManager.play,
                ),
              );
        }
      },
    );
  }
}
