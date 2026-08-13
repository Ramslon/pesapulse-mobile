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

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(.65),
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
      ),
      padding: EdgeInsets.all(
        landscape
            ? 10
            : compact
            ? 14
            : 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          skeleton(
            context: context,
            width: landscape ? 28 : 36,
            height: landscape ? 28 : 36,
            radius: BorderRadius.circular(20),
          ),

          SizedBox(height: landscape ? 8 : 12),

          skeleton(
            context: context,
            width: landscape ? 70 : 90,
            height: landscape ? 10 : 13,
          ),

          const Spacer(),

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

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(.65),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: ResponsiveHelper.isLandscape(context)
          ? const EdgeInsets.all(12)
          : const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          skeleton(
            context: context,
            width: ResponsiveHelper.isLandscape(context) ? 30 : 42,
            height: ResponsiveHelper.isLandscape(context) ? 30 : 42,
            radius: BorderRadius.circular(30),
          ),

          SizedBox(height: ResponsiveHelper.isLandscape(context) ? 8 : 12),

          skeleton(
            context: context,
            width: 110,
            height: ResponsiveHelper.isLandscape(context) ? 11 : 14,
          ),

          const Spacer(),

          skeleton(
            context: context,
            width: 140,
            height: ResponsiveHelper.isLandscape(context) ? 17 : 22,
          ),
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
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: statColumns,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: _statCardAspectRatio(
                    context,
                    columns: statColumns,
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

                // Analytics cards
                if (desktop || tablet)
                  Row(
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

  double _statCardAspectRatio(BuildContext context, {required int columns}) {
    final landscape = ResponsiveHelper.isLandscape(context);
    final desktop = ResponsiveHelper.isDesktop(context);
    final tablet = ResponsiveHelper.isTablet(context);

    if (desktop) {
      return 1.9;
    }

    if (tablet) {
      return landscape ? 1.8 : 1.5;
    }

    if (landscape) {
      return 2.0;
    }

    return columns == 2 ? 1.35 : 1.5;
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
