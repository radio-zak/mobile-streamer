import 'package:flutter/material.dart';
import 'package:zakstreamer/widgets/live_chip.dart';
import 'package:zakstreamer/widgets/favorite_button.dart';

class ScheduleListEntry extends StatelessWidget {
  final bool isLiveNow;
  final String entryTime;
  final String entryTitle;
  final String entryHosts;

  const ScheduleListEntry({
    super.key,
    required this.isLiveNow,
    required this.entryTitle,
    required this.entryTime,
    required this.entryHosts,
  });

  @override
  Widget build(context) {
    return Container(
      color: isLiveNow
          ? Theme.of(context).colorScheme.primaryFixedDim
          : Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      entryTime,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLiveNow) const LiveChip(),
                        FavoriteButton(showTitle: entryTitle),
                      ],
                    ),
                  ],
                ),
                Text(
                  entryTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (entryHosts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Prowadzący: $entryHosts',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
