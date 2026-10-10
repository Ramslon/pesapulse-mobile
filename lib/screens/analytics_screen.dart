import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/connectivity_provider.dart';

import '../widgets/analytics_loading_skeleton.dart';
import '../widgets/analytics_section_header.dart';
import '../widgets/fade_slide_animation.dart';
import '../widgets/empty_state_helper.dart';
import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';
import '../widgets/analytics/analytics_overview_card.dart';
import '../widgets/analytics/analytics_stats_grid.dart';
import '../widgets/analytics/financial_health_card.dart';
import '../widgets/analytics/recommendation_card.dart';
import '../widgets/analytics/category_breakdown_chart.dart';
import '../widgets/analytics/goal_status_chart.dart';
import '../widgets/analytics/monthly_spending_chart.dart';
import '../widgets/analytics/smart_insights_card.dart';
import '../widgets/analytics/reports_center_card.dart';
import '../widgets/analytics/export_reports_section.dart';
import '../widgets/analytics/report_details_dialog.dart';
import '../widgets/analytics/analytics_period_selector.dart';
import '../widgets/analytics/analytics_refresh_error_banner.dart';
import '../widgets/premium/premium_feature_card.dart';
import '../widgets/premium/premium_feature_guard.dart';

import '../services/guest_dialog_service.dart';
import '../services/session_service.dart';
import '../services/analytics_service.dart';
import '../services/report_manager_service.dart';
import '../services/analytics_export_service.dart';
import '../services/sync_events.dart';
import '../services/api_services.dart';

import '../models/analytics_summary.dart';
import '../models/analytics_period.dart';

import '../subscription/controllers/subscription_controller.dart';
import '../subscription/models/premium_feature.dart';
import '../subscription/models/premium_payment_result.dart';

import '../utils/analytics_theme_helper.dart';
import '../utils/responsive_helper.dart';
import '../utils/snackbar_helper.dart';

import '../repositories/analytics_repository.dart';
import '../exceptions/rate_limit_exception.dart';

import 'advanced_analytics_screen.dart';
import 'spending_forecast_screen.dart';
import '../screens/historical_insights_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  AnalyticsSummary? summary;

  List<Map<String, dynamic>> reports = [];

  bool? isGuest;
  bool isLoading = true;
  bool isRefreshingAnalytics = false;
  bool? _wasOnline;
  bool _analyticsRequestInProgress = false;
  bool _isOffline = false;
  String? _analyticsError;

  AnalyticsPeriod selectedPeriod = AnalyticsPeriod.thisMonth;

  final AnalyticsRepository analyticsRepository = AnalyticsRepository();

  late final AnalyticsService analyticsService = AnalyticsService(
    analyticsRepository,
  );

  late ConnectivityProvider _network;

  final SubscriptionController _subscriptionController =
      SubscriptionController();

  bool get _hasPremiumAccess => _subscriptionController.hasPremiumAccess;

  bool _subscriptionLoading = false;
  bool _subscriptionRefreshQueued = false;
  bool _cacheReloadPending = false;
  bool _premiumCheckoutInProgress = false;
  bool _checkingPayment = false;

  bool _premiumPaymentVerificationPending = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _network = context.read<ConnectivityProvider>();
    _wasOnline = _network.isOnline;

    _network.addListener(_onConnectivityChanged);

    SyncEvents.instance.analyticsRefresh.addListener(_onAnalyticsDataChanged);

    _subscriptionController.addListener(_onSubscriptionChanged);

    _initializeAnalytics();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    if (isGuest == true) {
      return;
    }

    // Restore the last verified entitlement when offline.
    if (!_network.isOnline) {
      _loadSubscription(forceRefresh: true);

      if (_premiumCheckoutInProgress || _premiumPaymentVerificationPending) {
        if (!mounted) return;

        setState(() {
          _premiumCheckoutInProgress = false;
        });

        SnackbarHelper.showInfo(
          context,
          'Reconnect to verify your Premium payment.',
        );
      }

      return;
    }

    // If this screen initiated checkout, verify that payment.
    if (_premiumCheckoutInProgress || _premiumPaymentVerificationPending) {
      _verifyPremiumAfterPayment();
      return;
    }

    // Important:
    // Premium may have been activated from Budget or another
    // screen while Analytics remained mounted in the IndexedStack.
    // Always refresh the subscription when the app resumes,
    // even if Analytics did not initiate the checkout.
    _loadSubscription(forceRefresh: true);
  }

  void _onAnalyticsDataChanged() {
    if (!mounted) return;

    debugPrint(
      'Analytics: synchronized data changed. '
      'Reloading analytics from local cache.',
    );

    _reloadAnalyticsFromCache();
  }

  void _onSubscriptionChanged() {
    if (!mounted) return;

    setState(() {});
  }

  Future<void> _loadSubscription({bool forceRefresh = false}) async {
    if (isGuest == true) return;

    if (_subscriptionLoading) {
      if (forceRefresh) {
        _subscriptionRefreshQueued = true;
      }

      return;
    }

    if (mounted) {
      setState(() {
        _subscriptionLoading = true;
      });
    }

    try {
      if (!_network.isOnline) {
        await _subscriptionController.restoreOfflinePremiumAccess();
      } else {
        await _subscriptionController.loadSubscription(
          forceRefresh: forceRefresh,
        );
      }
    } catch (e) {
      debugPrint('Analytics: failed to load subscription: $e');

      // If connectivity was lost during the request,
      // restore the last locally available entitlement.
      if (!_network.isOnline) {
        try {
          await _subscriptionController.restoreOfflinePremiumAccess();
        } catch (restoreError) {
          debugPrint(
            'Analytics: offline Premium restoration failed: '
            '$restoreError',
          );
        }
      }
    } finally {
      final refreshAgain = _subscriptionRefreshQueued;
      _subscriptionRefreshQueued = false;

      if (mounted) {
        setState(() {
          _subscriptionLoading = false;
        });
      }

      if (refreshAgain && mounted && _network.isOnline) {
        await _loadSubscription(forceRefresh: true);
      }
    }
  }

  Future<void> _reloadAnalyticsFromCache() async {
    if (!mounted || isGuest == true) return;

    if (_analyticsRequestInProgress) {
      _cacheReloadPending = true;
      return;
    }

    final requestPeriod = selectedPeriod;

    try {
      final analytics = await analyticsRepository.getCachedAnalytics();

      final processed = await analyticsService.processAnalyticsData(
        analytics: analytics,
        period: requestPeriod,
      );

      if (!mounted) return;

      // A network request or period change may have started
      // while the cache was being read.
      if (_analyticsRequestInProgress || selectedPeriod != requestPeriod) {
        _cacheReloadPending = true;
        return;
      }

      setState(() {
        summary = processed;
        isLoading = false;
        _isOffline = !_network.isOnline;
        _analyticsError = null;
      });

      debugPrint('Analytics: local analytics cache reloaded successfully.');
    } catch (e) {
      debugPrint('Analytics: failed to reload local cache: $e');
    }
  }

  Future<void> _initializeAnalytics() async {
    try {
      final guest = await SessionService.isGuest();

      if (!mounted) return;

      setState(() {
        isGuest = guest;
        _isOffline = !_network.isOnline;
      });

      if (guest) {
        await _loadCachedAnalytics();

        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        return;
      }

      // Begin checking Premium access immediately.
      // Do not await this before loading the analytics cache.
      await _loadSubscription();

      // These are independent local operations.
      await Future.wait<void>([_loadCachedAnalytics(), loadReports()]);

      if (!mounted) return;

      if (!_network.isOnline) {
        setState(() {
          _isOffline = true;
          isLoading = false;

          if (summary == null) {
            _analyticsError =
                'You are offline and no cached analytics are available.';
          }
        });

        return;
      }

      setState(() {
        // Show the skeleton only when no usable analytics are available.
        isLoading = summary == null;
        _analyticsError = null;
      });

      // First fetch happens after the initial frame, without blocking
      // the screen when cached analytics are already available.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _refreshAnalyticsInBackground();
      });
    } catch (e) {
      debugPrint('Analytics initialization failed: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
        _analyticsError = 'We couldn’t initialize analytics. Please try again.';
      });
    }
  }

  Future<void> _loadCachedAnalytics() async {
    try {
      final analytics = await analyticsRepository.getCachedAnalytics();

      final processed = await analyticsService.processAnalyticsData(
        analytics: analytics,
        period: selectedPeriod,
      );

      if (!mounted) return;

      setState(() {
        summary = processed;
        isLoading = false;
        _analyticsError = null;
      });

      debugPrint('Loaded cached analytics data.');
    } catch (e) {
      debugPrint('No cached analytics available: $e');
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
      await _subscriptionController.startPremiumCheckout();

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
      _premiumPaymentVerificationPending = false;

      if (!mounted) return;

      setState(() {
        _premiumCheckoutInProgress = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _verifyPremiumAfterPayment() async {
    if (!mounted || _checkingPayment) return;

    if (!_network.isOnline) {
      setState(() {
        _premiumCheckoutInProgress = false;
      });

      SnackbarHelper.showInfo(
        context,
        _hasPremiumAccess
            ? 'Premium is already unlocked. Reconnect to verify your payment.'
            : 'Payment status cannot be verified while offline. Reconnect and try again.',
      );

      return;
    }

    setState(() {
      _checkingPayment = true;
    });

    try {
      final result = await _subscriptionController.verifyPendingPayment();

      if (!mounted || result == null) return;

      switch (result.status) {
        case PremiumPaymentStatus.complete:
          await _subscriptionController.cacheCurrentPremiumAccess();

          _premiumPaymentVerificationPending = false;

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
          SnackbarHelper.showError(context, result.message);
          break;
      }
    } catch (e) {
      debugPrint('Analytics: Premium payment verification failed: $e');

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

      if (_hasPremiumAccess) {
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

  Future<void> _openAdvancedAnalytics() async {
    final allowed = await _checkPremiumFeatureAccess(
      PremiumFeature.advancedAnalytics,
    );

    if (!allowed || !mounted) return;

    try {
      final data = await ApiService.getAdvancedAnalytics(months: 6);

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdvancedAnalyticsScreen(analytics: data),
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
      debugPrint('Advanced Analytics failed: $e');

      if (!mounted) return;

      SnackbarHelper.showError(
        context,
        'Unable to load Advanced Analytics. Please try again.',
      );
    }
  }

  Future<void> _openSpendingForecast() async {
    final allowed = await _checkPremiumFeatureAccess(
      PremiumFeature.spendingForecast,
    );

    if (!allowed || !mounted) return;
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SpendingForecastScreen()),
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
      debugPrint('Spending Forecast failed: $e');

      if (!mounted) return;

      SnackbarHelper.showError(
        context,
        'Unable to load Spending Forecast. Please try again.',
      );
    }
  }

  Future<void> _openHistoricalInsights() async {
    final allowed = await _checkPremiumFeatureAccess(
      PremiumFeature.historicalInsights,
    );

    if (!allowed || !mounted) return;
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HistoricalInsightsScreen()),
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
      debugPrint('Historical Insights failed: $e');

      if (!mounted) return;

      SnackbarHelper.showError(
        context,
        'Unable to load Historical Insights. Please try again.',
      );
    }
  }

  void _onConnectivityChanged() {
    final isOnline = _network.isOnline;
    final wasOnline = _wasOnline;

    _wasOnline = isOnline;

    if (!mounted) return;

    if (!isOnline) {
      if (!_isOffline) {
        setState(() {
          _isOffline = true;
        });
      }

      return;
    }

    if (_isOffline) {
      setState(() {
        _isOffline = false;
      });
    }

    if (wasOnline == false && isOnline) {
      if (isGuest == true) {
        return;
      }

      if (!_analyticsRequestInProgress) {
        _refreshAnalyticsInBackground();
      }

      _loadSubscription(forceRefresh: true);

      if (_premiumPaymentVerificationPending) {
        _verifyPremiumAfterPayment();
      }
    }
  }

  Future<void> _refreshAnalyticsInBackground() async {
    if (_analyticsRequestInProgress) return;

    _analyticsRequestInProgress = true;

    try {
      final analytics = await analyticsRepository.refreshAnalytics();

      final processed = await analyticsService.processAnalyticsData(
        analytics: analytics,
        period: selectedPeriod,
      );

      if (!mounted) return;

      setState(() {
        summary = processed;
        _analyticsError = null;
        _isOffline = false;
        isLoading = false;
      });

      debugPrint('Analytics background refresh completed.');
    } on RateLimitException catch (e) {
      debugPrint('Analytics background refresh rate limited: ${e.message}');
    } catch (e) {
      debugPrint('Analytics background refresh failed: $e');
    } finally {
      _analyticsRequestInProgress = false;

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _network.removeListener(_onConnectivityChanged);

    SyncEvents.instance.analyticsRefresh.removeListener(
      _onAnalyticsDataChanged,
    );

    _subscriptionController.removeListener(_onSubscriptionChanged);
    _subscriptionController.dispose();

    super.dispose();
  }

  Future<void> _loadAnalytics({bool showFullSkeleton = false}) async {
    if (_analyticsRequestInProgress) return;
    if (isGuest == true) return;

    _analyticsRequestInProgress = true;

    final requestPeriod = selectedPeriod;
    final shouldShowSkeleton = showFullSkeleton && summary == null;

    if (mounted) {
      setState(() {
        _analyticsError = null;

        if (shouldShowSkeleton) {
          isLoading = true;
        } else {
          isRefreshingAnalytics = true;
        }
      });
    }

    try {
      final analytics = await analyticsRepository.refreshAnalytics();

      final result = await analyticsService.processAnalyticsData(
        analytics: analytics,
        period: requestPeriod,
      );

      if (!mounted) return;

      setState(() {
        summary = result;
        isLoading = false;
        isRefreshingAnalytics = false;
        _analyticsError = null;
        _isOffline = false;
      });
    } on RateLimitException catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isRefreshingAnalytics = false;
        _analyticsError = e.message;
      });

      SnackbarHelper.showRateLimited(
        context,
        message: e.message,
        remaining: e.remaining,
        retryAfter: e.retryAfter,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isRefreshingAnalytics = false;
      });

      if (!_network.isOnline) {
        setState(() {
          _isOffline = true;
          _analyticsError =
              'You are offline. Your existing analytics are still available.';
        });

        SnackbarHelper.showError(
          context,
          'Offline mode: showing cached analytics.',
        );
      } else {
        setState(() {
          _analyticsError =
              'We couldn\'t load your analytics. Please try again.';
        });

        SnackbarHelper.showError(
          context,
          'Failed to load analytics. Please try again.',
        );
      }
    } finally {
      _analyticsRequestInProgress = false;
    }
  }

  Future<void> _refreshAnalytics() async {
    if (!_network.isOnline) {
      if (!mounted) return;

      SnackbarHelper.showError(
        context,
        'You are offline. Your existing analytics are still available.',
      );

      return;
    }

    await Future.wait<void>([
      _loadAnalytics(),
      _loadSubscription(forceRefresh: true),
      loadReports(),
    ]);
  }

  Future<void> _retryAnalytics() async {
    if (_isOffline || !_network.isOnline) {
      if (!mounted) return;

      SnackbarHelper.showError(
        context,
        'You are offline. Please reconnect and try again.',
      );

      return;
    }

    await _refreshAnalytics();
  }

  Future<void> _changeAnalyticsPeriod(AnalyticsPeriod period) async {
    if (_analyticsRequestInProgress) return;
    if (isGuest == true) return;

    final previousPeriod = selectedPeriod;

    // Acquire the shared lock before starting asynchronous work.
    _analyticsRequestInProgress = true;

    setState(() {
      selectedPeriod = period;
      isRefreshingAnalytics = true;
      _analyticsError = null;
    });

    try {
      final analytics = _network.isOnline
          ? await analyticsRepository.refreshAnalytics()
          : await analyticsRepository.getCachedAnalytics();

      final processed = await analyticsService.processAnalyticsData(
        analytics: analytics,
        period: period,
      );

      if (!mounted) return;

      setState(() {
        summary = processed;
        isLoading = false;
        isRefreshingAnalytics = false;
        _isOffline = !_network.isOnline;
        _analyticsError = null;
      });
    } catch (e) {
      debugPrint(
        'Analytics: failed to change period '
        '$previousPeriod → $period: $e',
      );

      if (!mounted) return;

      setState(() {
        selectedPeriod = previousPeriod;
        isLoading = false;
        isRefreshingAnalytics = false;
        _isOffline = !_network.isOnline;
        _analyticsError = _network.isOnline
            ? 'Could not load analytics for that period. Please try again.'
            : 'You are offline. Your saved analytics are still available.';
      });
    } finally {
      _analyticsRequestInProgress = false;

      if (mounted) {
        setState(() {
          isLoading = false;
          isRefreshingAnalytics = false;
        });
      }

      _flushPendingCacheReload();
    }
  }

  void _flushPendingCacheReload() {
    if (!mounted || !_cacheReloadPending || _analyticsRequestInProgress) {
      return;
    }

    _cacheReloadPending = false;
    _reloadAnalyticsFromCache();
  }

  Future<void> shareExistingReport(String path) async {
    final exists = await ReportManagerService.shareExistingReport(path);
    if (!exists && mounted) {
      SnackbarHelper.showError(context, 'Report file no longer exists');
    }
  }

  Future<void> previewReport(Map<String, dynamic> report) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => ReportDetailsDialog(report: report),
    );
  }

  Future<void> loadReports() async {
    try {
      final result = await ReportManagerService.loadReports();

      if (!mounted) return;

      setState(() {
        reports = result;
      });
    } catch (e) {
      debugPrint('Analytics: failed to load reports: $e');
    }
  }

  Future<void> deleteReport(int index) async {
    final result = await ReportManagerService.deleteReport(index);
    if (!mounted) return;
    setState(() {
      reports = result;
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // ─────────────────────────────────────────
    // Responsive configuration
    // ─────────────────────────────────────────

    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final screenWidth = ResponsiveHelper.width(context);

    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);
    final spacing = ResponsiveHelper.spacing(context);

    final contentPadding = _contentPadding(
      compact: compact,
      landscape: landscape,
      tablet: tablet,
      desktop: desktop,
      screenWidth: screenWidth,
    );

    final chartHeight = _chartHeight(
      compact: compact,
      landscape: landscape,
      tablet: tablet,
      desktop: desktop,
    );

    final maxContentWidth = _maxContentWidth(
      screenWidth: screenWidth,
      tablet: tablet,
      desktop: desktop,
    );

    final maxChartWidth = _maxChartWidth(
      screenWidth: screenWidth,
      tablet: tablet,
      desktop: desktop,
    );

    final internalSpacing = _internalSpacing(
      compact: compact,
      landscape: landscape,
      tablet: tablet,
      desktop: desktop,
    );

    final largeSectionSpacing = _largeSectionSpacing(
      sectionSpacing: sectionSpacing,
      compact: compact,
    );

    // ─────────────────────────────────────────
    // Loading
    // ─────────────────────────────────────────

    if (isGuest == null || (isLoading && summary == null)) {
      return const AnalyticsLoadingSkeleton();
    }

    // ─────────────────────────────────────────
    // Guest
    // ─────────────────────────────────────────

    if (isGuest!) {
      return AppScaffold(
        showOfflineBanner: _isOffline,
        appBar: const AdaptiveAppBar(title: null),
        body: buildEmptyState(context, EmptyStateType.analyticsGuest),
      );
    }

    final analytics = summary;

    // ─────────────────────────────────────────
    // No analytics
    // ─────────────────────────────────────────

    if (analytics == null) {
      return AppScaffold(
        showOfflineBanner: _isOffline,
        appBar: const AdaptiveAppBar(title: null),
        body: _buildAnalyticsUnavailableContent(
          contentPadding: contentPadding,
          maxContentWidth: maxContentWidth,
          sectionSpacing: sectionSpacing,
        ),
      );
    }

    final hasNoData =
        analytics.expenses.isEmpty &&
        analytics.totalGoals == 0 &&
        reports.isEmpty;

    final hasPartialData =
        !hasNoData &&
        (analytics.expenses.isEmpty ||
            analytics.totalGoals == 0 ||
            reports.isEmpty);

    // ─────────────────────────────────────────
    // Main screen
    // ─────────────────────────────────────────

    return AppScaffold(
      showOfflineBanner: _isOffline,
      appBar: const AdaptiveAppBar(title: null),
      body: hasNoData
          ? _buildAnalyticsUnavailableContent(
              contentPadding: contentPadding,
              maxContentWidth: maxContentWidth,
              sectionSpacing: sectionSpacing,
            )
          : RefreshIndicator(
              onRefresh: _refreshAnalytics,
              child: SingleChildScrollView(
                key: const PageStorageKey('analytics'),
                padding: EdgeInsets.all(contentPadding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─────────────────────────────
                        // Refresh progress
                        // ─────────────────────────────
                        if (isRefreshingAnalytics)
                          Padding(
                            padding: EdgeInsets.only(bottom: spacing),
                            child: const LinearProgressIndicator(minHeight: 2),
                          ),

                        // ─────────────────────────────
                        // Refresh error
                        // ─────────────────────────────
                        AnalyticsRefreshErrorBanner(
                          error: _analyticsError,
                          isOffline: _isOffline,
                          isRetrying: _analyticsRequestInProgress,
                          onRetry: _retryAnalytics,
                        ),

                        SizedBox(height: spacing),

                        // ─────────────────────────────
                        // Partial data
                        // ─────────────────────────────
                        if (hasPartialData)
                          Padding(
                            padding: EdgeInsets.only(bottom: spacing),
                            child: buildEmptyState(
                              context,
                              EmptyStateType.analyticsInProgress,
                            ),
                          ),

                        SizedBox(height: spacing),

                        // ─────────────────────────────
                        // Period selector
                        // ─────────────────────────────
                        AnalyticsPeriodSelector(
                          selectedPeriod: selectedPeriod,
                          isDisabled:
                              isRefreshingAnalytics ||
                              _analyticsRequestInProgress,
                          onChanged: (AnalyticsPeriod? value) async {
                            if (value == null || value == selectedPeriod) {
                              return;
                            }

                            await _changeAnalyticsPeriod(value);
                          },
                        ),

                        SizedBox(height: spacing),

                        // ─────────────────────────────
                        // Overview
                        // ─────────────────────────────
                        AnalyticsOverviewCard(
                          totalSpending: analytics.totalSpending,
                        ),

                        SizedBox(height: sectionSpacing),

                        //─────────────────────────────
                        //Premium
                        //─────────────────────────────
                        _buildPremiumFeatureCards(
                          sectionSpacing: sectionSpacing,
                        ),

                        SizedBox(height: sectionSpacing),

                        // ─────────────────────────────
                        // Statistics
                        // ─────────────────────────────
                        AnalyticsStatsGrid(
                          totalGoals: analytics.totalGoals,
                          completedGoals: analytics.completedGoals,
                          activeGoals: analytics.activeGoals,
                          completionRate: analytics.completionRate,
                        ),

                        SizedBox(height: sectionSpacing),

                        // ─────────────────────────────
                        // Financial health
                        // ─────────────────────────────
                        FinancialHealthCard(
                          healthScore: analytics.healthScore,
                          healthStatus: analytics.healthStatus,
                          recommendation: analytics.recommendation,
                          color: AnalyticsThemeHelper.financialHealthColor(
                            context,
                            analytics.healthStatus,
                          ),
                          icon: AnalyticsThemeHelper.financialHealthIcon(
                            analytics.healthStatus,
                          ),
                        ),

                        SizedBox(height: internalSpacing),

                        // ─────────────────────────────
                        // Recommendation
                        // ─────────────────────────────
                        FadeSlideAnimation(
                          delay: 100,
                          child: RecommendationCard(
                            budgetStatus: analytics.budgetStatus,
                            recommendation: analytics.recommendation,
                            categoryAdvice: analytics.categoryAdvice,
                            topCategory: analytics.topCategory,
                            budgetUsage: analytics.budgetUsage,
                          ),
                        ),

                        SizedBox(height: sectionSpacing),

                        // ─────────────────────────────
                        // Category breakdown
                        // ─────────────────────────────
                        const AnalyticsSectionHeader(
                          icon: Icons.pie_chart_outline_rounded,
                          title: 'Category Breakdown',
                        ),

                        SizedBox(height: spacing),

                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: maxChartWidth,
                            ),
                            child: analytics.categoryTotals.isEmpty
                                ? buildEmptyState(
                                    context,
                                    EmptyStateType.categories,
                                    isGuest: isGuest!,
                                  )
                                : CategoryBreakdownChart(
                                    categoryTotals: analytics.categoryTotals,
                                    chartHeight: chartHeight,
                                  ),
                          ),
                        ),

                        SizedBox(height: largeSectionSpacing),

                        // ─────────────────────────────
                        // Goal status
                        // ─────────────────────────────
                        const AnalyticsSectionHeader(
                          icon: Icons.flag_outlined,
                          title: 'Goal Status',
                        ),

                        SizedBox(height: spacing),

                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: maxChartWidth,
                            ),
                            child: GoalStatusChart(
                              completedGoals: analytics.completedGoals,
                              activeGoals: analytics.activeGoals,
                              totalGoals: analytics.totalGoals,
                              chartHeight: chartHeight,
                            ),
                          ),
                        ),

                        SizedBox(height: largeSectionSpacing),

                        // ─────────────────────────────
                        // Monthly spending
                        // ─────────────────────────────
                        const AnalyticsSectionHeader(
                          icon: Icons.show_chart_rounded,
                          title: 'Monthly Spending Trend',
                        ),

                        SizedBox(height: internalSpacing),

                        MonthlySpendingChart(
                          monthlyTotals: analytics.monthlyTotals,
                          expenses: analytics.expenses,
                          chartHeight: chartHeight,
                        ),

                        SizedBox(height: largeSectionSpacing),

                        // ─────────────────────────────
                        // Smart insights
                        // ─────────────────────────────
                        const AnalyticsSectionHeader(
                          icon: Icons.lightbulb_outline_rounded,
                          title: 'Smart Insights',
                        ),

                        SizedBox(height: spacing),

                        SmartInsightsCard(insights: analytics.insights),

                        SizedBox(height: largeSectionSpacing),

                        // ─────────────────────────────
                        // Reports
                        // ─────────────────────────────
                        const AnalyticsSectionHeader(
                          icon: Icons.description_outlined,
                          title: 'Reports Center',
                        ),

                        SizedBox(height: spacing),

                        ExportReportsSection(
                          isGuest: isGuest!,
                          onGuestTap: () async {
                            await GuestDialogService.requireAccount(context);
                          },
                          onExportPdf: () {
                            return AnalyticsExportService.exportPdf(
                              context: context,
                              expenses: analytics.expenses,
                              onReportsUpdated: loadReports,
                            );
                          },
                          onExportCsv: () {
                            return AnalyticsExportService.exportCsv(
                              context: context,
                              expenses: analytics.expenses,
                              onReportsUpdated: loadReports,
                            );
                          },
                        ),

                        SizedBox(height: spacing),

                        // ─────────────────────────────
                        // Reports count
                        // ─────────────────────────────
                        _buildReportsCount(context, spacing: spacing),

                        SizedBox(height: internalSpacing),

                        // ─────────────────────────────
                        // Reports center
                        // ─────────────────────────────
                        ReportsCenterCard(
                          reports: reports,
                          onShare: shareExistingReport,
                          onPreview: previewReport,
                          onDelete: deleteReport,
                          onClearHistory: () async {
                            final result =
                                await ReportManagerService.clearHistory();

                            if (!mounted) return;

                            setState(() {
                              reports = result;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  // ───────────────────────────────────────────
  // Reports count
  // ───────────────────────────────────────────

  Widget _buildReportsCount(BuildContext context, {required double spacing}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.folder_outlined, size: 18, color: colorScheme.primary),
        SizedBox(width: spacing),
        Flexible(
          child: Text(
            reports.length == 1
                ? '1 report generated'
                : '${reports.length} reports generated',
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumFeatureCards({required double sectionSpacing}) {
    final cardLoading =
        _subscriptionLoading || _premiumCheckoutInProgress || _checkingPayment;

    return Column(
      children: [
        PremiumFeatureCard(
          feature: PremiumFeature.advancedAnalytics,
          isPremium: _subscriptionController.hasPremiumAccess,
          isLoading: cardLoading,
          accentColor: Colors.teal,
          onPressed: _openAdvancedAnalytics,
        ),

        SizedBox(height: sectionSpacing),

        PremiumFeatureCard(
          feature: PremiumFeature.spendingForecast,
          isPremium: _subscriptionController.hasPremiumAccess,
          isLoading: cardLoading,
          accentColor: Colors.teal,
          onPressed: _openSpendingForecast,
        ),

        SizedBox(height: sectionSpacing),

        PremiumFeatureCard(
          feature: PremiumFeature.historicalInsights,
          isPremium: _subscriptionController.hasPremiumAccess,
          isLoading: cardLoading,
          accentColor: Colors.teal,
          onPressed: _openHistoricalInsights,
        ),
      ],
    );
  }

  Widget _buildAnalyticsUnavailableContent({
    required double contentPadding,
    required double maxContentWidth,
    required double sectionSpacing,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final hasError = _analyticsError != null;

    return RefreshIndicator(
      onRefresh: _refreshAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.all(contentPadding),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: EdgeInsets.all(
                    ResponsiveHelper.cardPadding(context),
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: scheme.outline.withOpacity(0.08)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        hasError
                            ? Icons.cloud_off_rounded
                            : Icons.analytics_outlined,
                        size: 42,
                        color: hasError ? scheme.error : Colors.teal,
                      ),

                      const SizedBox(height: 12),

                      Text(
                        hasError
                            ? 'Analytics temporarily unavailable'
                            : 'No analytics data yet',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        _analyticsError ??
                            'Add expenses or goals to populate your analytics. Your Premium features remain available below.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),

                      if (hasError) ...[
                        const SizedBox(height: 14),

                        FilledButton.icon(
                          onPressed: _retryAnalytics,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: sectionSpacing),

                _buildPremiumFeatureCards(sectionSpacing: sectionSpacing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────
  // Content padding
  // ───────────────────────────────────────────

  double _contentPadding({
    required bool compact,
    required bool landscape,
    required bool tablet,
    required bool desktop,
    required double screenWidth,
  }) {
    if (desktop) {
      return 28;
    }

    if (tablet) {
      return landscape ? 20 : 24;
    }

    if (landscape) {
      return 14;
    }

    if (compact) {
      return screenWidth < 360 ? 10 : 12;
    }

    return 16;
  }

  // ───────────────────────────────────────────
  // Chart height
  // ───────────────────────────────────────────

  double _chartHeight({
    required bool compact,
    required bool landscape,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) {
      return 300;
    }

    if (tablet) {
      return landscape ? 220 : 270;
    }

    if (landscape) {
      return 170;
    }

    if (compact) {
      return 220;
    }

    return 250;
  }

  // ───────────────────────────────────────────
  // Maximum content width
  // ───────────────────────────────────────────

  double _maxContentWidth({
    required double screenWidth,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) {
      return 1200;
    }

    if (tablet) {
      return 1050;
    }

    return screenWidth;
  }

  // ───────────────────────────────────────────
  // Maximum chart width
  // ───────────────────────────────────────────

  double _maxChartWidth({
    required double screenWidth,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) {
      return 850;
    }

    if (tablet) {
      return 760;
    }

    return screenWidth;
  }

  // ───────────────────────────────────────────
  // Internal spacing
  // ───────────────────────────────────────────

  double _internalSpacing({
    required bool compact,
    required bool landscape,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) {
      return 18;
    }

    if (tablet) {
      return 16;
    }

    if (landscape) {
      return 10;
    }

    if (compact) {
      return 12;
    }

    return 14;
  }

  // ───────────────────────────────────────────
  // Large section spacing
  // ───────────────────────────────────────────

  double _largeSectionSpacing({
    required double sectionSpacing,
    required bool compact,
  }) {
    return compact ? sectionSpacing : sectionSpacing * 1.15;
  }
}
