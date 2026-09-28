import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_screen.dart';
import 'auth_choice_screen.dart';
import 'home_screen.dart';

import '../services/api_services.dart';
import '../services/session_service.dart';
import '../services/sync_service.dart';
import '../utils/responsive_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();

    checkLoginStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> checkLoginStatus() async {
    final startupStart = DateTime.now();

    final prefs = await SharedPreferences.getInstance();

    final String? token = prefs.getString('token');

    final bool hasCompletedOnboarding =
        prefs.getBool('hasCompletedOnboarding') ?? false;

    final bool isGuest = await SessionService.isGuest();

    // Keep the splash visible long enough for the branding
    // animation to be perceived without forcing a long delay.
    const minimumSplashDuration = Duration(milliseconds: 1400);

    final elapsed = DateTime.now().difference(startupStart);

    if (elapsed < minimumSplashDuration) {
      await Future.delayed(minimumSplashDuration - elapsed);
    }

    if (!mounted) return;

    // ------------------------------------------------------------
    // 1. Authenticated user
    // ------------------------------------------------------------

    if (token != null && token.isNotEmpty) {
      ApiService.token = token;

      await SyncService.instance.startListening();

      if (!mounted) return;

      _navigateTo(const HomeScreen());

      return;
    }

    // ------------------------------------------------------------
    // 2. Guest user
    // ------------------------------------------------------------

    if (isGuest) {
      _navigateTo(const HomeScreen());

      return;
    }

    // ------------------------------------------------------------
    // 3. First-time user
    // ------------------------------------------------------------

    if (!hasCompletedOnboarding) {
      _navigateTo(const OnboardingScreen());

      return;
    }

    // ------------------------------------------------------------
    // 4. No active session
    // ------------------------------------------------------------

    _navigateTo(const AuthChoiceScreen());
  }

  void _navigateTo(Widget screen) {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, secondaryAnimation) => screen,
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isCompact = ResponsiveHelper.useCompactLayout(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    final screenHeight = ResponsiveHelper.height(context);

    final logoSize = isDesktop
        ? 128.0
        : isTablet
        ? 112.0
        : isCompact
        ? 88.0
        : 104.0;

    final titleSize = isDesktop
        ? 40.0
        : isTablet
        ? 36.0
        : isCompact
        ? 30.0
        : 34.0;

    final verticalSpacing = isLandscape
        ? 14.0
        : isCompact
        ? 18.0
        : 24.0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveHelper.horizontalPadding(context),
              vertical: isLandscape ? 16 : 24,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop
                        ? 520
                        : isTablet
                        ? 460
                        : 400,
                    minHeight: isLandscape ? screenHeight - 32 : 0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ------------------------------------------------
                      // Logo
                      // ------------------------------------------------
                      Container(
                        width: logoSize,
                        height: logoSize,
                        padding: EdgeInsets.all(isCompact ? 12 : 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(
                            isCompact ? 24 : 30,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withOpacity(.10),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/icon/pesapulse_icon.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.account_balance_wallet_rounded,
                              size: logoSize * .55,
                              color: theme.colorScheme.primary,
                            );
                          },
                        ),
                      ),

                      SizedBox(height: verticalSpacing),

                      // ------------------------------------------------
                      // App name
                      // ------------------------------------------------
                      Text(
                        'PesaPulse',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.0,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ------------------------------------------------
                      // Tagline
                      // ------------------------------------------------
                      Text(
                        'Take control of your money.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),

                      SizedBox(height: isLandscape ? 20 : 32),

                      // ------------------------------------------------
                      // Loading indicator
                      // ------------------------------------------------
                      SizedBox(
                        width: isCompact ? 28 : 32,
                        height: isCompact ? 28 : 32,
                        child: CircularProgressIndicator(
                          strokeWidth: isCompact ? 2.5 : 3,
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        'Preparing your finances...',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            .75,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
