import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class BudgetLoadingSkeleton extends StatelessWidget {
  const BudgetLoadingSkeleton({super.key});

  Widget skeleton({
    required BuildContext context,
    double height = 20,
    double width = double.infinity,
    BorderRadius? radius,
  }) {
    final theme = Theme.of(context);

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(.65),
        borderRadius: radius ?? BorderRadius.circular(12),
      ),
    );
  }

  Widget statCardSkeleton({required BuildContext context}) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final padding = desktop
        ? 18.0
        : tablet
        ? 16.0
        : landscape
        ? 10.0
        : compact
        ? 14.0
        : 18.0;

    final iconSize = desktop
        ? 36.0
        : tablet
        ? 34.0
        : landscape
        ? 28.0
        : 36.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(.65),
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          skeleton(
            context: context,
            width: iconSize,
            height: iconSize,
            radius: BorderRadius.circular(20),
          ),

          skeleton(
            context: context,
            width: landscape ? 70 : 90,
            height: landscape ? 10 : 13,
          ),

          skeleton(
            context: context,
            width: landscape ? 90 : 120,
            height: landscape ? 16 : 22,
          ),
        ],
      ),
    );
  }

  Widget analyticsCardSkeleton({
    required BuildContext context,
    required double height,
  }) {
    final theme = Theme.of(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final desktop = ResponsiveHelper.isDesktop(context);
    final tablet = ResponsiveHelper.isTablet(context);

    final padding = desktop
        ? 20.0
        : tablet
        ? 18.0
        : landscape
        ? 12.0
        : 18.0;

    final iconSize = landscape ? 30.0 : 42.0;

    return Container(
      height: height,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(.65),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          skeleton(
            context: context,
            width: iconSize,
            height: iconSize,
            radius: BorderRadius.circular(30),
          ),

          skeleton(context: context, width: 110, height: landscape ? 11 : 14),

          skeleton(context: context, width: 140, height: landscape ? 17 : 22),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);

    final spacing = ResponsiveHelper.spacing(context);

    final contentMaxWidth = ResponsiveHelper.contentMaxWidth(context);

    final statColumns = ResponsiveHelper.gridColumns(
      context,
      mobilePortrait: 2,
      mobileLandscape: 4,
      tabletPortrait: 4,
      tabletLandscape: 4,
      desktop: 4,
    );

    final statCardHeight = _statCardHeight(
      compact: compact,
      landscape: landscape,
      tablet: tablet,
      desktop: desktop,
    );

    final chartHeight = _chartHeight(
      compact: compact,
      landscape: landscape,
      tablet: tablet,
      desktop: desktop,
    );

    final analyticsHeight = _analyticsHeight(
      compact: compact,
      landscape: landscape,
      tablet: tablet,
      desktop: desktop,
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: landscape ? 12 : 20,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─────────────────────────────
                // Page header
                // ─────────────────────────────
                skeleton(
                  context: context,
                  width: desktop
                      ? 280
                      : tablet
                      ? 240
                      : 220,
                  height: landscape ? 26 : 32,
                ),

                SizedBox(height: landscape ? 6 : 10),

                skeleton(
                  context: context,
                  width: 180,
                  height: landscape ? 14 : 18,
                ),

                SizedBox(height: sectionSpacing),

                // ─────────────────────────────
                // Statistics grid
                // ─────────────────────────────
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: statColumns,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    mainAxisExtent: statCardHeight,
                  ),
                  children: List.generate(
                    4,
                    (_) => statCardSkeleton(context: context),
                  ),
                ),

                SizedBox(height: sectionSpacing),

                // ─────────────────────────────
                // Budget status
                // ─────────────────────────────
                skeleton(
                  context: context,
                  height: landscape ? 80 : 110,
                  radius: BorderRadius.circular(18),
                ),

                SizedBox(height: sectionSpacing),

                // ─────────────────────────────
                // Budget overview
                // ─────────────────────────────
                skeleton(
                  context: context,
                  height: landscape
                      ? 260
                      : tablet
                      ? 380
                      : 420,
                  radius: BorderRadius.circular(20),
                ),

                SizedBox(height: sectionSpacing),

                // ─────────────────────────────
                // Budget breakdown
                // ─────────────────────────────
                skeleton(
                  context: context,
                  width: desktop ? 230 : 200,
                  height: landscape ? 24 : 28,
                ),

                const SizedBox(height: 8),

                skeleton(
                  context: context,
                  width: 180,
                  height: landscape ? 14 : 18,
                ),

                SizedBox(height: spacing),

                skeleton(
                  context: context,
                  height: chartHeight,
                  radius: BorderRadius.circular(20),
                ),

                SizedBox(height: sectionSpacing),

                // ─────────────────────────────
                // Financial health
                // ─────────────────────────────
                skeleton(
                  context: context,
                  width: desktop ? 230 : 200,
                  height: landscape ? 24 : 28,
                ),

                const SizedBox(height: 8),

                skeleton(
                  context: context,
                  width: 180,
                  height: landscape ? 14 : 18,
                ),

                SizedBox(height: spacing),

                skeleton(
                  context: context,
                  height: landscape
                      ? 260
                      : tablet
                      ? 380
                      : 420,
                  radius: BorderRadius.circular(20),
                ),

                SizedBox(height: sectionSpacing),

                // ─────────────────────────────
                // Spending analytics
                // ─────────────────────────────
                skeleton(
                  context: context,
                  width: desktop ? 230 : 200,
                  height: landscape ? 24 : 28,
                ),

                const SizedBox(height: 8),

                skeleton(
                  context: context,
                  width: 180,
                  height: landscape ? 14 : 18,
                ),

                SizedBox(height: spacing),

                skeleton(
                  context: context,
                  height: chartHeight,
                  radius: BorderRadius.circular(20),
                ),

                SizedBox(height: spacing),

                // ─────────────────────────────
                // Analytics cards
                // ─────────────────────────────
                if (desktop || tablet)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: analyticsCardSkeleton(
                          context: context,
                          height: analyticsHeight,
                        ),
                      ),

                      SizedBox(width: spacing),

                      Expanded(
                        child: analyticsCardSkeleton(
                          context: context,
                          height: analyticsHeight,
                        ),
                      ),

                      SizedBox(width: spacing),

                      Expanded(
                        child: analyticsCardSkeleton(
                          context: context,
                          height: analyticsHeight,
                        ),
                      ),
                    ],
                  )
                else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: analyticsCardSkeleton(
                          context: context,
                          height: analyticsHeight,
                        ),
                      ),

                      SizedBox(width: spacing),

                      Expanded(
                        child: analyticsCardSkeleton(
                          context: context,
                          height: analyticsHeight,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: spacing),

                  analyticsCardSkeleton(
                    context: context,
                    height: analyticsHeight,
                  ),
                ],

                SizedBox(height: sectionSpacing),

                // ─────────────────────────────
                // Bottom sections
                // ─────────────────────────────
                skeleton(
                  context: context,
                  height: landscape ? 180 : 260,
                  radius: BorderRadius.circular(20),
                ),

                SizedBox(height: spacing),

                skeleton(
                  context: context,
                  height: landscape ? 120 : 170,
                  radius: BorderRadius.circular(18),
                ),

                SizedBox(height: spacing),

                skeleton(
                  context: context,
                  height: landscape ? 90 : 120,
                  radius: BorderRadius.circular(18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _statCardHeight({
    required bool compact,
    required bool landscape,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) {
      return 145;
    }

    if (tablet) {
      return landscape ? 125 : 145;
    }

    if (landscape) {
      return 105;
    }

    if (compact) {
      return 125;
    }

    return 140;
  }

  double _chartHeight({
    required bool compact,
    required bool landscape,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) {
      return 280;
    }

    if (tablet) {
      return landscape ? 220 : 260;
    }

    if (landscape) {
      return 150;
    }

    if (compact) {
      return 210;
    }

    return 240;
  }

  double _analyticsHeight({
    required bool compact,
    required bool landscape,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) {
      return 145;
    }

    if (tablet) {
      return landscape ? 135 : 150;
    }

    if (landscape) {
      return 120;
    }

    if (compact) {
      return 125;
    }

    return 145;
  }
}
