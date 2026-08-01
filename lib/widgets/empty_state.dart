import 'package:flutter/material.dart';

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
    final isDark = theme.brightness == Brightness.dark;
    final Color accentColor = iconColor ?? theme.colorScheme.primary;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark
        ? Colors.grey.shade400
        : Colors.grey.shade600;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: accentColor.withOpacity(0.15),
              child: Icon(icon, size: 50, color: accentColor),
            ),

            const SizedBox(height: 24),

            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
                decoration: TextDecoration.none,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subTextColor,
                fontSize: 15,
                height: 1.5,
                decoration: TextDecoration.none,
              ),
            ),

            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
