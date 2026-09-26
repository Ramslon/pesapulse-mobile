import 'package:flutter/material.dart';

import '../fade_slide_animation.dart';
import '/utils/responsive_helper.dart';

class SmartInsightsCard extends StatelessWidget {
  final List<String> insights;

  const SmartInsightsCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final mobile = ResponsiveHelper.isMobile(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final contentMaxWidth = ResponsiveHelper.contentMaxWidth(context);

    final cardPadding = ResponsiveHelper.cardPadding(context);

    final spacing = ResponsiveHelper.spacing(context);

    final validInsights = insights
        .map((insight) => insight.trim())
        .where((insight) => insight.isNotEmpty)
        .toList();

    if (validInsights.isEmpty) {
      return _buildEmptyState(
        context,
        theme: theme,
        colorScheme: colorScheme,
        contentMaxWidth: contentMaxWidth,
        cardPadding: cardPadding,
        mobile: mobile,
      );
    }

    return FadeSlideAnimation(
      delay: 350,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(desktop ? 22 : 18),
              border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    theme.brightness == Brightness.dark ? 0.10 : 0.045,
                  ),
                  blurRadius: desktop ? 20 : 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(
                    context,
                    theme: theme,
                    colorScheme: colorScheme,
                    mobile: mobile,
                    tablet: tablet,
                    desktop: desktop,
                  ),

                  SizedBox(
                    height: desktop
                        ? 18
                        : tablet
                        ? 16
                        : 14,
                  ),

                  _buildInsightList(
                    context,
                    validInsights: validInsights,
                    theme: theme,
                    colorScheme: colorScheme,
                    mobile: mobile,
                    tablet: tablet,
                    desktop: desktop,
                    spacing: spacing,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool mobile,
    required bool tablet,
    required bool desktop,
  }) {
    final iconSize = desktop
        ? 46.0
        : mobile
        ? 40.0
        : 44.0;

    final icon = desktop
        ? 23.0
        : mobile
        ? 20.0
        : 22.0;

    final titleSize = desktop
        ? 19.0
        : mobile
        ? 16.0
        : 18.0;

    final subtitleSize = desktop
        ? 12.5
        : mobile
        ? 11.0
        : 12.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withOpacity(0.16),
                colorScheme.primary.withOpacity(0.07),
              ],
            ),
            borderRadius: BorderRadius.circular(mobile ? 13 : 15),
            border: Border.all(color: colorScheme.primary.withOpacity(0.10)),
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            color: colorScheme.primary,
            size: icon,
          ),
        ),

        SizedBox(width: mobile ? 10 : 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Smart Insights',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                'Personalized signals from your finances',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: subtitleSize,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        _buildInsightCountBadge(
          context,
          count: insights
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .length,
          colorScheme: colorScheme,
          mobile: mobile,
        ),
      ],
    );
  }

  Widget _buildInsightCountBadge(
    BuildContext context, {
    required int count,
    required ColorScheme colorScheme,
    required bool mobile,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 8 : 10,
        vertical: mobile ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insights_rounded,
            size: mobile ? 13 : 14,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 5),
          Text(
            '$count',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: mobile ? 10 : 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightList(
    BuildContext context, {
    required List<String> validInsights,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool mobile,
    required bool tablet,
    required bool desktop,
    required double spacing,
  }) {
    return Column(
      children: [
        for (int index = 0; index < validInsights.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == validInsights.length - 1
                  ? 0
                  : desktop
                  ? 10
                  : 8,
            ),
            child: _buildInsightTile(
              context,
              insight: validInsights[index],
              index: index,
              theme: theme,
              colorScheme: colorScheme,
              mobile: mobile,
              tablet: tablet,
              desktop: desktop,
              spacing: spacing,
            ),
          ),
      ],
    );
  }

  Widget _buildInsightTile(
    BuildContext context, {
    required String insight,
    required int index,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool mobile,
    required bool tablet,
    required bool desktop,
    required double spacing,
  }) {
    final accent = _accentColor(context, index);

    final background = accent.withOpacity(
      theme.brightness == Brightness.dark ? 0.10 : 0.055,
    );

    final iconSize = desktop
        ? 38.0
        : mobile
        ? 34.0
        : 36.0;

    final icon = desktop
        ? 18.0
        : mobile
        ? 16.0
        : 17.0;

    final textSize = desktop
        ? 13.5
        : mobile
        ? 12.5
        : 13.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: desktop
            ? 14
            : mobile
            ? 11
            : 13,
        vertical: desktop
            ? 13
            : mobile
            ? 11
            : 12,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(desktop ? 16 : 14),
        border: Border.all(
          color: accent.withOpacity(
            theme.brightness == Brightness.dark ? 0.16 : 0.10,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_insightIcon(index), color: accent, size: icon),
          ),

          SizedBox(width: mobile ? 10 : spacing * 0.85),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                insight,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: textSize,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _accentColor(BuildContext context, int index) {
    final colorScheme = Theme.of(context).colorScheme;

    // A small semantic rotation prevents a long list from looking
    // like one repeated generic block while keeping the palette
    // restrained.
    switch (index % 4) {
      case 0:
        return colorScheme.primary;

      case 1:
        return const Color(0xFF0F9D8A);

      case 2:
        return const Color(0xFFF59E0B);

      default:
        return const Color(0xFF6366F1);
    }
  }

  IconData _insightIcon(int index) {
    switch (index % 4) {
      case 0:
        return Icons.lightbulb_rounded;

      case 1:
        return Icons.trending_up_rounded;

      case 2:
        return Icons.account_balance_wallet_rounded;

      default:
        return Icons.insights_rounded;
    }
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required ThemeData theme,
    required ColorScheme colorScheme,
    required double contentMaxWidth,
    required double cardPadding,
    required bool mobile,
  }) {
    final iconSize = mobile ? 42.0 : 46.0;

    return FadeSlideAnimation(
      delay: 350,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(mobile ? 18 : 22),
              border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(mobile ? 13 : 15),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: colorScheme.primary,
                    size: mobile ? 21 : 23,
                  ),
                ),

                SizedBox(width: ResponsiveHelper.spacing(context)),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Insights',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        'Your personalized financial insights will appear here as more data becomes available.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.4,
                          color: colorScheme.onSurfaceVariant,
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
