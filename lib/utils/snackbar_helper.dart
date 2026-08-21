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
}
