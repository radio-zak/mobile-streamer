import 'package:flutter/material.dart';

class LiveChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsGeometry.directional(
        start: 8,
        end: 8,
        top: 2,
        bottom: 2,
      ),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 49, 179, 193),
        border: Border.all(color: Colors.white.withAlpha(125)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'LIVE',
        style: Theme.of(
          context,
        ).textTheme.labelSmall!.copyWith(color: Colors.white),
      ),
    );
  }
}
