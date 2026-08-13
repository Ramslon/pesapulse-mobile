import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final accentColor = iconColor ?? colorScheme.primary;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final compact = ResponsiveHelper.useCompactLayout(context);

    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final iconRadius = isDesktop
        ? 56.0
        : isTablet
        ? 52.0
        : compact
        ? 38.0
        : 45.0;

    final iconSize = isDesktop
        ? 60.0
        : isTablet
        ? 56.0
        : compact
        ? 42.0
        : 50.0;

    final titleSize = isDesktop
        ? 28.0
        : isTablet
        ? 26.0
        : compact
        ? 21.0
        : 24.0;

    final messageSize = isDesktop
        ? 16.0
        : isTablet
        ? 15.5
        : compact
        ? 13.5
        : 15.0;

    final maxContentWidth = isDesktop
        ? 520.0
        : isTablet
        ? 480.0
        : 420.0;

    final verticalSpacing = ResponsiveHelper.spacing(context);

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: ResponsiveHelper.sectionSpacing(context),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: iconRadius * 2,
                height: iconRadius * 2,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor.withOpacity(0.08)),
                ),
                child: Icon(icon, size: iconSize, color: accentColor),
              ),

              SizedBox(height: verticalSpacing + 8),

              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  color: textColor,
                  letterSpacing: -0.2,
                ),
              ),

              SizedBox(height: verticalSpacing * 0.65),

              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: subTextColor,
                  fontSize: messageSize,
                  height: 1.5,
                ),
              ),

              if (action != null) ...[
                SizedBox(height: verticalSpacing + 6),

                // Prevent action widgets from becoming excessively wide
                // on tablets and desktop.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: isMobile ? 0 : 180,
                    maxWidth: isDesktop
                        ? 320
                        : isTablet
                        ? 300
                        : double.infinity,
                  ),
                  child: action!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
