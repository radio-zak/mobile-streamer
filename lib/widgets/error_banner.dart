import 'package:flutter/material.dart';
import 'package:zakstreamer/page_manager.dart';
import 'package:zakstreamer/service_locator.dart';

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pageManager = getIt<PageManager>();

    return GestureDetector(
      onTap: pageManager.clearError,
      child: Padding(
        padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
        child: Material(
          borderRadius: BorderRadius.circular(12.0),
          elevation: 4.0,
          color: theme.colorScheme.error,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Icon(
                  Icons.signal_wifi_off_rounded,
                  color: theme.colorScheme.onError,
                  size: 36,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Błąd połączenia',
                          style: theme.textTheme.titleSmall!.copyWith(
                            color: theme.colorScheme.onError,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: theme.colorScheme.onError,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
