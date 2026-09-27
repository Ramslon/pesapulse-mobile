import 'package:flutter/material.dart';

import '../utils/responsive_helper.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final tablet = ResponsiveHelper.isTablet(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final colorScheme = Theme.of(context).colorScheme;

    final height = desktop
        ? 54.0
        : tablet
        ? 52.0
        : compact
        ? 48.0
        : landscape
        ? 50.0
        : 52.0;

    final radius = compact
        ? 14.0
        : landscape
        ? 15.0
        : 17.0;

    final iconSize = compact
        ? 18.0
        : landscape
        ? 19.0
        : 21.0;

    final fontSize = desktop
        ? 15.0
        : tablet
        ? 14.5
        : compact
        ? 12.5
        : landscape
        ? 13.0
        : 14.0;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: isLoading
              ? null
              : [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.14),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            disabledBackgroundColor: colorScheme.primary.withOpacity(0.55),
            foregroundColor: colorScheme.onPrimary,
            disabledForegroundColor: colorScheme.onPrimary.withOpacity(0.9),
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: isLoading
                ? SizedBox(
                    key: const ValueKey('loading'),
                    width: compact ? 19 : 21,
                    height: compact ? 19 : 21,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    key: const ValueKey('content'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: iconSize),
                        SizedBox(width: compact ? 7 : 9),
                      ],
                      Flexible(
                        child: Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.05,
                          ),
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
