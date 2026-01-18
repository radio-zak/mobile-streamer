import 'package:flutter/material.dart';
import 'package:zakstreamer/page_manager.dart';
import 'package:zakstreamer/service_locator.dart';
import 'package:simple_animations/animation_builder/custom_animation_builder.dart';

class PlayButton extends StatelessWidget {
  const PlayButton({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<ButtonState>(
      valueListenable: pageManager.playButtonNotifier,
      builder: (_, value, __) {
        switch (value) {
          case ButtonState.loading:
            return SizedBox(
              width: 300,
              height: 300,
              child: CircularProgressIndicator(
                strokeWidth: 15,
                strokeCap: StrokeCap.round,
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          case ButtonState.paused:
            return Opacity(
              opacity: 0.5,
              child: SizedBox(
                width: 300,
                height: 300,
                child: IconButton(
                  icon: Image.asset('assets/zak-kropka-niebieska-biale.png'),
                  onPressed: pageManager.play,
                ),
              ),
            );
          case ButtonState.playing:
            return CustomAnimationBuilder<double>(
              builder: (context, value, children) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: value,
                      height: value,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(255),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withAlpha(164),
                            blurRadius: 64,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      height: 300,
                      child: IconButton(
                        icon: Image.asset(
                          'assets/zak-kropka-niebieska-biale.png',
                        ),
                        onPressed: pageManager.pause,
                      ),
                    ),
                  ],
                );
              },
              tween: Tween(begin: 275, end: 300),
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
              startPosition: 0.5,
              control: Control.mirror,
              animationStatusListener: (status) {
                debugPrint('status updated: $status');
              },
            );
        }
      },
    );
  }
}
