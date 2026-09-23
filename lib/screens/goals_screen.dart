import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pesapulse_mobile/core/utils/currency_formatter.dart';

import '../services/session_service.dart';
import '../services/sync_events.dart';
import '../services/goals_service.dart';
import '../services/api_services.dart';

import '../widgets/goal_loading_skeleton.dart';
import '../widgets/empty_state_helper.dart';
import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';
import '../widgets/goals/goals_overview_card.dart';
import '../widgets/goals/goals_stats_grid.dart';
import '../widgets/goals/upcoming_deadlines_card.dart';
import '../widgets/goals/goal_list_item.dart';
import '../widgets/premium/premium_feature_card.dart';
import '../widgets/premium/premium_feature_guard.dart';

import '../subscription/controllers/subscription_controller.dart';
import '../subscription/models/premium_feature.dart';
import '../subscription/models/premium_payment_result.dart';

import 'add_goals_screen.dart';
import 'archived_goals_screen.dart';
import 'advanced_goal_tracking_screen.dart';
import 'goal_forecast_screen.dart';

import '../controllers/goals_controller.dart';

import '../utils/snackbar_helper.dart';
import '../exceptions/rate_limit_exception.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  bool isGuest = false;

  final GoalsService goalsService = GoalsService();

  late final GoalsController goalsController;

  final SubscriptionController subscriptionController =
      SubscriptionController();

  late VoidCallback _goalRefreshListener;

  final currency = NumberFormat.currency(
    locale: 'en_KE',
    symbol: 'KES ',
    decimalDigits: 0,
  );

  bool _cacheLoaded = false;

  bool _subscriptionLoading = false;
  bool _premiumCheckoutInProgress = false;
  bool _checkingPayment = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    goalsController = GoalsController(goalsService: goalsService);

    goalsController.addListener(_onGoalsControllerChanged);

    subscriptionController.addListener(_onSubscriptionChanged);

    _goalRefreshListener = () async {
      if (!mounted) return;

      if (goalsController.mutationInProgress) {
        debugPrint(
          'GoalsScreen: goal mutation is already refreshing the local cache. '
          'Skipping duplicate goals reload.',
        );
        return;
      }

      debugPrint(
        'GoalsScreen: synchronized/local goal data changed. '
        'Reloading from local cache only.',
      );

      try {
        await goalsController.reloadFromCache();
      } catch (e) {
        debugPrint('GoalsScreen: failed to reload goals from cache: $e');
      }
    };

    SyncEvents.instance.goalsRefresh.addListener(_goalRefreshListener);

    _initializeGoalsScreen();
  }

  // lifecycle callback

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _premiumCheckoutInProgress) {
      _verifyPremiumAfterPayment();
    }
  }

  // ============================================================
  // CONTROLLER LISTENER
  // ============================================================

  void _onGoalsControllerChanged() {
    if (!mounted) return;

    debugPrint(
      'GoalsScreen: controller notified. '
      'goals=${goalsController.goals.length}, '
      'ids=${goalsController.goals.map((g) => g.id).toList()}',
    );

    setState(() {});
  }

  void _onSubscriptionChanged() {
    if (!mounted) return;

    setState(() {});
  }

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<void> _initializeGoalsScreen({bool forceRefresh = false}) async {
    try {
      final guest = await SessionService.isGuest();

      if (!mounted) return;

      setState(() {
        isGuest = guest;
      });

      if (!guest) {
        // Start subscription verification immediately.
        _loadSubscription();
      }

      await goalsController.initialize(forceRefresh: forceRefresh);

      if (!mounted) return;

      setState(() {
        _cacheLoaded = true;
      });
    } on RateLimitException catch (e) {
      if (!mounted) return;

      SnackbarHelper.showRateLimited(
        context,
        message: e.message,
        remaining: e.remaining,
        retryAfter: e.retryAfter,
      );
    } catch (e) {
      debugPrint('Failed to initialize goals screen: $e');

      if (!mounted) return;

      if (goalsController.goals.isEmpty) {
        SnackbarHelper.showError(
          context,
          'Unable to load goals. Please try again.',
        );
      }
    }
  }

  // ============================================================
  // SUBSCRIPTION
  // ============================================================

  Future<void> _loadSubscription() async {
    if (isGuest) return;

    if (subscriptionController.state.isLoading) {
      return;
    }

    if (mounted) {
      setState(() {
        _subscriptionLoading = true;
      });
    }

    try {
      await subscriptionController.loadSubscription();
    } catch (e) {
      debugPrint('GoalsScreen: failed to load subscription: $e');
    } finally {
      if (!mounted) return;

      setState(() {
        _subscriptionLoading = false;
      });
    }
  }

  Future<void> _openPremiumCheckout() async {
    if (_premiumCheckoutInProgress) return;

    try {
      await subscriptionController.startPremiumCheckout();

      if (!mounted) return;

      setState(() {
        _premiumCheckoutInProgress = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Premium checkout opened. Complete your payment to unlock Premium.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      SnackbarHelper.showError(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _verifyPremiumAfterPayment() async {
    if (!mounted || _checkingPayment) return;

    setState(() {
      _checkingPayment = true;
    });

    try {
      final result = await subscriptionController.verifyPendingPayment();

      if (!mounted || result == null) return;

      switch (result.status) {
        case PremiumPaymentStatus.complete:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Payment confirmed. PesaPulse Premium is now active.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
          break;

        case PremiumPaymentStatus.failed:
          SnackbarHelper.showError(context, result.message);
          break;

        case PremiumPaymentStatus.pending:
        case PremiumPaymentStatus.processing:
          SnackbarHelper.showInfo(context, result.message);
          break;

        case PremiumPaymentStatus.unknown:
          SnackbarHelper.showError(context, result.message);
          break;
      }
    } catch (e) {
      debugPrint('GoalsScreen: Premium payment verification failed: $e');

      if (!mounted) return;

      SnackbarHelper.showError(
        context,
        'Unable to check your Premium payment status.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _checkingPayment = false;
          _premiumCheckoutInProgress = false;
        });
      }
    }
  }
  // ============================================================
  // ADVANCED GOAL TRACKING
  // ============================================================

  Future<void> _openAdvancedGoalTracking() async {
    final allowed = await PremiumFeatureGuard.check(
      context: context,
      feature: PremiumFeature.advancedGoalTracking,
      onUpgrade: _openPremiumCheckout,
    );

    if (!allowed || !mounted) return;

    try {
      final data = await ApiService.getAdvancedGoalTracking();

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdvancedGoalTrackingScreen(tracking: data),
        ),
      );
    } on RateLimitException catch (e) {
      if (!mounted) return;

      SnackbarHelper.showRateLimited(
        context,
        message: e.message,
        remaining: e.remaining,
        retryAfter: e.retryAfter,
      );
    } catch (e) {
      debugPrint('Advanced Goal Tracking failed: $e');

      if (!mounted) return;

      SnackbarHelper.showError(
        context,
        'Unable to load Advanced Goal Tracking. Please try again.',
      );
    }
  }

  // ============================================================
  // GOAL FORECAST
  // ============================================================

  Future<void> _openAdvancedGoalForecast() async {
    final allowed = await PremiumFeatureGuard.check(
      context: context,
      feature: PremiumFeature.advancedGoalForecast,
      onUpgrade: _openPremiumCheckout,
    );

    if (!allowed || !mounted) return;

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              GoalForecastScreen(key: const ValueKey('goalForecastScreen')),
        ),
      );
    } on RateLimitException catch (e) {
      if (!mounted) return;

      SnackbarHelper.showRateLimited(
        context,
        message: e.message,
        remaining: e.remaining,
        retryAfter: e.retryAfter,
      );
    } catch (e) {
      debugPrint('Goal Forecast failed: $e');

      if (!mounted) return;

      SnackbarHelper.showError(
        context,
        'Unable to load Goal Forecast. Please try again.',
      );
    }
  }

  // ============================================================
  // KEEP ALIVE
  // ============================================================

  @override
  bool get wantKeepAlive => true;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final goals = goalsController.goals;

    final screenSize = MediaQuery.of(context).size;

    final screenHeight = screenSize.height;

    final sectionSpacing = screenHeight * .035;

    // ----------------------------------------------------------
    // Show skeleton ONLY when there is genuinely no data yet.
    // ----------------------------------------------------------

    final showSkeleton =
        !_cacheLoaded && goalsController.isLoading && goals.isEmpty;

    if (showSkeleton) {
      return const GoalLoadingSkeleton();
    }

    return AppScaffold(
      appBar: const AdaptiveAppBar(title: null),

      // ========================================================
      // FAB
      // ========================================================
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "goalFab",
        elevation: 4,
        icon: const Icon(Icons.flag_outlined),
        label: const Text(
          "New Goal",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddGoalScreen()),
          );

          if (!mounted) return;

          if (result == true) {
            goalsController.markNeedsRefresh();

            await _initializeGoalsScreen(forceRefresh: true);
          }
        },
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: RefreshIndicator(
        onRefresh: () async {
          await _initializeGoalsScreen(forceRefresh: true);
        },

        child: goals.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 140),
                children: [
                  const SizedBox(height: 120),

                  buildEmptyState(
                    context,
                    EmptyStateType.goals,
                    isGuest: isGuest,
                  ),
                ],
              )
            : ListView(
                key: const PageStorageKey("goals"),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
                children: [
                  // ==================================================
                  // OVERVIEW
                  // ==================================================
                  GoalsOverviewCard(
                    totalGoals:
                        goalsController.goalAnalytics['total_goals'] ?? 0,
                    onArchivedGoals: () async {
                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ArchivedGoalsScreen(),
                        ),
                      );

                      if (!mounted) return;

                      if (changed == true) {
                        goalsController.markNeedsRefresh();

                        await _initializeGoalsScreen(forceRefresh: true);
                      }
                    },
                  ),

                  SizedBox(height: sectionSpacing),

                  // ==================================================
                  // STATISTICS
                  // ==================================================
                  GoalsStatsGrid(
                    totalGoals:
                        goalsController.goalAnalytics['total_goals'] ?? 0,
                    completedGoals:
                        goalsController.goalAnalytics['completed_goals'] ?? 0,
                    activeGoals:
                        goalsController.goalAnalytics['active_goals'] ?? 0,
                    completionRate:
                        (goalsController.goalAnalytics['completion_rate'] ?? 0)
                            .toDouble(),
                  ),

                  SizedBox(height: sectionSpacing),

                  // ==================================================
                  // UPCOMING DEADLINES
                  // ==================================================
                  UpcomingDeadlinesCard(
                    upcomingDeadlines: goalsController.upcomingDeadlines,
                  ),

                  // ==================================================
                  // PREMIUM ADVANCED GOAL TRACKING AND GOAL FORECAST
                  // ==================================================
                  if (!isGuest) ...[
                    SizedBox(height: sectionSpacing),

                    PremiumFeatureCard(
                      feature: PremiumFeature.advancedGoalTracking,
                      isPremium: subscriptionController.isPremium,
                      isLoading:
                          _subscriptionLoading ||
                          !subscriptionController.state.hasLoaded ||
                          _premiumCheckoutInProgress ||
                          _checkingPayment,
                      accentColor: Colors.amber,
                      onPressed: _openAdvancedGoalTracking,
                    ),

                    SizedBox(height: sectionSpacing),

                    PremiumFeatureCard(
                      feature: PremiumFeature.advancedGoalForecast,
                      isPremium: subscriptionController.isPremium,
                      isLoading:
                          _subscriptionLoading ||
                          !subscriptionController.state.hasLoaded ||
                          _premiumCheckoutInProgress ||
                          _checkingPayment,
                      accentColor: Colors.amber,
                      onPressed: _openAdvancedGoalForecast,
                    ),
                  ],

                  SizedBox(height: sectionSpacing),

                  // ==================================================
                  // GOAL LIST
                  // ==================================================
                  ...goals.map<Widget>(
                    (goal) => GoalListItem(
                      goal: goal,
                      goalsController: goalsController,
                      currency: CurrencyFormatter.format,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    SyncEvents.instance.goalsRefresh.removeListener(_goalRefreshListener);

    goalsController.removeListener(_onGoalsControllerChanged);

    subscriptionController.removeListener(_onSubscriptionChanged);

    subscriptionController.dispose();

    goalsController.dispose();

    super.dispose();
  }
}
