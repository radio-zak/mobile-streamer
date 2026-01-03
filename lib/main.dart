import 'dart:async';
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

  try {
    await setupServiceLocator();
    await Notifications.init();
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.music());
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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      title: 'Żak Streamer',
      theme: ThemeData.dark(),
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
              const NowPlayingWidget(),
              const Text('Wciśnij Kropkę, aby włączyć alternatywę.'),
              const PlayButton(),
              TextButton(
                child: const Text(
                  'POKAŻ RAMÓWKĘ',
                  style: TextStyle(color: Colors.tealAccent),
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
