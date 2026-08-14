import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class AnalyticsRefreshErrorBanner extends StatelessWidget {
  final String? error;
  final bool isOffline;
  final bool isRetrying;
  final VoidCallback onRetry;

  const AnalyticsRefreshErrorBanner({
    super.key,
    required this.error,
    required this.isOffline,
    required this.isRetrying,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (error == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final padding = desktop
        ? 16.0
        : tablet
        ? 14.0
        : compact
        ? 10.0
        : 12.0;

    final iconSize = compact
        ? 18.0
        : landscape
        ? 19.0
        : 20.0;

    final iconTextSpacing = compact ? 7.0 : 10.0;

    final textSize = compact
        ? 11.5
        : landscape
        ? 12.0
        : 13.0;

    final buttonHorizontalPadding = compact ? 6.0 : 10.0;

    final borderRadius = compact ? 10.0 : 12.0;

    return Card(
      margin: EdgeInsets.only(bottom: compact ? 8.0 : 10.0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: compact ? 8.0 : 10.0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isOffline
                  ? Icons.cloud_off_outlined
                  : Icons.error_outline_rounded,
              size: iconSize,
              color: colorScheme.error,
            ),

            SizedBox(width: iconTextSpacing),

            Expanded(
              child: Text(
                error!,
                maxLines: compact ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: textSize,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
              ),
            ),

            SizedBox(width: compact ? 4.0 : 8.0),

            TextButton(
              onPressed: isRetrying ? null : onRetry,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: buttonHorizontalPadding,
                  vertical: compact ? 6.0 : 8.0,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                isRetrying ? 'Retrying...' : 'Retry',
                style: TextStyle(
                  fontSize: compact ? 11.0 : 12.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
