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
        // If nothing is playing or data is not yet loaded, return an empty container.
        if (nowPlaying == null) {
          return const SizedBox.shrink();
        }

        // If a show is playing, display its details.
        return Padding(
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
              const SizedBox(height: 48), // Add space between this widget and the player button
            ],
          ),
        );
      },
    );
  }
}
