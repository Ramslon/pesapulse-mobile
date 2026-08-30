import 'package:flutter/material.dart';
import 'package:pesapulse_mobile/screens/forgot_password_screen.dart';
import 'register_screen.dart';
import '../services/api_services.dart';
import '../services/session_service.dart';
import '../services/migration_service.dart';
import '../services/sync_service.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/auth_message_helper.dart';
import '../exceptions/auth_exception.dart';

import '../exceptions/rate_limit_exception.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  final _formKey = GlobalKey<FormState>();

  bool _autoValidate = false;

  Future<void> loginUser() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = true);
      return;
    }

    FocusScope.of(context).unfocus();

    if (isLoading) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    setState(() => isLoading = true);

    try {
      final response = await ApiService.loginUser(email, password);

      if (response.containsKey('token')) {
        final prefs = await SharedPreferences.getInstance();

        final token = response['token'];
        final userId = response['user']['id'].toString();

        // ------------------------------------------------------------
        // STEP 1: Save authentication information.
        // ------------------------------------------------------------

        await prefs.setString('token', token);
        await prefs.setString('owner_id', userId);

        ApiService.token = token;

        await SessionService.loginUser(userId, token);

        // Start automatic syncing only after authentication.
        SyncService.instance.startListening();

        // ------------------------------------------------------------
        // STEP 2: Migrate any guest data to this authenticated user.
        // ------------------------------------------------------------

        try {
          await MigrationService.instance.migrateGuestData(userId);

          // Cleanup guest-only sync items after successful migration.
          await SyncService.instance.cleanupGuestQueue();

          debugPrint('Guest data migration completed successfully.');
        } on AuthException catch (e) {
          debugPrint('Guest data migration failed: $e');

          if (!mounted) return;

          AuthMessageHelper.showError(
            context,
            'You signed in successfully, but your guest data '
            'could not be migrated: ${e.message}',
          );

          if (e.remaining != null && e.remaining! > 0) {
            AuthMessageHelper.showAttemptsRemaining(context, e.remaining!);
          }

          // Do NOT return.
          // Authentication was successful.
        } catch (migrationError) {
          debugPrint('Guest data migration failed: $migrationError');

          if (!mounted) return;

          AuthMessageHelper.showError(
            context,
            'You signed in successfully, but your guest data '
            'could not be migrated. You can continue using your account.',
          );

          // Do NOT return.
        }

        if (!mounted) return;

        // ------------------------------------------------------------
        // STEP 3: Continue to the application.
        // ------------------------------------------------------------

        AuthMessageHelper.showSuccess(context, "Welcome back! 👋");

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else {
        if (!mounted) return;

        AuthMessageHelper.showError(
          context,
          response["message"] ?? "Login failed.",
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

      debugPrint('Login error: $e');

      AuthMessageHelper.showError(
        context,
        'Unable to sign in. Please check your email and password and try again.',
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
                      color: const Color(0xFF2E7D32).withOpacity(.10),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: const Color(0xFF2E7D32).withOpacity(.15),
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_open_rounded,
                      color: Color(0xFF2E7D32),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                Text(
                  "Welcome Back 👋",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: .3,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Sign in to continue managing your budgets,\nexpenses, savings and financial goals.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 40),

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
                                return "Please enter your password";
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
                              text: 'Login',
                              isLoading: isLoading,
                              onPressed: loginUser,
                            ),
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: const Text("Forgot Password?"),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Don't have an account?"),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  );
                                },
                                child: const Text("Create one"),
                              ),
                            ],
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
