import 'package:flutter/material.dart';

import '/utils/responsive_helper.dart';

class AnalyticsLoadingSkeleton extends StatelessWidget {
  const AnalyticsLoadingSkeleton({super.key});

  Widget cardPlaceholder(BuildContext context, {double height = 120}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final spacing = ResponsiveHelper.spacing(context);
    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);

    final contentMaxWidth = ResponsiveHelper.contentMaxWidth(context);

    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    final healthCardHeight = isMobile
        ? 150.0
        : isTablet
        ? 170.0
        : 180.0;

    final smallCardHeight = isMobile
        ? 120.0
        : isTablet
        ? 135.0
        : 145.0;

    final categoryChartHeight = isMobile
        ? 220.0
        : isTablet
        ? 250.0
        : 280.0;

    final goalChartHeight = isMobile
        ? 170.0
        : isTablet
        ? 190.0
        : 210.0;

    final monthlyChartHeight = isMobile
        ? 300.0
        : isTablet
        ? 330.0
        : 360.0;

    final insightsHeight = isMobile
        ? 260.0
        : isTablet
        ? 280.0
        : 300.0;

    final recommendationHeight = isMobile
        ? 220.0
        : isTablet
        ? 240.0
        : 260.0;

    final reportsHeight = isMobile
        ? 180.0
        : isTablet
        ? 200.0
        : 220.0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: sectionSpacing * 0.75,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth),
              child: Column(
                children: [
                  // Financial health / summary card
                  cardPlaceholder(context, height: healthCardHeight),

                  SizedBox(height: sectionSpacing),

                  // Summary cards
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: cardPlaceholder(
                          context,
                          height: smallCardHeight,
                        ),
                      ),

                      SizedBox(width: spacing),

                      Expanded(
                        child: cardPlaceholder(
                          context,
                          height: smallCardHeight,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: spacing),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: cardPlaceholder(
                          context,
                          height: smallCardHeight,
                        ),
                      ),

                      SizedBox(width: spacing),

                      Expanded(
                        child: cardPlaceholder(
                          context,
                          height: smallCardHeight,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: sectionSpacing),

                  // Category breakdown
                  cardPlaceholder(context, height: categoryChartHeight),

                  SizedBox(height: sectionSpacing),

                  // Goal status
                  cardPlaceholder(context, height: goalChartHeight),

                  SizedBox(height: sectionSpacing),

                  // Monthly spending
                  cardPlaceholder(context, height: monthlyChartHeight),

                  SizedBox(height: sectionSpacing),

                  // Smart insights
                  cardPlaceholder(context, height: insightsHeight),

                  SizedBox(height: sectionSpacing),

                  // Recommendation
                  cardPlaceholder(context, height: recommendationHeight),

                  SizedBox(height: sectionSpacing),

                  // Reports center
                  cardPlaceholder(context, height: reportsHeight),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
