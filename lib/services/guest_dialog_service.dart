import 'package:flutter/material.dart';

import '../services/session_service.dart';
import '../screens/register_screen.dart';

class GuestDialogService {
  static Future<bool> isGuest() async {
    return await SessionService.isGuest();
  }

  static Future<bool> requireAccount(BuildContext context) async {
    if (await isGuest()) {
      await show(context);
      return false;
    }

    return true;
  }

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
          "Create a free account to unlock cloud sync, backups, AI features, "
          "and access your data across devices.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Maybe Later"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              );
            },
            child: const Text("Create Account"),
          ),
        ],
      ),
    );
  }
}
