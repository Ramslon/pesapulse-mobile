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

  ({Color color, Color backgroundColor}) _sectionColors(BuildContext context) {
    switch (title.toLowerCase()) {
      case 'category breakdown':
        return (
          color: Colors.blue.shade700,
          backgroundColor: Colors.blue.withOpacity(0.12),
        );

      case 'goal status':
        return (
          color: Colors.orange.shade700,
          backgroundColor: Colors.orange.withOpacity(0.12),
        );

      case 'monthly spending trend':
        return (
          color: Colors.teal.shade700,
          backgroundColor: Colors.teal.withOpacity(0.12),
        );

      case 'smart insights':
        return (
          color: Colors.amber.shade800,
          backgroundColor: Colors.amber.withOpacity(0.14),
        );

      case 'reports center':
        return (
          color: Colors.indigo.shade600,
          backgroundColor: Colors.indigo.withOpacity(0.12),
        );

      default:
        final colorScheme = Theme.of(context).colorScheme;

        return (
          color: colorScheme.primary,
          backgroundColor: colorScheme.primary.withOpacity(0.12),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _sectionColors(context);

    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    final iconSize = isMobile
        ? 20.0
        : isTablet
        ? 21.0
        : 22.0;

    final iconContainerSize = isMobile
        ? 38.0
        : isTablet
        ? 40.0
        : 42.0;

    final titleFontSize = isMobile
        ? 17.0
        : isTablet
        ? 19.0
        : 20.0;

    final spacing = ResponsiveHelper.spacing(context);

    return Row(
      children: [
        Container(
          width: iconContainerSize,
          height: iconContainerSize,
          decoration: BoxDecoration(
            color: colors.backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colors.color, size: iconSize),
        ),

        SizedBox(width: spacing),

        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
