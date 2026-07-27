import 'package:flutter/material.dart';

class GuestDialogService {
  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.orange),
            SizedBox(width: 10),
            Text("Guest Mode"),
          ],
        ),
        content: const Text(
          "This feature requires an account.\n\n"
          "Create a free account to unlock cloud sync, profile management, backups, AI features and access your data on multiple devices.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Maybe Later"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);

              Navigator.pushNamed(context, "/register");
            },
            child: const Text("Create Account"),
          ),
        ],
      ),
    );
  }
}
