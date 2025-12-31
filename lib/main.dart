import 'package:flutter/material.dart';
import 'package:audio_session/audio_session.dart';
import 'package:logging/logging.dart';
import 'package:simple_animations/animation_builder/custom_animation_builder.dart';
import 'package:zakstreamer/widgets/now_playing_widget.dart';
import 'page_manager.dart';
import 'schedule_page.dart';
import 'service_locator.dart';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final log = Logger('Main');
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  try {
    await setupServiceLocator();
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
  @override
  void initState() {
    super.initState();
    getIt<PageManager>().init();
  }

  @override
  void dispose() {
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const NowPlayingWidget(),
            const Text('Wciśnij Kropkę, aby włączyć alternatywę.'),
            const SizedBox(height: 24),
            const PlayButton(),
            const SizedBox(height: 24),
            TextButton(
              child: const Text('POKAŻ RAMÓWKĘ'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SchedulePage()),
                );
              },
            ),
          ],
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
            return const SizedBox(
              width: 300,
              height: 300,
              child: CircularProgressIndicator(
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
              animationStatusListener: (status) {
                debugPrint('status updated: $status');
              },
            );
        }
      },
    );
  }
}
