import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';
import '../../subscription/models/premium_feature.dart';

class PremiumFeatureCard extends StatelessWidget {
  final PremiumFeature feature;
  final bool isPremium;
  final bool isLoading;
  final VoidCallback onPressed;

  const PremiumFeatureCard({
    super.key,
    required this.feature,
    required this.isPremium,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);

    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer.withOpacity(.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 9 : 11),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(.10),
                borderRadius: BorderRadius.circular(compact ? 11 : 14),
              ),
              child: Icon(
                isPremium ? Icons.auto_graph_rounded : Icons.lock_rounded,
                color: colorScheme.primary,
                size: compact ? 20 : 23,
              ),
            ),
            SizedBox(width: compact ? 12 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feature.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(.7),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: isLoading ? null : onPressed,
                    icon: Icon(
                      isLoading
                          ? Icons.sync_rounded
                          : isPremium
                          ? Icons.open_in_new_rounded
                          : Icons.workspace_premium_rounded,
                      size: 18,
                    ),
                    label: Text(
                      isLoading
                          ? 'Checking Access...'
                          : isPremium
                          ? 'Open'
                          : 'Unlock Premium',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
