import 'package:flutter/material.dart';
import '../utils/responsive_helper.dart';

class SnackbarHelper {
  SnackbarHelper._();

  static void showError(BuildContext context, String message) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
        margin: EdgeInsets.all(compact ? 12 : 20),
        backgroundColor: Colors.red.shade600,
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: compact ? 12 : 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: EdgeInsets.all(compact ? 12 : 20),
        backgroundColor: Colors.green.shade600,
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: compact ? 12 : 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: EdgeInsets.all(compact ? 12 : 20),
        backgroundColor: Colors.blue.shade600,
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: compact ? 12 : 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showRateLimited(
    BuildContext context, {
    String? message,
    int? remaining,
    int? retryAfter,
  }) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    String displayMessage =
        message ?? 'Too many requests. Please try again later.';

    // Only display remaining attempts when there are attempts left.
    if (remaining != null && remaining > 0) {
      displayMessage += '\nAttempts remaining: $remaining';
    }

    // Display server-provided Retry-After value.
    if (retryAfter != null && retryAfter > 0) {
      if (retryAfter < 60) {
        displayMessage += '\nPlease wait ${retryAfter}s before trying again.';
      } else {
        final minutes = (retryAfter / 60).ceil();

        displayMessage +=
            '\nPlease wait $minutes minute${minutes == 1 ? '' : 's'} '
            'before trying again.';
      }
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        margin: EdgeInsets.all(compact ? 12 : 20),
        backgroundColor: Colors.orange.shade700,
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.timer_outlined, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                displayMessage,
                style: TextStyle(fontSize: compact ? 12 : 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
