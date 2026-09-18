import 'package:flutter/material.dart';

import '../../subscription/models/premium_feature.dart';
import '../../utils/responsive_helper.dart';

class PremiumFeatureDialog extends StatelessWidget {
  final PremiumFeature feature;
  final VoidCallback? onUpgrade;

  const PremiumFeatureDialog({
    super.key,
    required this.feature,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 18 : 24),
      ),
      titlePadding: EdgeInsets.fromLTRB(
        compact ? 20 : 24,
        compact ? 20 : 24,
        compact ? 20 : 24,
        8,
      ),
      contentPadding: EdgeInsets.fromLTRB(
        compact ? 20 : 24,
        8,
        compact ? 20 : 24,
        20,
      ),
      actionsPadding: EdgeInsets.fromLTRB(
        compact ? 20 : 24,
        0,
        compact ? 20 : 24,
        compact ? 16 : 20,
      ),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(compact ? 9 : 11),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(.10),
              borderRadius: BorderRadius.circular(compact ? 11 : 14),
            ),
            child: Icon(
              Icons.lock_rounded,
              color: colorScheme.primary,
              size: compact ? 20 : 23,
            ),
          ),
          SizedBox(width: compact ? 10 : 12),
          Expanded(
            child: Text(
              feature.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        '${feature.description}\n\n'
        'This feature is available with PesaPulse Premium.',
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.45,
          color: colorScheme.onSurface.withOpacity(.75),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Not Now'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onUpgrade?.call();
          },
          icon: const Icon(Icons.workspace_premium_rounded),
          label: const Text('View Premium'),
        ),
      ],
    );
  }
}
