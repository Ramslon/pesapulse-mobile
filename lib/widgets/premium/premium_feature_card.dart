import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';
import '../../subscription/models/premium_feature.dart';

class PremiumFeatureCard extends StatelessWidget {
  final PremiumFeature feature;
  final bool isPremium;
  final bool isLoading;
  final VoidCallback onPressed;

  /// Accent color inherited from the screen's section identity.
  final Color? accentColor;

  const PremiumFeatureCard({
    super.key,
    required this.feature,
    required this.isPremium,
    required this.isLoading,
    required this.onPressed,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);

    // Falls back to the app theme when a screen-specific color
    // is not supplied.
    final accent = accentColor ?? colorScheme.primary;

    return Card(
      elevation: 0,
      color: accent.withOpacity(.075),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        side: BorderSide(color: accent.withOpacity(.10), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 9 : 11),
              decoration: BoxDecoration(
                color: accent.withOpacity(.11),
                borderRadius: BorderRadius.circular(compact ? 11 : 14),
              ),
              child: Icon(
                isPremium ? Icons.auto_graph_rounded : Icons.lock_rounded,
                color: accent,
                size: compact ? 20 : 23,
              ),
            ),

            SizedBox(width: compact ? 12 : 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          feature.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(.10),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium_rounded,
                              size: 13,
                              color: accent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Premium',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    feature.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(.68),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 13),

                  SizedBox(
                    height: compact ? 42 : 44,
                    child: FilledButton.icon(
                      onPressed: isLoading ? null : onPressed,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: _foregroundFor(
                          accent,
                          theme.brightness,
                        ),
                        disabledBackgroundColor: accent.withOpacity(.25),
                        disabledForegroundColor: colorScheme.onSurface
                            .withOpacity(.45),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _foregroundFor(Color color, Brightness brightness) {
    // Amber needs dark foreground text/icons for good contrast.
    if (color == Colors.amber) {
      return Colors.black87;
    }

    // Use a dark foreground for the bright amber-family accent.
    if (color.computeLuminance() > .72) {
      return Colors.black87;
    }

    return Colors.white;
  }
}
