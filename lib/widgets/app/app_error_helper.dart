import 'package:flutter/material.dart';

class AppErrorHelper {
  static void show(
    BuildContext context, {
    String? message,
    String fallbackMessage = 'Something went wrong. Please try again.',
  }) {
    if (!context.mounted) return;

    final displayMessage = message?.trim().isNotEmpty == true
        ? message!
        : fallbackMessage;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(displayMessage),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  static void showConnectionError(BuildContext context) {
    show(
      context,
      message:
          'Unable to connect. Please check your internet connection and try again.',
    );
  }

  static void showServerError(BuildContext context) {
    show(
      context,
      message: 'The server is currently unavailable. Please try again later.',
    );
  }

  static void showGenericError(BuildContext context) {
    show(context, message: 'Something went wrong. Please try again.');
  }
}
