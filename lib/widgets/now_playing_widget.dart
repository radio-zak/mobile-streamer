import 'package:flutter/material.dart';
import 'package:zakstreamer/page_manager.dart';
import 'package:zakstreamer/schedule_service.dart';
import 'package:zakstreamer/service_locator.dart';

class NowPlayingWidget extends StatelessWidget {
  const NowPlayingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();

    return ValueListenableBuilder<ScheduleEntry?>(
      valueListenable: pageManager.nowPlayingNotifier,
      builder: (_, nowPlaying, __) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 750),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: nowPlaying == null
              // When no show is live, display an empty box with a specific key.
              // The key is crucial for AnimatedSwitcher to detect a change.
              ? const SizedBox(key: ValueKey('empty'))
              // When a show is live, display its details.
              : Padding(
                  // The key changes when the show title changes, triggering the animation.
                  key: ValueKey(nowPlaying.title),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'TERAZ GRAMY',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white70,
                              letterSpacing: 1.5,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        nowPlaying.title,
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
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                          ),
                        ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
