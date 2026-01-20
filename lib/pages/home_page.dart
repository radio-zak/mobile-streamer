import 'package:flutter/material.dart';
import 'package:zakstreamer/widgets/play_button.dart';
import 'package:zakstreamer/widgets/now_playing_widget.dart';
import 'package:zakstreamer/widgets/primary_text_button.dart';
import 'package:zakstreamer/pages/schedule_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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
    );
  }
}

class HomePageLandscape extends HomePage {
  const HomePageLandscape({super.key});
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
  const HomePagePortrait({super.key});

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
