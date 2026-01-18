import 'dart:async';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:audio_session/audio_session.dart';
import 'package:logging/logging.dart';
import 'package:zakstreamer/widgets/play_button.dart';
import 'package:zakstreamer/widgets/now_playing_widget.dart';
import 'page_manager.dart';
import 'schedule_page.dart';
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

  final surfaceColor = Color.fromARGB(255, 34, 34, 34);
  final primaryColor = Color.fromARGB(255, 0, 230, 255);
  final primaryDimmedColor = Color.fromARGB(255, 45, 71, 74);
  final textPrimaryColor = Colors.white;
  final textGreyedColor = Color(0xFFBBBBBB);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      title: 'Żak Streamer',
      theme: ThemeData(
        appBarTheme: AppBarThemeData(
          actionsIconTheme: IconThemeData(color: textPrimaryColor),
          iconTheme: IconThemeData(color: textPrimaryColor),
          backgroundColor: surfaceColor,
          foregroundColor: surfaceColor,
        ),
        tabBarTheme: TabBarThemeData(
          indicatorColor: primaryColor,
          labelStyle: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.normal,
          ),
          labelColor: primaryColor,
          unselectedLabelStyle: TextStyle(
            color: textGreyedColor,
            fontWeight: FontWeight.normal,
          ),
        ),
        colorScheme: ColorScheme(
          surface: surfaceColor,
          onSurface: textPrimaryColor,
          primary: primaryColor,
          onPrimary: textPrimaryColor,
          secondary: textGreyedColor,
          onSecondary: textPrimaryColor,
          primaryFixedDim: primaryDimmedColor,
          tertiary: textGreyedColor,
          brightness: Brightness.dark,
          onError: Colors.red,
          error: Colors.red,
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.sora(),
          displayMedium: GoogleFonts.sora(),
          titleLarge: GoogleFonts.sora(fontWeight: FontWeight.bold),
          titleMedium: GoogleFonts.sora(fontWeight: FontWeight.bold),
          titleSmall: GoogleFonts.sora(fontWeight: FontWeight.bold),
          displaySmall: GoogleFonts.sora(),
          labelLarge: GoogleFonts.sora(
            fontWeight: FontWeight.bold,
            color: textGreyedColor,
          ),
          labelMedium: GoogleFonts.sora(
            fontWeight: FontWeight.bold,
            color: textGreyedColor,
          ),
          labelSmall: GoogleFonts.sora(
            fontWeight: FontWeight.bold,
            color: textGreyedColor,
          ),
          headlineLarge: GoogleFonts.sora(),
          headlineMedium: GoogleFonts.sora(),
          headlineSmall: GoogleFonts.sora(fontSize: 16),
          bodyLarge: GoogleFonts.sora(),
          bodyMedium: GoogleFonts.sora(),
          bodySmall: GoogleFonts.sora(),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 36, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 140, child: NowPlayingWidget()),
              Text(
                'Wciśnij Kropkę, aby włączyć alternatywę.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const PlayButton(),
              TextButton(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  spacing: 12,
                  children: [
                    Icon(Icons.list, size: 36),
                    Text(
                      'ZOBACZ RAMÓWKĘ',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SchedulePage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
