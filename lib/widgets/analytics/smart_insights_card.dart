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

    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    final contentMaxWidth = ResponsiveHelper.contentMaxWidth(context);

    final cardPadding = ResponsiveHelper.cardPadding(context);

    final horizontalPadding = isDesktop
        ? 16.0
        : isTablet
        ? 14.0
        : 12.0;

    final verticalPadding = isDesktop
        ? 16.0
        : isTablet
        ? 14.0
        : 12.0;

    final insightIconSize = isMobile ? 28.0 : 30.0;

    final emptyIconSize = isMobile ? 42.0 : 44.0;

    // Remove empty insight strings before displaying them.
    final validInsights = insights
        .map((insight) => insight.trim())
        .where((insight) => insight.isNotEmpty)
        .toList();

    if (validInsights.isEmpty) {
      return FadeSlideAnimation(
        delay: 350,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: Card(
              elevation: 1,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Row(
                  children: [
                    Container(
                      width: emptyIconSize,
                      height: emptyIconSize,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        color: colorScheme.primary,
                        size: isMobile ? 22 : 24,
                      ),
                    ),

                    SizedBox(width: ResponsiveHelper.spacing(context)),

                    Expanded(
                      child: Text(
                        'No smart insights available yet.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return FadeSlideAnimation(
      delay: 350,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: Card(
            elevation: 1,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...validInsights.asMap().entries.map((entry) {
                    final index = entry.key;
                    final insight = entry.value;

                    final isLast = index == validInsights.length - 1;

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: isLast
                            ? 0
                            : ResponsiveHelper.spacing(context) * 0.7,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withOpacity(0.45),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.08),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: insightIconSize,
                              height: insightIconSize,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.10),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontSize: isMobile ? 11 : 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            SizedBox(
                              width: ResponsiveHelper.spacing(context) * 0.8,
                            ),

                            Expanded(
                              child: Text(
                                insight,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: isMobile ? 13.5 : 14,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
