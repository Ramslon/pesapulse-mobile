import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:pesapulse_mobile/screens/auth_choice_screen.dart';
import 'package:pesapulse_mobile/widgets/auth_message_helper.dart';
import '../repositories/settings_repository.dart';
import '../services/session_service.dart';
import '../exceptions/auth_exception.dart';
import '../exceptions/rate_limit_exception.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final passwordController = TextEditingController();
  final SettingsRepository settingsRepository = SettingsRepository();

  bool agree = false;
  bool obscurePassword = true;
  bool isDeleting = false;

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  Future<void> deleteAccount() async {
    setState(() {
      isDeleting = true;
    });

    try {
      await settingsRepository.deleteAccount(passwordController.text.trim());

      await SessionService.logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthChoiceScreen()),
        (route) => false,
      );

      AuthMessageHelper.showSuccess(context, "Account deleted successfully");
    } on AuthException catch (e) {
      if (!mounted) return;

      // Try to decode Laravel validation errors.
      try {
        final errors = jsonDecode(e.message);

        if (errors is Map<String, dynamic>) {
          // If your delete-account form has a password-specific
          // error field, handle it here.
          if (errors['password'] != null) {
            AuthMessageHelper.showError(
              context,
              errors['password'][0]?.toString() ?? 'Invalid password.',
            );
          } else {
            AuthMessageHelper.showError(context, e.message);
          }

          return;
        }
      } catch (_) {
        // Not a validation-error JSON payload.
      }

      AuthMessageHelper.showError(context, e.message);
    } on RateLimitException catch (e) {
      if (!mounted) return;

      AuthMessageHelper.showRateLimited(
        context,
        message: e.message,
        remaining: e.remaining,
        retryAfter: e.retryAfter,
      );
    } catch (e) {
      if (!mounted) return;

      debugPrint('Delete account error: $e');

      AuthMessageHelper.showError(
        context,
        'Account deletion failed. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDelete =
        passwordController.text.isNotEmpty && agree && !isDeleting;

    return Scaffold(
      appBar: AppBar(title: const Text("Delete Account")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 80),

          const SizedBox(height: 20),

          const Text(
            "Delete Your Account",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          const Text(
            "Deleting your account is permanent and cannot be undone.",
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 30),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "The following will be permanently removed:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.receipt_long),
                    title: Text("All expenses"),
                  ),
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.account_balance_wallet),
                    title: Text("Budgets"),
                  ),
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.flag),
                    title: Text("Goals"),
                  ),
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.analytics),
                    title: Text("Analytics history"),
                  ),
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.settings),
                    title: Text("Preferences"),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: "Confirm Password",
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
                icon: Icon(
                  obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          CheckboxListTile(
            value: agree,
            onChanged: (value) {
              setState(() {
                agree = value ?? false;
              });
            },
            title: const Text("I understand this action cannot be undone."),
          ),

          const SizedBox(height: 30),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(55),
            ),
            onPressed: canDelete
                ? () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Delete Account?"),
                        content: const Text(
                          "This will permanently delete your account and all your data.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await deleteAccount();
                    }
                  }
                : null,
            icon: isDeleting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.delete_forever),
            label: Text(isDeleting ? "Deleting..." : "Delete Account"),
          ),
        ],
      ),
    );
  }
}
