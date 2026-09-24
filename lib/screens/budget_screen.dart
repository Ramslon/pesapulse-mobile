import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pesapulse_mobile/widgets/budget_alert_card.dart';
import '../widgets/budget/budget_overview_card.dart';
import '../widgets/budget/budget_breakdown_card.dart';
import '../widgets/budget/spending_analytics_section.dart';
import '../widgets/budget/financial_health_section.dart';
import '../widgets/budget/budget_header.dart';
import '../widgets/budget/budget_status_bar.dart';
import '../widgets/empty_state_helper.dart';
import '../widgets/budget_loading_skeleton.dart';
import '../widgets/budget/budget_section_header.dart';
import '../widgets/budget/budget_fab.dart';
import '../widgets/budget_dialog.dart';
import '../widgets/delete_budget_dialog.dart';
import '../widgets/budget/budget_stats_grid.dart';

import '../repositories/budget_repository.dart';
import '../repositories/financial_insights_repository.dart';
import '../features/budget/controllers/budget_controller.dart';
import '../features/budget/utils/budget_calculator.dart';
import '../features/budget/models/budget_state.dart';

import '../exceptions/rate_limit_exception.dart';

import '../providers/connectivity_provider.dart';
import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';
import '../utils/responsive_helper.dart';
import '../utils/snackbar_helper.dart';

import '../widgets/premium/premium_feature_card.dart';
import '../widgets/premium/premium_feature_guard.dart';
import '../subscription/models/premium_feature.dart';
import '../subscription/controllers/subscription_controller.dart';
import '../subscription/models/premium_payment_result.dart';

import '../screens/advanced_budget_insights_screen.dart';
import '../screens/budget_simulation_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  BudgetScreenState createState() => BudgetScreenState();
}

class BudgetScreenState extends State<BudgetScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final BudgetController controller = BudgetController(
    budgetRepository: BudgetRepository(),
    insightsRepository: FinancialInsightsRepository(),
  );

  BudgetState state = const BudgetState();

  final TextEditingController budgetController = TextEditingController();

  final SubscriptionController subscriptionController =
      SubscriptionController();

  bool _subscriptionLoading = true;
  bool _premiumCheckoutInProgress = false;
  bool _checkingPayment = false;

  late ConnectivityProvider _network;

  bool? _wasOnline;
  bool _premiumPaymentVerificationPending = false;

  double get percentageUsed =>
      BudgetCalculator.percentageUsed(budget: state.budget, spent: state.spent);

  double get remainingAmount =>
      BudgetCalculator.remaining(budget: state.budget, spent: state.spent);

  int get daysRemaining => BudgetCalculator.daysRemaining();

  Color get statusColor =>
      BudgetCalculator.statusColor(context, state.budgetStatus);

  String get statusText => BudgetCalculator.statusText(state.budgetStatus);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _network = context.read<ConnectivityProvider>();
    _wasOnline = _network.isOnline;

    _network.addListener(_onConnectivityChanged);

    subscriptionController.addListener(_onSubscriptionChanged);

    loadBudget();
  }

  // Lifecycle callback
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    final shouldVerify =
        _premiumCheckoutInProgress || _premiumPaymentVerificationPending;

    if (!shouldVerify) {
      return;
    }

    if (!_network.isOnline) {
      if (!mounted) return;

      setState(() {
        _premiumCheckoutInProgress = false;
      });

      SnackbarHelper.showInfo(
        context,
        subscriptionController.hasPremiumAccess
            ? 'Premium is unlocked. Reconnect to verify any recent payment.'
            : 'Reconnect to verify your Premium payment.',
      );

      return;
    }

    _verifyPremiumAfterPayment();
  }

  void _onSubscriptionChanged() {
    if (!mounted) return;

    setState(() {});
  }

  void _onConnectivityChanged() {
    final isOnline = _network.isOnline;
    final wasOnline = _wasOnline;

    _wasOnline = isOnline;

    if (!mounted) return;

    if (!isOnline) {
      debugPrint('BudgetScreen: device is offline.');
      return;
    }

    if (wasOnline == false && isOnline) {
      debugPrint('BudgetScreen: connectivity restored.');

      if (state.isGuest) {
        return;
      }

      // A pending payment verification already refreshes the
      // subscription when payment is confirmed, so avoid starting
      // a second subscription refresh at the same time.
      if (_premiumPaymentVerificationPending) {
        _verifyPremiumAfterPayment();
      } else {
        _loadSubscription(forceRefresh: true);
      }
    }
  }

  Future<void> refreshBudget() async {
    await loadBudget();
  }

  Future<void> loadBudget() async {
    try {
      final newState = await controller.loadAll();

      if (!mounted) return;

      setState(() {
        state = newState;

        budgetController.text = state.budget.toStringAsFixed(0);
      });

      await _loadSubscription();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        state = state.copyWith(isLoading: false, hasCachedBudget: false);
      });

      await _loadSubscription();
    }
  }

  Future<void> _loadSubscription({bool forceRefresh = false}) async {
    if (state.isGuest) {
      if (!mounted) return;

      setState(() {
        _subscriptionLoading = false;
      });

      return;
    }

    if (_subscriptionLoading && !forceRefresh) {
      return;
    }

    // Offline: restore the last server-confirmed entitlement.
    if (!_network.isOnline) {
      await subscriptionController.restoreOfflinePremiumAccess();

      debugPrint(
        'BudgetScreen: offline subscription restored. '
        'hasPremiumAccess=${subscriptionController.hasPremiumAccess}',
      );

      if (!mounted) return;

      setState(() {
        _subscriptionLoading = false;
      });

      return;
    }

    if (mounted) {
      setState(() {
        _subscriptionLoading = true;
      });
    }

    try {
      await subscriptionController.loadSubscription(forceRefresh: forceRefresh);

      debugPrint(
        'BudgetScreen: subscription refreshed. '
        'isPremium=${subscriptionController.isPremium}',
      );
    } catch (e) {
      debugPrint('BudgetScreen: failed to load subscription: $e');

      // If connectivity disappeared during the request,
      // fall back to the locally cached entitlement.
      if (!_network.isOnline) {
        await subscriptionController.restoreOfflinePremiumAccess();
      }
    } finally {
      if (mounted) {
        setState(() {
          _subscriptionLoading = false;
        });
      }
    }
  }

  Future<void> _openPremiumCheckout() async {
    if (_premiumCheckoutInProgress) return;

    if (!_network.isOnline) {
      if (!mounted) return;

      SnackbarHelper.showInfo(
        context,
        'You are offline. Reconnect to purchase PesaPulse Premium.',
      );

      return;
    }

    setState(() {
      _premiumCheckoutInProgress = true;
      _premiumPaymentVerificationPending = false;
    });

    try {
      await subscriptionController.startPremiumCheckout();

      _premiumPaymentVerificationPending = true;

      if (!mounted) return;

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

      setState(() {
        _premiumCheckoutInProgress = false;
        _premiumPaymentVerificationPending = false;
      });

      SnackbarHelper.showError(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _verifyPremiumAfterPayment() async {
    if (!mounted || _checkingPayment) return;

    if (!_network.isOnline) {
      if (mounted) {
        setState(() {
          _premiumCheckoutInProgress = false;
        });

        SnackbarHelper.showInfo(
          context,
          subscriptionController.hasPremiumAccess
              ? 'Premium is already unlocked. Reconnect to verify your payment.'
              : 'Payment status cannot be verified while offline. Reconnect and try again.',
        );
      }

      return;
    }

    setState(() {
      _checkingPayment = true;
    });

    try {
      final result = await subscriptionController.verifyPendingPayment();

      if (!mounted || result == null) {
        return;
      }

      switch (result.status) {
        case PremiumPaymentStatus.complete:
          _premiumPaymentVerificationPending = false;

          await subscriptionController.cacheCurrentPremiumAccess();

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
          _premiumPaymentVerificationPending = false;

          SnackbarHelper.showError(context, result.message);
          break;

        case PremiumPaymentStatus.pending:
        case PremiumPaymentStatus.processing:
          _premiumPaymentVerificationPending = true;

          SnackbarHelper.showInfo(context, result.message);
          break;

        case PremiumPaymentStatus.unknown:
          _premiumPaymentVerificationPending = true;

          SnackbarHelper.showError(context, result.message);
          break;
      }
    } catch (e) {
      debugPrint('BudgetScreen: Premium payment verification failed: $e');

      _premiumPaymentVerificationPending = true;

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

  Future<bool> _checkPremiumFeatureAccess(PremiumFeature feature) async {
    if (!_network.isOnline) {
      if (!mounted) return false;

      if (subscriptionController.hasPremiumAccess) {
        SnackbarHelper.showInfo(
          context,
          'Premium is unlocked, but this feature requires an internet connection.',
        );
      } else {
        SnackbarHelper.showInfo(
          context,
          'You are offline. Reconnect to check Premium access.',
        );
      }

      return false;
    }

    return PremiumFeatureGuard.check(
      context: context,
      feature: feature,
      onUpgrade: _openPremiumCheckout,
    );
  }

  Future<void> _openAdvancedBudgetInsights() async {
    final allowed = await _checkPremiumFeatureAccess(
      PremiumFeature.advancedBudgetInsights,
    );

    if (!allowed || !mounted) return;
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdvancedBudgetInsightsScreen()),
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
      debugPrint('Advanced Budget Insights failed: $e');

      if (!mounted) return;

      SnackbarHelper.showError(
        context,
        'Unable to load Advanced Budget Insights. Please try again.',
      );
    }
  }

  Future<void> _openBudgetSimulation() async {
    final allowed = await _checkPremiumFeatureAccess(
      PremiumFeature.budgetSimulation,
    );

    if (!allowed || !mounted) return;
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BudgetSimulationScreen()),
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
      debugPrint('Budget Simulation failed: $e');

      if (!mounted) return;

      SnackbarHelper.showError(
        context,
        'Unable to load Budget Simulation. Please try again.',
      );
    }
  }

  Widget _buildAdvancedBudgetFeature() {
    return PremiumFeatureCard(
      feature: PremiumFeature.advancedBudgetInsights,
      isPremium: subscriptionController.hasPremiumAccess,
      isLoading:
          _subscriptionLoading ||
          _premiumCheckoutInProgress ||
          _checkingPayment,
      accentColor: Colors.blue,
      onPressed: _openAdvancedBudgetInsights,
    );
  }

  Widget _buildAdvancedBudgetSimulation() {
    return PremiumFeatureCard(
      feature: PremiumFeature.budgetSimulation,
      isPremium: subscriptionController.hasPremiumAccess,
      isLoading:
          _subscriptionLoading ||
          _premiumCheckoutInProgress ||
          _checkingPayment,
      accentColor: Colors.blue,
      onPressed: _openBudgetSimulation,
    );
  }

  Future<void> saveBudget() async {
    final network = context.read<ConnectivityProvider>();

    if (budgetController.text.trim().isEmpty) {
      SnackbarHelper.showError(context, "Please enter a budget amount");
      return;
    }

    final amount = double.tryParse(budgetController.text.trim());

    if (amount == null || amount <= 0) {
      SnackbarHelper.showError(context, "Budget must be greater than zero");
      return;
    }

    network.setSyncing(true);

    try {
      final isUpdate = state.budget > 0;

      final newState = await controller.saveBudget(amount: amount);

      if (!mounted) return;

      setState(() {
        state = newState;
        budgetController.text = state.budget.toStringAsFixed(0);
      });

      SnackbarHelper.showSuccess(
        context,
        isUpdate
            ? "Budget updated successfully"
            : "Budget created successfully",
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
      debugPrint('Save budget failed: $e');

      if (!mounted) return;

      SnackbarHelper.showError(context, "Failed to save budget.");
    } finally {
      network.setSyncing(false);
    }
  }

  Future<void> refreshBudgetData() async {
    final network = context.read<ConnectivityProvider>();

    if (!network.isOnline) {
      await loadBudget();

      if (!mounted) return;

      SnackbarHelper.showInfo(
        context,
        "Offline mode • Showing cached budget data.",
      );

      return;
    }

    await loadBudget();
  }

  Future<void> deleteBudget() async {
    try {
      final newState = await controller.deleteBudget();

      if (!mounted) return;

      setState(() {
        state = newState;
        budgetController.clear();
      });

      SnackbarHelper.showSuccess(context, "Budget deleted successfully");
    } on RateLimitException catch (e) {
      if (!mounted) return;

      SnackbarHelper.showRateLimited(
        context,
        message: e.message,
        remaining: e.remaining,
        retryAfter: e.retryAfter,
      );
    } catch (e) {
      if (!mounted) return;

      SnackbarHelper.showError(context, "Error deleting budget: $e");
    }
  }

  Future<void> confirmDeleteBudget() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => const DeleteBudgetDialog(),
    );

    if (shouldDelete == true) {
      await deleteBudget();
    }
  }

  Future<void> showCreateBudgetDialog() async {
    budgetController.text = state.budget > 0
        ? state.budget.toStringAsFixed(0)
        : '';

    await showDialog(
      context: context,
      builder: (_) => BudgetDialog(
        controller: budgetController,
        hasBudget: state.budget > 0,
        isSyncing: context.read<ConnectivityProvider>().isSyncing,
        onSave: saveBudget,
        onDelete: confirmDeleteBudget,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _network.removeListener(_onConnectivityChanged);

    subscriptionController.removeListener(_onSubscriptionChanged);
    subscriptionController.dispose();

    budgetController.dispose();

    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);

    final spacing = ResponsiveHelper.spacing(context);

    final cardPadding = ResponsiveHelper.cardPadding(context);

    final network = context.watch<ConnectivityProvider>();

    return AppScaffold(
      appBar: const AdaptiveAppBar(title: null),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      floatingActionButton: state.isLoading || state.budget <= 0
          ? null
          : BudgetFAB(
              hasBudget: state.budget > 0,
              onPressed: showCreateBudgetDialog,
            ),

      body: _buildBody(
        context,
        compact: compact,
        landscape: landscape,
        desktop: desktop,
        sectionSpacing: sectionSpacing,
        spacing: spacing,
        cardPadding: cardPadding,
        network: network,
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required bool compact,
    required bool landscape,
    required bool desktop,
    required double sectionSpacing,
    required double spacing,
    required double cardPadding,
    required ConnectivityProvider network,
  }) {
    if (state.isLoading) {
      return const BudgetLoadingSkeleton();
    }

    if (state.budget <= 0) {
      return Center(
        child: buildEmptyState(
          context,
          EmptyStateType.budget,
          isOnline: network.isOnline,
          isGuest: state.isGuest,
          refreshBudgetData: refreshBudgetData,
          showCreateBudgetDialog: showCreateBudgetDialog,
        ),
      );
    }

    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final mediaQuery = MediaQuery.of(context);

    final bottomSafeArea = mediaQuery.padding.bottom;

    /*
     * Give the final content enough clearance to scroll
     * completely above the floating action button.
     */
    final fabClearance = landscape && !desktop
        ? 120.0
        : compact
        ? 180.0
        : 190.0;

    final bottomContentPadding = fabClearance + bottomSafeArea;

    return RefreshIndicator(
      onRefresh: refreshBudgetData,
      child: SingleChildScrollView(
        key: const PageStorageKey("budget"),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          compact ? 8 : 12,
          horizontalPadding,
          bottomContentPadding + bottomSafeArea,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: ResponsiveHelper.contentMaxWidth(context),
              minWidth: 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BudgetHeader(),

                SizedBox(height: compact ? 10 : 14),

                BudgetStatsGrid(
                  spent: state.spent,
                  remaining: remainingAmount,
                  percentageUsed: percentageUsed,
                  daysRemaining: daysRemaining,
                  statusColor: statusColor,
                ),

                SizedBox(height: sectionSpacing),

                BudgetStatusBar(
                  statusText: statusText,
                  statusColor: statusColor,
                ),

                SizedBox(height: sectionSpacing),

                const BudgetSectionHeader(
                  title: "Monthly Budget Overview",
                  subtitle:
                      "Track your monthly spending and stay within budget",
                ),

                SizedBox(height: compact ? 10 : spacing),

                _buildOverviewSection(
                  context,
                  compact: compact,
                  landscape: landscape,
                  sectionSpacing: sectionSpacing,
                ),

                SizedBox(height: sectionSpacing),

                _buildAnalyticsSection(
                  context,
                  compact: compact,
                  landscape: landscape,
                  sectionSpacing: sectionSpacing,
                  cardPadding: cardPadding,
                ),

                // Premium Budget Intelligence
                // Only authenticated users see this feature.
                if (!state.isGuest) ...[
                  SizedBox(height: sectionSpacing),

                  _buildAdvancedBudgetFeature(),

                  SizedBox(height: sectionSpacing),

                  _buildAdvancedBudgetSimulation(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewSection(
    BuildContext context, {
    required bool compact,
    required bool landscape,
    required double sectionSpacing,
  }) {
    final overviewCard = BudgetOverviewCard(
      budget: state.budget,
      spent: state.spent,
      remaining: remainingAmount,
      percentageUsed: percentageUsed,
      statusColor: statusColor,
    );

    final breakdownCard = BudgetBreakdownCard(
      categoryTotals: state.categoryTotals,
      totalSpent: state.spent,
    );

    /*
     * ResponsiveHelper controls the overall breakpoint logic.
     *
     * On landscape layouts, the overview and breakdown
     * cards are placed side-by-side.
     */
    if (landscape) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: overviewCard),

          SizedBox(width: compact ? 12 : 20),

          Expanded(flex: 6, child: breakdownCard),
        ],
      );
    }

    return Column(
      children: [
        overviewCard,

        SizedBox(height: sectionSpacing),

        breakdownCard,
      ],
    );
  }

  Widget _buildAnalyticsSection(
    BuildContext context, {
    required bool compact,
    required bool landscape,
    required double sectionSpacing,
    required double cardPadding,
  }) {
    final analytics = SpendingAnalyticsSection(
      dailySpending: state.dailySpending,
      highestDay: state.highestDay,
      highestDayAmount: state.highestDayAmount,
      averageDaily: state.averageDaily,
      estimatedMonthEnd: state.estimatedMonthEnd,
    );

    final health = FinancialHealthSection(
      financialScore: state.financialScore,
      financialLabel: state.financialLabel,
      percentageUsed: percentageUsed,
      budget: state.budget,
      spent: state.spent,

      budgetAlert: BudgetAlertCard(
        budgetStatus: state.budgetStatus,
        budget: state.budget,
        percentageUsed: percentageUsed,
        recommendation: state.recommendation,
      ),

      categoryAdvice: state.categoryAdvice,
    );

    /*
     * Landscape:
     * Analytics gets slightly more width than
     * Financial Health because the analytics content
     * is usually more data-dense.
     */
    if (landscape) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: analytics),

          SizedBox(width: compact ? 12 : 20),

          Expanded(flex: 5, child: health),
        ],
      );
    }

    return Column(
      children: [
        analytics,

        SizedBox(height: sectionSpacing),

        health,
      ],
    );
  }
}
