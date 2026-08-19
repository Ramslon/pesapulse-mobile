import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_screen.dart';
import 'auth_choice_screen.dart';
import 'home_screen.dart';

import '../services/api_services.dart';
import '../services/session_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();

    final String? token = prefs.getString('token');

    final bool hasCompletedOnboarding =
        prefs.getBool('hasCompletedOnboarding') ?? false;

    final bool isGuest = await SessionService.isGuest();

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // ------------------------------------------------------------
    // 1. Authenticated user
    // ------------------------------------------------------------

    if (token != null && token.isNotEmpty) {
      ApiService.token = token;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );

      return;
    }

    // ------------------------------------------------------------
    // 2. Guest user
    // ------------------------------------------------------------

    if (isGuest) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );

      return;
    }

    // ------------------------------------------------------------
    // 3. First-time user
    // ------------------------------------------------------------

    if (!hasCompletedOnboarding) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );

      return;
    }

    // ------------------------------------------------------------
    // 4. No active session
    // ------------------------------------------------------------

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthChoiceScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet, size: 100),

            const SizedBox(height: 20),

            const Text(
              'PesaPulse',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
