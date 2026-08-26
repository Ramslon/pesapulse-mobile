import 'package:flutter/material.dart';

class AuthMessageHelper {
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showOffline(BuildContext context) {
    showError(
      context,
      "You’re offline. Please check your internet connection and try again.",
    );
  }

  /// Shows a rate-limit message.
  ///
  /// If [retryAfter] is available, the user is told how long
  /// they should wait before trying again.
  ///
  /// If [remaining] is available, the number of remaining
  /// attempts can also be displayed.
  static void showRateLimited(
    BuildContext context, {
    String? message,
    int? remaining,
    int? retryAfter,
  }) {
    String displayMessage =
        message ?? "Too many attempts. Please try again later.";

    // Only show remaining attempts when there are actually attempts left.
    if (remaining != null && remaining > 0) {
      displayMessage += "\nAttempts remaining: $remaining";
    }

    // Show the server-provided Retry-After value.
    if (retryAfter != null && retryAfter > 0) {
      if (retryAfter < 60) {
        displayMessage += "\nPlease wait ${retryAfter}s before trying again.";
      } else {
        final minutes = (retryAfter / 60).ceil();

        displayMessage +=
            "\nPlease wait $minutes minute${minutes == 1 ? '' : 's'} "
            "before trying again.";
      }
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.timer_outlined, color: Colors.white),

            const SizedBox(width: 8),

            Expanded(child: Text(displayMessage)),
          ],
        ),

        backgroundColor: Colors.orange.shade700,

        behavior: SnackBarBehavior.floating,

        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Shows the number of authentication attempts remaining.
  ///
  /// This is useful after a failed authentication request
  /// when the server provides the X-RateLimit-Remaining header.
  static void showAttemptsRemaining(
    BuildContext context,
    int remaining, {
    String? message,
  }) {
    if (remaining <= 0) return;

    final displayMessage = message != null
        ? '$message $remaining attempts remaining.'
        : '$remaining authentication attempts remaining.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(displayMessage)),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
