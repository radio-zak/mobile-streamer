import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'main.dart';
import 'notification_service.dart';
import 'page_manager.dart';
import 'service_locator.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _logoOpacity = 0.0;
  double _logoScale = 0.8;
  double _topTextOpacity = 0.0;
  double _bottomTextOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    // This is the key change: We start the whole initialization process
    // right after the first frame is built. This ensures a smooth animation start.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeApp());
  }

  Future<void> _initializeApp() async {
    // Start the visual animations immediately
    _startAnimationSequence();

    final log = Logger('Init');

    // Handle notification that launched the app
    final notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    final didLaunchFromNotification =
        notificationAppLaunchDetails?.didNotificationLaunchApp ?? false;
    final notificationPayload =
        notificationAppLaunchDetails?.notificationResponse?.payload;

    // Start all initialization tasks in the background
    final initFuture = Future.wait([
      setupServiceLocator(),
      initNotifications(),
      AudioSession.instance.then((session) =>
          session.configure(AudioSessionConfiguration.music())),
      // A minimum duration for the splash screen to be visible
      Future.delayed(const Duration(seconds: 4)),
    ]);

    // Wait for all initializations to complete
    await initFuture;

    // Now that services are ready, handle the notification payload if it exists
    if (didLaunchFromNotification && notificationPayload == 'retry') {
      log.info("Handling 'retry' payload from terminated state.");
      getIt<PageManager>().play();
    }

    // Listen for notification taps while the app is running
    selectNotificationStream.stream.listen((String? payload) {
      if (payload == 'retry') {
        log.info("Handling 'retry' payload from running state.");
        getIt<PageManager>().play();
      }
    });
    
    // Request notification permission for Android
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Navigate to the main screen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomePage(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  void _startAnimationSequence() {
    Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _logoOpacity = 1.0;
          _logoScale = 1.0;
        });
      }
    });
    Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _topTextOpacity = 1.0;
        });
      }
    });
    Timer(const Duration(milliseconds: 1100), () {
      if (mounted) {
        setState(() {
          _bottomTextOpacity = 1.0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedOpacity(
              opacity: _topTextOpacity,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeIn,
              child: const Text(
                'Alternatywa na żywo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),
            AnimatedOpacity(
              opacity: _logoOpacity,
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeIn,
              child: AnimatedScale(
                scale: _logoScale,
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOut,
                child: Image.asset(
                  'assets/zak-kropka-niebieska-biale.png',
                  width: 200,
                  height: 200,
                ),
              ),
            ),
            const SizedBox(height: 30),
            AnimatedOpacity(
              opacity: _bottomTextOpacity,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeIn,
              child: const Text(
                'Studenckie Radio "ŻAK" Politechniki Łódzkiej',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
