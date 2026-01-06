import 'package:flutter/material.dart';
import 'package:zakstreamer/now_playing.dart';
import 'package:zakstreamer/schedule_service.dart';
import 'package:zakstreamer/service_locator.dart';

class NowPlayingWidget extends StatelessWidget {
  const NowPlayingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<NowPlaying>();

    return ValueListenableBuilder<NowPlayingState>(
      valueListenable: pageManager.nowPlayingNotifier,
      builder: (_, nowPlaying, __) {
        switch (nowPlaying) {
          case NowPlayingState.loading:
            return Center(
              child: const CircularProgressIndicator(color: Colors.tealAccent),
            );
          case NowPlayingState.inactive:
            return Container();
          case NowPlayingState.active:
            return NowPlayingActiveWidget();
        }
      },
    );
  }
}

class NowPlayingActiveWidget extends NowPlayingWidget {
  const NowPlayingActiveWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<NowPlaying>();

    return ValueListenableBuilder<ScheduleEntry?>(
      valueListenable: pageManager.nowPlayingContents,
      builder: (_, nowPlaying, __) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 750),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              key: ValueKey(nowPlaying?.title),
              children: [
                Text(
                  'TERAZ GRAMY',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.tealAccent,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  nowPlaying!.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (nowPlaying.hosts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Prowadzący: ${nowPlaying.hosts}',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
