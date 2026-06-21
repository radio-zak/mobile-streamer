import 'package:flutter/material.dart';
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
                  pageController: pageController,
                  icon: Icon(Icons.play_circle_rounded),
                  label: "Streamer",
                ),
              ),
              Flexible(
                fit: FlexFit.tight,
                child: NavBarButton(
                  page: 1,
                  currentPageIndex: currentPageIndex,
                  pageController: pageController,
                  icon: Icon(Icons.list),
                  label: "Ramówka",
                ),
              ),
              Flexible(
                fit: FlexFit.tight,
                child: NavBarButton(
                  page: 2,
                  currentPageIndex: currentPageIndex,
                  pageController: pageController,
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
