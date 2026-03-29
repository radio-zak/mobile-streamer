import 'package:flutter/material.dart';
import 'package:zakstreamer/now_playing.dart';
import 'package:zakstreamer/schedule_service.dart';
import 'package:zakstreamer/service_locator.dart';
import 'package:zakstreamer/widgets/show_progress_bar.dart';

class NowPlayingWidget extends StatelessWidget {
  const NowPlayingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<NowPlaying>();

    return ValueListenableBuilder<NowPlayingState>(
      valueListenable: pageManager.nowPlayingNotifier,
      builder: (_, nowPlaying, _) {
        switch (nowPlaying) {
          case NowPlayingState.loading:
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
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
      builder: (_, nowPlaying, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 750),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Column(
              key: ValueKey(nowPlaying?.title),
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TERAZ GRAMY',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nowPlaying!.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (nowPlaying.hosts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      'Prowadzący: ${nowPlaying.hosts}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 4),
                ShowProgressBar(entry: nowPlaying),
              ],
            ),
          ),
        );
      },
    );
  }
}
