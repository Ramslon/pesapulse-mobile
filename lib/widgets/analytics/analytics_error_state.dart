import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class AnalyticsErrorState extends StatelessWidget {
  final bool isOffline;
  final String message;
  final bool isRetrying;
  final VoidCallback onRetry;

  const AnalyticsErrorState({
    super.key,
    required this.isOffline,
    required this.message,
    required this.isRetrying,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final horizontalPadding = desktop
        ? 40.0
        : tablet
        ? 32.0
        : compact
        ? 18.0
        : 24.0;

    final iconSize = desktop
        ? 64.0
        : tablet
        ? 58.0
        : compact
        ? 44.0
        : landscape
        ? 46.0
        : 52.0;

    final titleSize = desktop
        ? 22.0
        : tablet
        ? 20.0
        : compact
        ? 16.0
        : landscape
        ? 17.0
        : 18.0;

    final messageSize = desktop
        ? 15.0
        : tablet
        ? 14.5
        : compact
        ? 12.0
        : 14.0;

    final iconTitleSpacing = compact
        ? 10.0
        : landscape
        ? 11.0
        : 14.0;

    final titleMessageSpacing = compact ? 6.0 : 8.0;

    final messageButtonSpacing = compact
        ? 14.0
        : landscape
        ? 15.0
        : 18.0;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: compact
              ? 16.0
              : landscape
              ? 12.0
              : 24.0,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: desktop
                ? 520.0
                : tablet
                ? 480.0
                : 420.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOffline
                    ? Icons.cloud_off_outlined
                    : Icons.error_outline_rounded,
                size: iconSize,
                color: colorScheme.error,
              ),

              SizedBox(height: iconTitleSpacing),

              Text(
                isOffline ? 'You are offline' : 'Unable to load analytics',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),

              SizedBox(height: titleMessageSpacing),

              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: messageSize,
                  height: 1.35,
                  color: colorScheme.onSurface.withOpacity(.7),
                ),
              ),

              SizedBox(height: messageButtonSpacing),

              ElevatedButton.icon(
                onPressed: isRetrying ? null : onRetry,
                icon: Icon(Icons.refresh_rounded, size: compact ? 17.0 : 19.0),
                label: Text(
                  isRetrying ? 'Retrying...' : 'Retry',
                  style: TextStyle(
                    fontSize: compact ? 12.0 : 13.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 16.0 : 20.0,
                    vertical: compact ? 10.0 : 12.0,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(compact ? 10.0 : 12.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
