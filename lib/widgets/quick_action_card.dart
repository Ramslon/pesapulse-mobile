import 'package:flutter/material.dart';

import '../utils/responsive_helper.dart';

class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);

    final cardPadding = compact
        ? 12.0
        : landscape
        ? 15.0
        : 18.0;

    final horizontalPadding = compact
        ? 8.0
        : landscape
        ? 10.0
        : 12.0;

    final iconRadius = compact
        ? 18.0
        : landscape
        ? 20.0
        : 22.0;

    final iconSize = compact
        ? 20.0
        : landscape
        ? 21.0
        : 22.0;

    final titleFontSize = compact
        ? 12.0
        : landscape
        ? 13.0
        : 14.0;

    final spacing = compact
        ? 8.0
        : landscape
        ? 10.0
        : 12.0;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: cardPadding,
            horizontal: horizontalPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: iconRadius,
                backgroundColor: color.withOpacity(.12),
                child: Icon(icon, color: color, size: iconSize),
              ),

              SizedBox(height: spacing),

              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: titleFontSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
