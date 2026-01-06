import 'package:flutter/material.dart';
import 'package:zakstreamer/now_playing.dart';
import 'package:zakstreamer/schedule_service.dart';
import 'package:zakstreamer/service_locator.dart';

class NowPlayingWidget extends StatelessWidget {
  const NowPlayingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<NowPlaying>();

    return ValueListenableBuilder<ScheduleEntry?>(
      valueListenable: pageManager.nowPlayingNotifier,
      builder: (_, nowPlaying, __) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 750),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: SizedBox(
            height: 130,
            child: Center(
              child: nowPlaying == null
                  // When no show is live, display an empty box with a specific key.
                  // The key is crucial for AnimatedSwitcher to detect a change.
                  ? const CircularProgressIndicator(
                      color: Colors.tealAccent,
                      key: ValueKey('empty'),
                    )
                  // When a show is live, display its details.
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      key: ValueKey(nowPlaying.title),
                      children: [
                        Text(
                          'TERAZ GRAMY',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Colors.tealAccent,
                                letterSpacing: 1.5,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          nowPlaying.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (nowPlaying.hosts.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Prowadzący: ${nowPlaying.hosts}',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
