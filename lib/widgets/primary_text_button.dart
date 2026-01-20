import 'package:flutter/material.dart';

class PrimaryTextButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic route;

  const PrimaryTextButton({
    super.key,
    required this.icon,
    required this.label,
    this.route,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        spacing: 12,
        children: [
          Icon(icon, size: 36),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => route));
      },
    );
  }
}
