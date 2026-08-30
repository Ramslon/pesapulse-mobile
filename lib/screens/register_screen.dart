import 'package:flutter/material.dart';
import 'package:pesapulse_mobile/screens/login_screen.dart';
import 'package:pesapulse_mobile/screens/home_screen.dart';

import '../services/api_services.dart';
import '../services/session_service.dart';
import '../services/migration_service.dart';
import '../services/sync_service.dart';

import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/auth_message_helper.dart';

import '../exceptions/rate_limit_exception.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  final _formKey = GlobalKey<FormState>();

  bool _autoValidate = false;

  Future<void> registerUser() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = true);
      return;
    }

    if (isLoading) return;

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() => isLoading = true);

    try {
      final response = await ApiService.registerUser(name, email, password);

      if (response.containsKey('token')) {
        final token = response['token'];
        final userId = response['user']['id'].toString();

        // ------------------------------------------------------------
        // STEP 1: Create the authenticated session.
        // ------------------------------------------------------------

        await SessionService.loginUser(userId, token);

        ApiService.token = token;

        // Start automatic syncing after authentication.
        SyncService.instance.startListening();

        // ------------------------------------------------------------
        // STEP 2: Migrate any guest data to the new account.
        // ------------------------------------------------------------

        try {
          await MigrationService.instance.migrateGuestData(userId);

          // Cleanup guest-only sync items after successful migration.
          await SyncService.instance.cleanupGuestQueue();

          debugPrint(
            'Guest data migration after registration completed successfully.',
          );
        } catch (migrationError) {
          debugPrint(
            'Guest data migration after registration failed: '
            '$migrationError',
          );

          if (!mounted) return;

          AuthMessageHelper.showError(
            context,
            'Account created, but your guest data could not be migrated. '
            'You can continue using your account.',
          );

          return;
        }

        if (!mounted) return;

        // ------------------------------------------------------------
        // STEP 3: Continue to the application.
        // ------------------------------------------------------------

        AuthMessageHelper.showSuccess(context, 'Account created successfully!');

        await Future.delayed(const Duration(milliseconds: 700));

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        if (!mounted) return;

        AuthMessageHelper.showError(
          context,
          response['message'] ?? 'Registration failed.',
        );
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

      debugPrint('Registration error: $e');

      AuthMessageHelper.showError(
        context,
        'Unable to create your account. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
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

                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(.10),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.blue.withOpacity(.15)),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Colors.blue,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                Text(
                  "Create Account",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Center(
                  child: Text(
                    "Join PesaPulse and start taking control\nof your finances today.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
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
                            controller: nameController,
                            label: "Full Name",
                            prefixIcon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Please enter your full name";
                              }

                              if (value.trim().length < 3) {
                                return "Name is too short";
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          CustomTextField(
                            controller: emailController,
                            label: "Email Address",
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Please enter your email";
                              }

                              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

                              if (!emailRegex.hasMatch(value.trim())) {
                                return "Enter a valid email";
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          CustomTextField(
                            controller: passwordController,
                            label: "Password",
                            obscureText: true,
                            prefixIcon: Icons.lock_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter a password";
                              }

                              if (value.length < 8) {
                                return "Password must be at least 8 characters";
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: CustomButton(
                              text: "Create Account",
                              isLoading: isLoading,
                              onPressed: registerUser,
                            ),
                          ),

                          const SizedBox(height: 22),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.login_rounded),
                              label: const Text(
                                "Already have an account? Sign In",
                              ),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
