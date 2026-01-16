import 'package:flutter/material.dart';
import 'package:zakstreamer/widgets/now_playing_widget.dart';
import 'package:zakstreamer/widgets/play_button.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 36, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 140, child: NowPlayingWidget()),
              Text('Wciśnij Kropkę, aby włączyć alternatywę.'),
              PlayButton(),
            ],
          ),
        ),
      ),
    );
  }
}
