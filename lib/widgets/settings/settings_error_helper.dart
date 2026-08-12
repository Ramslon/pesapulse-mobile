import 'package:flutter/material.dart';

class SettingsErrorHelper {
  static void show(BuildContext context, {String? message}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Something went wrong. Please try again.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static String messageFor(Object error) {
    final errorMessage = error.toString().toLowerCase();

    if (errorMessage.contains('socket') ||
        errorMessage.contains('connection') ||
        errorMessage.contains('network') ||
        errorMessage.contains('timeout')) {
      return 'Unable to connect. Please check your internet connection.';
    }

    if (errorMessage.contains('unauthorized') || errorMessage.contains('401')) {
      return 'Your session has expired. Please sign in again.';
    }

    if (errorMessage.contains('forbidden') || errorMessage.contains('403')) {
      return 'You do not have permission to perform this action.';
    }

    if (errorMessage.contains('404')) {
      return 'The requested information could not be found.';
    }

    if (errorMessage.contains('500')) {
      return 'The server is temporarily unavailable. Please try again later.';
    }

    return 'Something went wrong. Please try again.';
  }
}
