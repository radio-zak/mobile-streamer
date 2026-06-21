import 'package:flutter/material.dart';

class NavBarButton extends StatelessWidget {
  final Icon icon;
  final String label;
  final TextStyle? style;
  final int currentPageIndex;
  final int page;
  final PageController pageController;

  NavBarButton({
    super.key,
    required this.icon,
    required this.label,
    required this.currentPageIndex,
    required this.page,
    required this.pageController,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final color = currentPageIndex == page
        ? Theme.of(context).navigationBarTheme.indicatorColor
        : Theme.of(context).navigationBarTheme.backgroundColor;
    final style = currentPageIndex == page
        ? Theme.of(context).textTheme.titleSmall
        : Theme.of(context).textTheme.bodyMedium;

    return Material(
      color: color,
      child: InkWell(
        onTap: () {
          pageController.animateToPage(
            page,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutSine,
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 10,
          children: [
            icon,
            Text(label, style: style),
          ],
        ),
      ),
    );
  }
}
