import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'streamer.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import "package:logging/logging.dart";

Future<void> main() async {
  final log = Logger('Main');
  Logger.root.level = Level.ALL; // defaults to Level.INFO
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
    androidShowNotificationBadge: true,
    notificationColor: Colors.teal,
    androidNotificationIcon: 'mipmap/launcher_icon',
  );
  final session = await AudioSession.instance;
  await session.configure(AudioSessionConfiguration.music());
  try {
    runApp(ZakStreamer());
    log.fine('Started background audio service');
  } catch (e) {
    log.severe('Streamer failed', e);
  }
}

class ZakStreamer extends StatelessWidget {
  ZakStreamer({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ŻAK Streamer',
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  // final String title;
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final Streamer _streamer;
  final _image = Image.asset('assets/zak-kropka-niebieska-biale.png');
  late final Animation<double> _animation;
  late final AnimationController animationController = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: this,
  );

  @override
  void initState() {
    super.initState();
    _streamer = Streamer();
    _animation = new Tween<double>(
      begin: 300,
      end: 250,
    ).animate(animationController);
    animationController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Theme.of(context).primaryColor),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Container(
              child: ValueListenableBuilder<ButtonState>(
                valueListenable: _streamer.buttonNotifier,
                builder: (_, value, __) {
                  switch (value) {
                    case ButtonState.loading:
                      return Container(
                        margin: const EdgeInsets.all(8.0),
                        width: 250.0,
                        height: 250.0,
                        child: const CircularProgressIndicator(),
                      );
                    case ButtonState.paused:
                      return Opacity(
                        opacity: 0.5,
                        child: Container(
                          width: 300,
                          height: 300,
                          child: Container(
                            width: 200,
                            height: 200,
                            child: IconButton(
                              icon: _image,
                              onPressed: _streamer.play,
                              color: Colors.tealAccent,
                            ),
                          ),
                        ),
                      );
                    case ButtonState.playing:
                      return Opacity(
                        opacity: 1,
                        child: Container(
                          width: 300,
                          height: 300,
                          child: AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return Stack(
                                alignment: Alignment.center,
                                children: <Widget>[
                                  Container(
                                    width: _animation.value,
                                    height: _animation.value,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(255),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.tealAccent.withOpacity(
                                            0.5,
                                          ),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 300,
                                    height: 300,
                                    child: IconButton(
                                      icon: _image,
                                      onPressed: _streamer.pause,
                                      color: Colors.tealAccent,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ).animate().fade(
                        begin: 0.5,
                        duration: Duration(milliseconds: 500),
                      );
                  }
                },
              ),
            ),
            Text(
              'Wciśnij Kropkę, aby włączyć alternatywę.',
            ).animate().fadeIn(delay: Duration(seconds: 2)),
          ],
        ),
      ),
    );
  }
}
