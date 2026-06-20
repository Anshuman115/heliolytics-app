import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heliolytics/design_system/tokens/helio_spacing.dart';
import 'package:heliolytics/utils/error_messages.dart';

class ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  final bool showSettings;

  const ErrorView({
    super.key,
    required this.error,
    required this.onRetry,
    this.showSettings = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final msg = friendlyError(error);
    final needsSettings = showSettings &&
        (msg.contains('Settings') || msg.contains('API key') || msg.contains('API URL'));

    return Padding(
      padding: const EdgeInsets.all(HelioSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: HelioSpacing.lg),
          Text('Could not load data', style: theme.textTheme.titleMedium),
          const SizedBox(height: HelioSpacing.sm),
          Text(msg, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
          const SizedBox(height: HelioSpacing.xl),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
          if (needsSettings) ...[
            const SizedBox(height: HelioSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => context.push('/settings/api'),
              icon: const Icon(Icons.settings),
              label: const Text('Cloud API settings'),
            ),
          ],
        ],
      ),
    );
  }
}
