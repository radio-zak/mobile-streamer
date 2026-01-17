import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:zakstreamer/contact_page.dart';
import 'package:zakstreamer/home_page.dart';
import 'package:zakstreamer/schedule_page.dart';
import 'package:zakstreamer/statistics_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _pageIndex = 2; // Start on Home
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _pageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Widget> _pages = [
    const SchedulePage(),
    const StatisticsPage(),
    const HomePage(),
    const ContactPage(),
    const Center(child: Text('Tutaj pojawią się nowe podstrony, standby ')),
  ];

  final List<IconData> _icons = [
    Icons.calendar_today_outlined,
    Icons.bar_chart_outlined,
    Icons.headphones_rounded,
    Icons.phone_outlined,
    Icons.more_horiz_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: _pages,
        onPageChanged: (index) {
          setState(() => _pageIndex = index);
        },
      ),
      bottomNavigationBar: AnimatedBottomNavigationBar.builder(
        itemCount: _icons.length,
        tabBuilder: (int index, bool isActive) {
          final color = isActive ? Colors.tealAccent : Colors.grey;
          // Middle button style
          if (index == 2) {
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? Colors.tealAccent : Colors.grey[850],
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(
                _icons[index],
                color: isActive ? Colors.black : Colors.white,
                size: 28,
              ),
            );
          }
          // Regular button style
          return Icon(
            _icons[index],
            size: 24,
            color: color,
          );
        },
        activeIndex: _pageIndex,
        gapLocation: GapLocation.none,
        notchSmoothness: NotchSmoothness.verySmoothEdge,
        leftCornerRadius: 32,
        rightCornerRadius: 32,
        onTap: (index) => _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        ),
        backgroundColor: Colors.black,
      ),
    );
  }
}
