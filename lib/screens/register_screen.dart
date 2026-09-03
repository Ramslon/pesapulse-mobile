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
import '../exceptions/auth_exception.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;

  String loadingMessage = '';

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
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text;
    final passwordConfirmation = confirmPasswordController.text;

    _setLoading('Creating your account...');

    try {
      // ------------------------------------------------------------
      // STEP 1: Register the user.
      // ------------------------------------------------------------

      final response = await ApiService.registerUser(
        name,
        email,
        password,
        passwordConfirmation,
      );

      // ------------------------------------------------------------
      // STEP 2: Validate registration response.
      // ------------------------------------------------------------

      final token = response['token'];
      final user = response['user'];

      if (token is! String ||
          token.isEmpty ||
          user is! Map<String, dynamic> ||
          user['id'] == null) {
        throw AuthException(
          message: 'Invalid registration response from server.',
        );
      }

      final userId = user['id'].toString();

      // ------------------------------------------------------------
      // STEP 3: Create authenticated session.
      // ------------------------------------------------------------

      await SessionService.loginUser(userId, token);

      ApiService.token = token;

      // ------------------------------------------------------------
      // STEP 4: Migrate any existing guest data.
      //
      // IMPORTANT:
      // SyncService is intentionally NOT started yet.
      // This prevents the old guest sync queue from being replayed
      // before migration clears it.
      // ------------------------------------------------------------

      bool migrationFailed = false;

      try {
        _setLoading('Migrating your guest data...');

        final migrationResult = await MigrationService.instance
            .migrateGuestData(userId);

        if (migrationResult.migrated) {
          debugPrint(
            'Guest migration completed successfully: '
            '${migrationResult.recordCount} records.',
          );
        } else {
          debugPrint('No guest data found to migrate.');
        }
      } on RateLimitException catch (e) {
        migrationFailed = true;

        debugPrint(
          'Guest data migration rate limited: '
          'message=${e.message}, '
          'remaining=${e.remaining}, '
          'retryAfter=${e.retryAfter}',
        );

        if (mounted) {
          AuthMessageHelper.showRateLimited(
            context,
            message: e.message,
            remaining: e.remaining,
            retryAfter: e.retryAfter,
          );
        }

        // Registration succeeded.
        // Do NOT return.
      } on AuthException catch (e) {
        migrationFailed = true;

        debugPrint('Guest data migration authentication error: ${e.message}');

        if (mounted) {
          AuthMessageHelper.showError(
            context,
            'Account created successfully, but your guest data '
            'could not be migrated. You can continue using your account.',
          );
        }

        // Registration succeeded.
        // Do NOT return.
      } catch (e) {
        migrationFailed = true;

        debugPrint('Guest data migration failed: $e');

        if (mounted) {
          AuthMessageHelper.showError(
            context,
            'Account created successfully, but your guest data '
            'could not be migrated. You can continue using your account.',
          );
        }

        // Registration succeeded.
        // Do NOT return.
      }

      // ------------------------------------------------------------
      // STEP 5: Start synchronization.
      //
      // This happens AFTER migration has either:
      //
      //   - completed successfully and cleared the guest queue, or
      //   - failed and the user is allowed to continue.
      //
      // SyncService can now operate under the authenticated session.
      // ------------------------------------------------------------

      if (!mounted) return;

      // ------------------------------------------------------------
      // STEP 6: Continue to the application.
      // ------------------------------------------------------------

      _setLoading('Opening your account...');

      // Only show the normal success message when migration did not
      // produce an error message.
      if (!migrationFailed) {
        AuthMessageHelper.showSuccess(context, 'Account created successfully!');
      }

      // Start authenticated synchronization after the migration
      // attempt. SyncService only processes the authenticated
      // user's queue, never the guest queue.
      await SyncService.instance.startListening();

      await Future.delayed(const Duration(milliseconds: 700));

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on RateLimitException catch (e) {
      // ------------------------------------------------------------
      // Registration itself was rate limited.
      // ------------------------------------------------------------

      if (!mounted) return;

      AuthMessageHelper.showRateLimited(
        context,
        message: e.message,
        remaining: e.remaining,
        retryAfter: e.retryAfter,
      );
    } on AuthException catch (e) {
      // ------------------------------------------------------------
      // Registration/authentication error.
      // ------------------------------------------------------------

      if (!mounted) return;

      debugPrint('Registration authentication error: ${e.message}');

      AuthMessageHelper.showError(context, e.message);
    } catch (e) {
      // ------------------------------------------------------------
      // Unexpected registration error.
      // ------------------------------------------------------------

      if (!mounted) return;

      debugPrint('Registration error: $e');

      AuthMessageHelper.showError(
        context,
        'Unable to create your account. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          loadingMessage = '';
        });
      }
    }
  }

  void _setLoading(String message) {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      loadingMessage = message;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
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

                              if (value.trim().length > 255) {
                                return "Name must be 255 characters or less";
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

                              if (!RegExp(r'[A-Z]').hasMatch(value)) {
                                return "Password must contain an uppercase letter";
                              }

                              if (!RegExp(r'[a-z]').hasMatch(value)) {
                                return "Password must contain a lowercase letter";
                              }

                              if (!RegExp(r'[0-9]').hasMatch(value)) {
                                return "Password must contain a number";
                              }

                              if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
                                return "Password must contain a symbol";
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
                              if (value == null || value.isEmpty) {
                                return "Please confirm your password";
                              }

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
                              text: "Create Account",
                              isLoading: isLoading,
                              onPressed: registerUser,
                            ),
                          ),

                          if (isLoading && loadingMessage.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              loadingMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],

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
