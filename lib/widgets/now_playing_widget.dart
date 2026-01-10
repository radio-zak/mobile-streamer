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
            return const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            );
          case NowPlayingState.inactive:
            return Container();
          case NowPlayingState.active:
            return const NowPlayingActiveWidget();
        }
      },
    );
  }
}

class NowPlayingActiveWidget extends StatelessWidget {
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
                Row(
                  children: [
                    const SizedBox(width: 48.0), // Spacer to balance the button on the right
                    Expanded(
                      child: Text(
                        'TERAZ GRAMY',
                        textAlign: TextAlign.center, // Center the text
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.tealAccent,
                              letterSpacing: 1.5,
                            ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.tealAccent),
                      onSelected: (value) {},
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[],
                    ),
                  ],
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
