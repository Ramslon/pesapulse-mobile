import 'package:flutter/material.dart';
import '../services/api_services.dart';

import 'dart:convert';

import 'login_screen.dart';
import '../widgets/auth_message_helper.dart';
import '../exceptions/auth_exception.dart';
import '../exceptions/rate_limit_exception.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final currentController = TextEditingController();

  final newController = TextEditingController();

  final confirmController = TextEditingController();

  bool isSaving = false;

  bool obscureCurrent = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  String? currentError;
  String? newError;
  String? confirmError;

  @override
  void dispose() {
    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  double get passwordStrength {
    final password = newController.text;

    double score = 0;

    if (password.length >= 8) score += 0.25;

    if (RegExp(r'[A-Z]').hasMatch(password)) score += 0.25;

    if (RegExp(r'[0-9]').hasMatch(password)) score += 0.25;

    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score += 0.25;

    return score;
  }

  Future<void> changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSaving = true;
      currentError = null;
      newError = null;
      confirmError = null;
    });

    try {
      await ApiService.changePassword(
        currentPassword: currentController.text.trim(),
        newPassword: newController.text.trim(),
        confirmPassword: confirmController.text.trim(),
      );

      if (!mounted) return;

      AuthMessageHelper.showSuccess(
        context,
        "Password changed successfully. Please login again.",
      );

      await ApiService.logoutUser();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      // Laravel validation errors are returned as JSON.
      try {
        final errors = jsonDecode(e.message);

        if (errors is Map<String, dynamic>) {
          setState(() {
            if (errors['current_password'] != null) {
              currentError = errors['current_password'][0]?.toString();
            }

            if (errors['new_password'] != null) {
              newError = errors['new_password'][0]?.toString();
            }

            if (errors['new_password_confirmation'] != null) {
              confirmError = errors['new_password_confirmation'][0]?.toString();
            }
          });

          return;
        }
      } catch (_) {
        // Not a validation-error JSON payload.
      }

      // General authentication/account error.
      AuthMessageHelper.showError(context, e.message);

      if (e.remaining != null && e.remaining! > 0) {
        AuthMessageHelper.showAttemptsRemaining(context, e.remaining!);
      }
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

      debugPrint('Password change error: $e');

      AuthMessageHelper.showError(
        context,
        'Password change failed. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget _buildCurrentPasswordField() {
      return TextFormField(
        controller: currentController,
        obscureText: obscureCurrent,

        decoration: InputDecoration(
          labelText: "Current Password",

          prefixIcon: const Icon(Icons.lock),

          suffixIcon: IconButton(
            icon: Icon(
              obscureCurrent ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () {
              setState(() {
                obscureCurrent = !obscureCurrent;
              });
            },
          ),

          errorText: currentError,
        ),

        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Current password is required";
          }
          return null;
        },
      );
    }

    Widget _buildNewPasswordField() {
      return TextFormField(
        controller: newController,
        obscureText: obscureNew,

        onChanged: (_) => setState(() {}),

        decoration: InputDecoration(
          labelText: "New Password",

          prefixIcon: const Icon(Icons.password),

          suffixIcon: IconButton(
            icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                obscureNew = !obscureNew;
              });
            },
          ),

          errorText: newError,
        ),

        validator: (value) {
          if (value == null || value.isEmpty) {
            return "New password is required";
          }

          if (value.length < 8) {
            return "Minimum 8 characters";
          }

          return null;
        },
      );
    }

    Widget _buildConfirmPasswordField() {
      return TextFormField(
        controller: confirmController,
        obscureText: obscureConfirm,

        decoration: InputDecoration(
          labelText: "Confirm Password",

          prefixIcon: const Icon(Icons.lock_reset),

          suffixIcon: IconButton(
            icon: Icon(
              obscureConfirm ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () {
              setState(() {
                obscureConfirm = !obscureConfirm;
              });
            },
          ),

          errorText: confirmError,
        ),

        validator: (value) {
          if (value != newController.text) {
            return "Passwords do not match";
          }

          return null;
        },
      );
    }

    Widget _buildPasswordStrength() {
      Color color;

      String text;

      if (passwordStrength < 0.5) {
        color = Colors.red;

        text = "Weak";
      } else if (passwordStrength < 1) {
        color = Colors.orange;

        text = "Medium";
      } else {
        color = Colors.green;

        text = "Strong";
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Password Strength: $text",
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          LinearProgressIndicator(
            value: passwordStrength,
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Change Password")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline, size: 70, color: Colors.green),

              const SizedBox(height: 20),

              const Text(
                "Update Your Password",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                "Choose a strong password to keep your account secure.",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 35),

              _buildCurrentPasswordField(),

              const SizedBox(height: 20),

              _buildNewPasswordField(),

              const SizedBox(height: 15),

              _buildPasswordStrength(),

              const SizedBox(height: 20),

              _buildConfirmPasswordField(),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(isSaving ? "Saving..." : "Change Password"),
                  onPressed: isSaving ? null : changePassword,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
