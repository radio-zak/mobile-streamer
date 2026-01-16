import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _bottomNavIndex = 0;

  // TODO: Replace with actual pages
  final List<Widget> _pages = [
    const Center(child: Text('Strona Główna')),
    const Center(child: Text('Ramówka')),
    const Center(child: Text('Statystyki')),
    const Center(child: Text('Więcej')),
  ];

  final iconList = <IconData>[
    Icons.home,
    Icons.calendar_today,
    Icons.bar_chart,
    Icons.more_horiz,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_bottomNavIndex],
      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: iconList,
        activeIndex: _bottomNavIndex,
        gapLocation: GapLocation.none,
        notchSmoothness: NotchSmoothness.verySmoothEdge,
        leftCornerRadius: 32,
        rightCornerRadius: 32,
        onTap: (index) => setState(() => _bottomNavIndex = index),
        //TODO: Add other properties to style the bar
      ),
    );
  }
}
