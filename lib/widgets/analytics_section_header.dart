import 'package:flutter/material.dart';

import '/utils/responsive_helper.dart';

class AnalyticsSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const AnalyticsSectionHeader({
    super.key,
    required this.icon,
    required this.title,
  });

  ({Color color, Color backgroundColor, String label}) _sectionStyle(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (title.toLowerCase()) {
      case 'category breakdown':
        return (
          color: const Color(0xFF2563EB),
          backgroundColor: const Color(0xFF2563EB).withOpacity(0.09),
          label: 'SPENDING',
        );

      case 'goal status':
        return (
          color: const Color(0xFFF59E0B),
          backgroundColor: const Color(0xFFF59E0B).withOpacity(0.10),
          label: 'GOALS',
        );

      case 'monthly spending trend':
        return (
          color: const Color(0xFF0F9D8A),
          backgroundColor: const Color(0xFF0F9D8A).withOpacity(0.09),
          label: 'TREND',
        );

      case 'smart insights':
        return (
          color: const Color(0xFF7C3AED),
          backgroundColor: const Color(0xFF7C3AED).withOpacity(0.09),
          label: 'INSIGHTS',
        );

      case 'reports center':
        return (
          color: const Color(0xFF4F46E5),
          backgroundColor: const Color(0xFF4F46E5).withOpacity(0.09),
          label: 'REPORTS',
        );

      default:
        return (
          color: colorScheme.primary,
          backgroundColor: colorScheme.primary.withOpacity(0.09),
          label: 'ANALYTICS',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final section = _sectionStyle(context);

    final mobile = ResponsiveHelper.isMobile(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final iconContainerSize = desktop
        ? 42.0
        : tablet
        ? 40.0
        : mobile
        ? 36.0
        : 39.0;

    final iconSize = desktop
        ? 21.0
        : tablet
        ? 20.0
        : mobile
        ? 18.0
        : 19.0;

    final titleSize = desktop
        ? 19.0
        : tablet
        ? 18.0
        : mobile
        ? 16.0
        : 17.0;

    final labelSize = desktop
        ? 9.0
        : mobile
        ? 7.5
        : 8.0;

    final spacing = mobile
        ? 9.0
        : desktop
        ? 12.0
        : 10.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: iconContainerSize,
          height: iconContainerSize,
          decoration: BoxDecoration(
            color: section.backgroundColor,
            borderRadius: BorderRadius.circular(mobile ? 11 : 13),
            border: Border.all(color: section.color.withOpacity(0.10)),
          ),
          child: Icon(icon, color: section.color, size: iconSize),
        ),

        SizedBox(width: spacing),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 5),

              Row(
                children: [
                  Container(
                    width: 22,
                    height: 3,
                    decoration: BoxDecoration(
                      color: section.color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(width: 6),

                  Text(
                    section.label,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.62),
                      fontSize: labelSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        Container(
          width: desktop
              ? 7
              : mobile
              ? 6
              : 6,
          height: desktop
              ? 7
              : mobile
              ? 6
              : 6,
          decoration: BoxDecoration(
            color: section.color.withOpacity(0.75),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
