import 'package:flutter/material.dart';
import 'package:zakstreamer/pages/about_us.dart';
import 'package:zakstreamer/pages/home_page.dart';
import 'package:zakstreamer/pages/schedule_page.dart';
import 'package:zakstreamer/widgets/nav_bar_button.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => MainLayoutState();
}

class MainLayoutState extends State<MainLayout> {
  int currentPageIndex = 0;
  final PageController pageController = PageController();
  bool isNavigatingViaNavBar = false;

  void navigateToPage(int index) async {
    if (currentPageIndex == index) return;

    setState(() {
      currentPageIndex = index;
      isNavigatingViaNavBar = true;
    });
    await pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOutSine,
    );
    isNavigatingViaNavBar = false;
  }

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
          if (!isNavigatingViaNavBar) {
            setState(() {
              currentPageIndex = index;
            });
          }
        },
        children: [HomePage(), SchedulePage(), AboutUsPage()],
      ),
      bottomNavigationBar: BottomAppBar(
        padding: EdgeInsetsDirectional.all(0),
        color: Theme.of(context).navigationBarTheme.backgroundColor,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey, width: 1)),
          ),
          child: Flex(
            direction: Axis.horizontal,
            children: [
              Flexible(
                fit: FlexFit.tight,
                child: NavBarButton(
                  page: 0,
                  currentPageIndex: currentPageIndex,
                  onTap: () {
                    navigateToPage(0);
                  },
                  icon: Icon(Icons.play_circle_rounded),
                  label: "Streamer",
                ),
              ),
              Flexible(
                fit: FlexFit.tight,
                child: NavBarButton(
                  page: 1,
                  currentPageIndex: currentPageIndex,
                  onTap: () {
                    navigateToPage(1);
                  },
                  icon: Icon(Icons.list),
                  label: "Ramówka",
                ),
              ),
              Flexible(
                fit: FlexFit.tight,
                child: NavBarButton(
                  page: 2,
                  currentPageIndex: currentPageIndex,
                  onTap: () {
                    navigateToPage(2);
                  },
                  icon: Icon(Icons.info),
                  label: "O nas",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
