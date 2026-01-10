import 'package:flutter/material.dart';
import 'package:zakstreamer/widgets/play_button.dart';
import 'package:zakstreamer/widgets/now_playing_widget.dart';
import 'package:zakstreamer/widgets/primary_text_button.dart';
import 'package:zakstreamer/pages/schedule_page.dart';
import 'package:zakstreamer/widgets/error_banner.dart';
import 'package:zakstreamer/page_manager.dart';
import 'package:zakstreamer/service_locator.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});
  final pageManager = getIt<PageManager>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 36, horizontal: 12),
              child: OrientationBuilder(
                builder: (context, orientation) {
                  return orientation == Orientation.portrait
                      ? HomePagePortrait()
                      : HomePageLandscape();
                },
              ),
            ),
          ),
          ValueListenableBuilder<String>(
            valueListenable: pageManager.errorNotifier,
            builder: (context, message, child) {
              if (message.isEmpty) {
                return const SizedBox.shrink();
              }
              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: ErrorBanner(message: message),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class HomePageLandscape extends HomePage {
  HomePageLandscape({super.key});
  @override
  Widget build(context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const SizedBox(height: 140, child: NowPlayingWidget()),
            Text(
              'Wciśnij Kropkę, aby włączyć alternatywę.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const PrimaryTextButton(
              icon: Icons.list,
              label: 'ZOBACZ RAMÓWKĘ',
              route: SchedulePage(),
            ),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [const PlayButton()],
        ),
      ],
    );
  }
}

class HomePagePortrait extends HomePage {
  HomePagePortrait({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const SizedBox(height: 140, child: NowPlayingWidget()),
        Text(
          'Wciśnij Kropkę, aby włączyć alternatywę.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const PlayButton(),
        const PrimaryTextButton(
          icon: Icons.list,
          label: 'ZOBACZ RAMÓWKĘ',
          route: SchedulePage(),
        ),
      ],
    );
  }
}
