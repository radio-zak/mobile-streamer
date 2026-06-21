import 'package:flutter/material.dart';
import 'package:zakstreamer/pages/home_page.dart';
import 'package:zakstreamer/pages/schedule_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => MainLayoutState();
}

class MainLayoutState extends State<MainLayout> {
  int currentPageIndex = 0;
  final PageController pageController = PageController();

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: pageController,
        onPageChanged: (index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        children: [HomePage(), SchedulePage(), Container()],
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutSine,
          );
        },
        selectedIndex: currentPageIndex,
        destinations: [
          NavigationDestination(icon: Icon(Icons.home), label: "Streamer"),
          NavigationDestination(icon: Icon(Icons.list), label: "Ramówka"),
          NavigationDestination(icon: Icon(Icons.info), label: "O nas"),
        ],
      ),
    );
  }
}
