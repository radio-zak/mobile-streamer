import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audio_session/audio_session.dart';
import 'package:logging/logging.dart';
import 'package:zakstreamer/main_screen.dart';
import 'package:zakstreamer/statistics_service.dart';
import 'page_manager.dart';
import 'service_locator.dart';
import 'package:flutter/services.dart';
import 'notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final log = Logger('Main');
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  //Setup RootCA certificate for purposes of NowPlaying
  try {
    log.info('Loading root certificate');
    ByteData rootCACertificate = await rootBundle.load(
      'assets/HARICA-TLS-Root-2021-RSA.pem',
    );
    SecurityContext context = SecurityContext.defaultContext;
    context.setTrustedCertificatesBytes(rootCACertificate.buffer.asUint8List());
  } catch (e) {
    log.severe('Failed loading Root CA certificate', e);
  }
  try {
    log.info('Setting up service locator');
    await setupServiceLocator();
  } catch (e) {
    log.severe('Service locator failed', e);
  }
  try {
    log.info('Starting notification service');
    await Notifications.init();
  } catch (e) {
    log.severe('Notifications service failed', e);
  }
  try {
    log.info('Initializing audio session');
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());
  } catch (e) {
    log.severe('Failed configuring audio session', e);
  }
  try {
    log.info('Initializing application...');
    runApp(const ZakStreamer());
  } catch (e) {
    log.severe('Streamer failed', e);
  }
}

class ZakStreamer extends StatefulWidget {
  const ZakStreamer({super.key});

  @override
  State<ZakStreamer> createState() => _ZakStreamerState();
}

class _ZakStreamerState extends State<ZakStreamer> {
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    getIt<PageManager>().init();
    getIt<StatisticsService>().init();
    Notifications.requestPermission();

    _notificationSubscription = Notifications.onNotificationTapped.stream
        .listen((payload) {
          if (payload == 'reconnect') {
            getIt<PageManager>().play();
          }
        });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    getIt<PageManager>().dispose();
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
      home: const MainScreen(),
    );
  }
}
