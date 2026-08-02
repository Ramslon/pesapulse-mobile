import 'package:flutter/material.dart';

import '../services/api_services.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/success_dialog.dart';
import '../widgets/auth_message_helper.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _autoValidate = false;

  bool isLoading = false;

  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  Future<void> resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = true);
      return;
    }

    FocusScope.of(context).unfocus();

    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      await ApiService.resetPassword(
        email: widget.email,
        otp: widget.otp,
        password: passwordController.text.trim(),
        confirmPassword: confirmPasswordController.text.trim(),
      );

      if (!mounted) return;

      setState(() => isLoading = false);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => SuccessDialog(
          title: "Password Reset Successful",
          message:
              "Your password has been updated successfully.\n\nPlease log in using your new password.",
          onContinue: () {
            Navigator.of(context).pop();

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      //  Use helper for consistency
      AuthMessageHelper.showOffline(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),

                IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),

                const SizedBox(height: 20),

                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                      ),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: Colors.green,
                      size: 36,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  "Create New Password",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Choose a strong password for your account.",
                  style: TextStyle(color: Colors.grey.shade600),
                ),

                const SizedBox(height: 35),

                Form(
                  key: _formKey,
                  autovalidateMode: _autoValidate
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: passwordController,
                            label: "New Password",
                            obscureText: true,
                            prefixIcon: Icons.lock_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Enter a password";
                              }

                              if (value.length < 8) {
                                return "Password must be at least 8 characters";
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          CustomTextField(
                            controller: confirmPasswordController,
                            label: "Confirm Password",
                            obscureText: true,
                            prefixIcon: Icons.lock_outline,
                            validator: (value) {
                              if (value != passwordController.text) {
                                return "Passwords do not match";
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: CustomButton(
                              text: "Reset Password",
                              isLoading: isLoading,
                              onPressed: resetPassword,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
