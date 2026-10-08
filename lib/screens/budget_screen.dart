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
  // ---------------------------------------------------------------------------
  // CONTROLLERS / REPOSITORIES
  // ---------------------------------------------------------------------------

  final BudgetController controller = BudgetController(
    budgetRepository: BudgetRepository(),
    insightsRepository: FinancialInsightsRepository(),
  );

  BudgetState state = const BudgetState();

  final TextEditingController budgetController = TextEditingController();

  final SubscriptionController subscriptionController =
      SubscriptionController();

  // ---------------------------------------------------------------------------
  // PREMIUM STATE
  // ---------------------------------------------------------------------------

  bool _subscriptionLoading = false;
  bool _premiumCheckoutInProgress = false;
  bool _checkingPayment = false;

  bool _premiumPaymentVerificationPending = false;

  // ---------------------------------------------------------------------------
  // CONNECTIVITY
  // ---------------------------------------------------------------------------

  late ConnectivityProvider _network;

  bool? _wasOnline;

  // ---------------------------------------------------------------------------
  // SELECTED BUDGET PERIOD
  // ---------------------------------------------------------------------------

  DateTime _selectedBudgetPeriod = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  bool get _isCurrentBudgetPeriod {
    final now = DateTime.now();

    return _selectedBudgetPeriod.year == now.year &&
        _selectedBudgetPeriod.month == now.month;
  }

  String get _selectedBudgetPeriodLabel {
    return _formatBudgetPeriod(_selectedBudgetPeriod);
  }

  // ---------------------------------------------------------------------------
  // BUDGET CALCULATIONS
  // ---------------------------------------------------------------------------

  double get percentageUsed =>
      BudgetCalculator.percentageUsed(budget: state.budget, spent: state.spent);

  double get remainingAmount =>
      BudgetCalculator.remaining(budget: state.budget, spent: state.spent);

  int get daysRemaining {
    // Historical periods are already completed.
    //
    // Returning zero is more meaningful than showing the number
    // of days remaining in the current month.
    if (!_isCurrentBudgetPeriod) {
      return 0;
    }

    return BudgetCalculator.daysRemaining();
  }

  Color get statusColor =>
      BudgetCalculator.statusColor(context, state.budgetStatus);

  String get statusText => BudgetCalculator.statusText(state.budgetStatus);

  // ---------------------------------------------------------------------------
  // PREMIUM CARD LOADING
  // ---------------------------------------------------------------------------

  bool get _premiumCardLoading =>
      _premiumCheckoutInProgress ||
      _checkingPayment ||
      (_subscriptionLoading && !subscriptionController.hasPremiumAccess);

  // ---------------------------------------------------------------------------
  // INIT
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // APP LIFECYCLE
  // ---------------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState != AppLifecycleState.resumed) {
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

  // ---------------------------------------------------------------------------
  // SUBSCRIPTION
  // ---------------------------------------------------------------------------

  void _onSubscriptionChanged() {
    if (!mounted) return;

    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // CONNECTIVITY
  // ---------------------------------------------------------------------------

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

      if (_premiumPaymentVerificationPending) {
        _verifyPremiumAfterPayment();
      } else {
        _loadSubscription(forceRefresh: true);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // LOAD SELECTED BUDGET PERIOD
  // ---------------------------------------------------------------------------

  Future<void> refreshBudget() async {
    await loadBudget();
  }

  Future<void> loadBudget() async {
    final month = _selectedBudgetPeriod.month;
    final year = _selectedBudgetPeriod.year;

    debugPrint(
      'BudgetScreen: loading budget '
      '$year-${month.toString().padLeft(2, '0')}',
    );

    try {
      final newState = await controller.loadAll(month: month, year: year);

      if (!mounted) return;

      setState(() {
        state = newState;

        budgetController.text = state.budget > 0
            ? state.budget.toStringAsFixed(0)
            : '';
      });

      await _loadSubscription();
    } catch (error) {
      debugPrint('BudgetScreen: failed to load budget: $error');

      if (!mounted) return;

      setState(() {
        state = state.copyWith(isLoading: false, hasCachedBudget: false);
      });

      await _loadSubscription();
    }
  }

  // ---------------------------------------------------------------------------
  // SUBSCRIPTION LOADING
  // ---------------------------------------------------------------------------

  Future<void> _loadSubscription({bool forceRefresh = false}) async {
    if (state.isGuest) {
      if (!mounted) return;

      setState(() {
        _subscriptionLoading = false;
      });

      return;
    }

    if (!forceRefresh && subscriptionController.state.hasLoaded) {
      debugPrint(
        'BudgetScreen: subscription already loaded. '
        'Skipping duplicate subscription check.',
      );

      return;
    }

    if (!_network.isOnline) {
      await subscriptionController.restoreOfflinePremiumAccess();

      debugPrint(
        'BudgetScreen: offline subscription restored. '
        'hasPremiumAccess='
        '${subscriptionController.hasPremiumAccess}',
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
        'isPremium='
        '${subscriptionController.isPremium}',
      );
    } catch (error) {
      debugPrint('BudgetScreen: failed to load subscription: $error');

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

  // ---------------------------------------------------------------------------
  // PREMIUM CHECKOUT
  // ---------------------------------------------------------------------------

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
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _premiumCheckoutInProgress = false;
        _premiumPaymentVerificationPending = false;
      });

      SnackbarHelper.showError(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // PREMIUM PAYMENT VERIFICATION
  // ---------------------------------------------------------------------------

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
    } catch (error) {
      debugPrint('BudgetScreen: Premium payment verification failed: $error');

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

  // ---------------------------------------------------------------------------
  // PREMIUM FEATURE ACCESS
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // ADVANCED BUDGET INSIGHTS
  // ---------------------------------------------------------------------------

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
    } on RateLimitException catch (error) {
      if (!mounted) return;

      SnackbarHelper.showRateLimited(
        context,
        message: error.message,
        remaining: error.remaining,
        retryAfter: error.retryAfter,
      );
    } catch (error) {
      debugPrint('Advanced Budget Insights failed: $error');

      if (!mounted) return;

      SnackbarHelper.showError(
        context,
        'Unable to load Advanced Budget Insights. Please try again.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // BUDGET SIMULATION
  // ---------------------------------------------------------------------------

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
    } on RateLimitException catch (error) {
      if (!mounted) return;

      SnackbarHelper.showRateLimited(
        context,
        message: error.message,
        remaining: error.remaining,
        retryAfter: error.retryAfter,
      );
    } catch (error) {
      debugPrint('Budget Simulation failed: $error');

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
      isLoading: _premiumCardLoading,
      accentColor: Colors.blue,
      onPressed: _openAdvancedBudgetInsights,
    );
  }

  Widget _buildAdvancedBudgetSimulation() {
    return PremiumFeatureCard(
      feature: PremiumFeature.budgetSimulation,
      isPremium: subscriptionController.hasPremiumAccess,
      isLoading: _premiumCardLoading,
      accentColor: Colors.blue,
      onPressed: _openBudgetSimulation,
    );
  }

  // ---------------------------------------------------------------------------
  // SAVE BUDGET
  // ---------------------------------------------------------------------------

  Future<void> saveBudget() async {
    final network = context.read<ConnectivityProvider>();

    if (budgetController.text.trim().isEmpty) {
      SnackbarHelper.showError(context, 'Please enter a budget amount');
      return;
    }

    final amount = double.tryParse(budgetController.text.trim());

    if (amount == null || amount <= 0) {
      SnackbarHelper.showError(context, 'Budget must be greater than zero');
      return;
    }

    network.setSyncing(true);

    try {
      final isUpdate = state.budget > 0;

      final newState = await controller.saveBudget(
        amount: amount,
        month: _selectedBudgetPeriod.month,
        year: _selectedBudgetPeriod.year,
      );

      if (!mounted) return;

      setState(() {
        state = newState;

        budgetController.text = state.budget.toStringAsFixed(0);
      });

      SnackbarHelper.showSuccess(
        context,
        isUpdate
            ? 'Budget updated successfully'
            : 'Budget created successfully',
      );
    } on RateLimitException catch (error) {
      if (!mounted) return;

      SnackbarHelper.showRateLimited(
        context,
        message: error.message,
        remaining: error.remaining,
        retryAfter: error.retryAfter,
      );
    } catch (error) {
      debugPrint('Save budget failed: $error');

      if (!mounted) return;

      SnackbarHelper.showError(context, 'Failed to save budget.');
    } finally {
      network.setSyncing(false);
    }
  }

  // ---------------------------------------------------------------------------
  // REFRESH
  // ---------------------------------------------------------------------------

  Future<void> refreshBudgetData() async {
    final network = context.read<ConnectivityProvider>();

    if (!network.isOnline) {
      await loadBudget();

      if (!mounted) return;

      SnackbarHelper.showInfo(
        context,
        'Offline mode • Showing cached budget data.',
      );

      return;
    }

    await loadBudget();
  }

  // ---------------------------------------------------------------------------
  // DELETE BUDGET
  // ---------------------------------------------------------------------------

  Future<void> deleteBudget() async {
    try {
      final newState = await controller.deleteBudget(
        month: _selectedBudgetPeriod.month,
        year: _selectedBudgetPeriod.year,
      );

      if (!mounted) return;

      setState(() {
        state = newState;

        budgetController.clear();
      });

      SnackbarHelper.showSuccess(context, 'Budget deleted successfully');
    } on RateLimitException catch (error) {
      if (!mounted) return;

      SnackbarHelper.showRateLimited(
        context,
        message: error.message,
        remaining: error.remaining,
        retryAfter: error.retryAfter,
      );
    } catch (error) {
      if (!mounted) return;

      SnackbarHelper.showError(context, 'Error deleting budget: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // DELETE CONFIRMATION
  // ---------------------------------------------------------------------------

  Future<void> confirmDeleteBudget() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => const DeleteBudgetDialog(),
    );

    if (shouldDelete == true) {
      await deleteBudget();
    }
  }

  // ---------------------------------------------------------------------------
  // CREATE / EDIT BUDGET DIALOG
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // PERIOD PICKER
  // ---------------------------------------------------------------------------

  Future<void> _showBudgetPeriodPicker() async {
    final now = DateTime.now();

    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final recentMonths = List.generate(
          18,
          (index) => DateTime(now.year, now.month - index, 1),
        );

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Select Budget Period',
                          style: Theme.of(sheetContext).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    itemCount: recentMonths.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (_, index) {
                      // -------------------------------------------------------
                      // CUSTOM MONTH
                      // -------------------------------------------------------

                      if (index == recentMonths.length) {
                        return ListTile(
                          leading: const Icon(Icons.date_range_rounded),
                          title: const Text('Choose another month'),
                          subtitle: const Text(
                            'Open the calendar to select an older period',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () async {
                            final lastDate = DateTime(
                              now.year,
                              now.month,
                              now.day,
                            );

                            var initialDate = _selectedBudgetPeriod;

                            if (initialDate.isAfter(lastDate)) {
                              initialDate = lastDate;
                            }

                            final picked = await showDatePicker(
                              context: sheetContext,
                              initialDate: initialDate,
                              firstDate: DateTime(2000),
                              lastDate: lastDate,
                              helpText: 'Select budget month',
                            );

                            if (picked != null && sheetContext.mounted) {
                              Navigator.pop(
                                sheetContext,
                                DateTime(picked.year, picked.month, 1),
                              );
                            }
                          },
                        );
                      }

                      // -------------------------------------------------------
                      // RECENT MONTH
                      // -------------------------------------------------------

                      final period = recentMonths[index];

                      final isSelected =
                          period.year == _selectedBudgetPeriod.year &&
                          period.month == _selectedBudgetPeriod.month;

                      final isCurrent =
                          period.year == now.year && period.month == now.month;

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: Theme.of(
                          sheetContext,
                        ).colorScheme.primary.withOpacity(0.08),
                        leading: Icon(
                          isCurrent
                              ? Icons.today_rounded
                              : Icons.calendar_month_rounded,
                          color: isSelected
                              ? Theme.of(sheetContext).colorScheme.primary
                              : null,
                        ),
                        title: Text(_formatBudgetPeriod(period)),
                        subtitle: Text(isCurrent ? 'Current' : 'Historical'),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: Theme.of(
                                  sheetContext,
                                ).colorScheme.primary,
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(sheetContext, period);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || !mounted) {
      return;
    }

    await _changeBudgetPeriod(selected);
  }

  // ---------------------------------------------------------------------------
  // CHANGE PERIOD
  // ---------------------------------------------------------------------------

  Future<void> _changeBudgetPeriod(DateTime period) async {
    final normalized = DateTime(period.year, period.month, 1);

    if (normalized.year == _selectedBudgetPeriod.year &&
        normalized.month == _selectedBudgetPeriod.month) {
      return;
    }

    setState(() {
      _selectedBudgetPeriod = normalized;

      // Prevent old period data from appearing while
      // the newly selected period is loading.
      state = const BudgetState(isLoading: true);

      budgetController.clear();
    });

    await loadBudget();
  }

  // ---------------------------------------------------------------------------
  // PERIOD FORMAT
  // ---------------------------------------------------------------------------

  String _formatBudgetPeriod(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  // ---------------------------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // BODY
  // ---------------------------------------------------------------------------

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

    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final mediaQuery = MediaQuery.of(context);

    final bottomSafeArea = mediaQuery.padding.bottom;

    final fabClearance = landscape && !desktop
        ? 120.0
        : compact
        ? 180.0
        : 190.0;

    final bottomContentPadding = fabClearance + bottomSafeArea;

    /*
     * IMPORTANT:
     *
     * The period selector is now part of the main
     * scrollable body even when no budget exists.
     *
     * This means a user can select September 2026,
     * discover that there is no budget, then switch
     * to August 2026 without being trapped inside
     * the empty state.
     */

    return RefreshIndicator(
      onRefresh: refreshBudgetData,
      child: SingleChildScrollView(
        key: const PageStorageKey('budget'),
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

                _buildBudgetPeriodSelector(context),

                if (!_isCurrentBudgetPeriod) ...[
                  const SizedBox(height: 10),

                  _buildHistoricalBudgetNotice(context),
                ],

                SizedBox(height: compact ? 14 : 20),

                // -------------------------------------------------------------
                // NO BUDGET FOR SELECTED PERIOD
                // -------------------------------------------------------------
                if (state.budget <= 0)
                  _buildNoBudgetForPeriod(context, network)
                // -------------------------------------------------------------
                // BUDGET EXISTS
                // -------------------------------------------------------------
                else ...[
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

                  BudgetSectionHeader(
                    title: '${_selectedBudgetPeriodLabel} Budget Overview',
                    subtitle: 'Track spending and stay within your budget',
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

                  // -----------------------------------------------------------
                  // PREMIUM
                  //
                  // These features remain current-period only for now.
                  // Their APIs/screens have not been made period-aware.
                  // -----------------------------------------------------------
                  if (!state.isGuest && _isCurrentBudgetPeriod) ...[
                    SizedBox(height: sectionSpacing),

                    _buildAdvancedBudgetFeature(),

                    SizedBox(height: sectionSpacing),

                    _buildAdvancedBudgetSimulation(),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // NO BUDGET FOR SELECTED PERIOD
  // ---------------------------------------------------------------------------

  Widget _buildNoBudgetForPeriod(
    BuildContext context,
    ConnectivityProvider network,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.dividerColor.withOpacity(0.65)),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 32,
              color: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            _isCurrentBudgetPeriod
                ? 'No Budget Set'
                : 'No Budget for $_selectedBudgetPeriodLabel',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _isCurrentBudgetPeriod
                ? 'Set a monthly budget to start tracking your spending and financial health.'
                : 'No budget was recorded for this historical period. '
                      'You can create one to keep the budget record complete.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: showCreateBudgetDialog,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              _isCurrentBudgetPeriod
                  ? 'Create Budget'
                  : 'Create $_selectedBudgetPeriodLabel Budget',
            ),
          ),

          const SizedBox(height: 12),

          Text(
            network.isOnline
                ? 'Budget changes will sync with your account.'
                : 'Offline mode • Your budget will sync when connection is restored.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PERIOD SELECTOR
  // ---------------------------------------------------------------------------

  Widget _buildBudgetPeriodSelector(BuildContext context) {
    final theme = Theme.of(context);

    final isCurrent = _isCurrentBudgetPeriod;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _showBudgetPeriodPicker,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedBudgetPeriodLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      isCurrent
                          ? 'Current budget period'
                          : 'Historical budget period',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isCurrent
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HISTORICAL NOTICE
  // ---------------------------------------------------------------------------

  Widget _buildHistoricalBudgetNotice(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.history_rounded,
            size: 19,
            color: theme.colorScheme.primary,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              'You are viewing a historical budget. '
              'Its expenses and calculations do not affect your current-month budget.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // OVERVIEW
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // ANALYTICS
  // ---------------------------------------------------------------------------

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
