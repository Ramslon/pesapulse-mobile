import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/connectivity_provider.dart';

class GoalActionHelpers {
  static Future<bool> confirmDelete(
    BuildContext context, {
    required String goalTitle,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Goal'),
            content: Text("Are you sure you want to delete '$goalTitle'?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  static Future<bool> confirmArchive(
    BuildContext context, {
    required String goalTitle,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Archive Goal'),
            content: Text("Are you sure you want to archive '$goalTitle'?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Archive'),
              ),
            ],
          ),
        ) ??
        false;
  }

  static void showMessage(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), duration: duration));
  }

  static ConnectivityProvider getConnectivity(BuildContext context) {
    return context.read<ConnectivityProvider>();
  }
}
