import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zakstreamer/page_manager.dart';
import 'package:zakstreamer/service_locator.dart';
import 'package:simple_animations/animation_builder/custom_animation_builder.dart';

class PlayButton extends StatelessWidget {
  const PlayButton({super.key});
  @override
  Widget build(BuildContext context) {
    final pageManager = getIt<PageManager>();
    return ValueListenableBuilder<ButtonState>(
      valueListenable: pageManager.playButtonNotifier,
      builder: (_, value, _) {
        switch (value) {
          case ButtonState.loading:
            return Padding(
              padding: EdgeInsetsGeometry.directional(
                start: 32,
                end: 32,
                top: 16,
                bottom: 16,
              ),
              child: FittedBox(
                fit: BoxFit.fitWidth,
                child: SizedBox(
                  width: 450,
                  height: 450,
                  child: CircularProgressIndicator(
                    strokeWidth: 15,
                    strokeCap: StrokeCap.round,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            );
          case ButtonState.paused:
            return Opacity(
              opacity: 0.5,
              child: Padding(
                padding: EdgeInsetsGeometry.directional(
                  start: 32,
                  end: 32,
                  top: 16,
                  bottom: 16,
                ),
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  child: IconButton(
                    icon: Image.asset('assets/zak-kropka-niebieska-biale.png'),
                    onPressed: pageManager.play,
                  ),
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
                    Padding(
                      padding: EdgeInsetsGeometry.directional(
                        start: 32,
                        end: 32,
                        top: 16,
                        bottom: 16,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: IconButton(
                          icon: Image.asset(
                            'assets/zak-kropka-niebieska-biale.png',
                          ),
                          onPressed: pageManager.pause,
                        ),
                      ),
                    ),
                  ],
                );
              },
              tween: Tween(
                begin:
                    MediaQuery.of(context).orientation == Orientation.portrait
                    ? MediaQuery.of(context).size.width * 0.7
                    : MediaQuery.of(context).size.height * 0.5,
                end: MediaQuery.of(context).orientation == Orientation.portrait
                    ? MediaQuery.of(context).size.width * 0.7
                    : MediaQuery.of(context).size.height * 0.5,
              ),
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
              startPosition: 0.5,
              control: Control.mirror,
              animationStatusListener: kDebugMode
                  ? (status) {
                      debugPrint('status updated: $status');
                    }
                  : null,
            );
        }
      },
    );
  }
}
