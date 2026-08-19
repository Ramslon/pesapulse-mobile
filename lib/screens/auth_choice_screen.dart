import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'register_screen.dart';
import 'home_screen.dart';

import '../repositories/settings_repository.dart';
import '../services/session_service.dart';
import '../services/settings_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/auth_message_helper.dart';

class AuthChoiceScreen extends StatefulWidget {
  final bool fromOnboarding;

  const AuthChoiceScreen({super.key, this.fromOnboarding = false});

  @override
  State<AuthChoiceScreen> createState() => _AuthChoiceScreenState();
}

class _AuthChoiceScreenState extends State<AuthChoiceScreen> {
  final SettingsRepository settingsRepository = SettingsRepository();

  bool isGuestLoading = false;

  Future<void> continueAsGuest() async {
    if (isGuestLoading) return;

    setState(() {
      isGuestLoading = true;
    });

    try {
      // ------------------------------------------------------------
      // STEP 1: Clear settings/cache from any previous session.
      // ------------------------------------------------------------

      settingsRepository.clearCache();

      await SettingsService.clearUserSettings();

      // ------------------------------------------------------------
      // STEP 2: Start the guest session.
      // ------------------------------------------------------------

      await SessionService.loginAsGuest();

      if (!mounted) return;

      // ------------------------------------------------------------
      // STEP 3: Enter the application.
      // ------------------------------------------------------------

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      AuthMessageHelper.showError(
        context,
        'Unable to start guest mode. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isGuestLoading = false;
        });
      }
    }
  }

  void openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void openRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
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

                // --------------------------------------------------
                // Back button
                // --------------------------------------------------
                if (widget.fromOnboarding)
                  IconButton(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),

                const SizedBox(height: 30),

                // --------------------------------------------------
                // PesaPulse icon
                // --------------------------------------------------
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(.25),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // --------------------------------------------------
                // Heading
                // --------------------------------------------------
                Center(
                  child: Text(
                    "Welcome to PesaPulse 👋",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: .3,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Center(
                  child: Text(
                    "Choose how you'd like to continue.\n"
                    "Sign in to your account or start\n"
                    "managing your finances as a guest.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                ),

                const SizedBox(height: 38),

                // --------------------------------------------------
                // Authentication options
                // --------------------------------------------------
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // ------------------------------------------------
                        // Sign In
                        // ------------------------------------------------
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: CustomButton(
                            text: 'Sign In',
                            isLoading: false,
                            onPressed: openLogin,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ------------------------------------------------
                        // OR divider
                        // ------------------------------------------------
                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ------------------------------------------------
                        // Continue as Guest
                        // ------------------------------------------------
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton.icon(
                            onPressed: isGuestLoading ? null : continueAsGuest,
                            icon: isGuestLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.travel_explore_rounded),
                            label: Text(
                              isGuestLoading
                                  ? 'Starting Guest Mode...'
                                  : 'Continue as Guest',
                            ),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          "You can create an account later and "
                          "transfer your guest data.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 22),

                        // ------------------------------------------------
                        // Sign Up
                        // ------------------------------------------------
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account?"),
                            TextButton(
                              onPressed: openRegister,
                              child: const Text("Sign Up"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
