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
import '../widgets/analytics/analytics_error_state.dart';
import '../widgets/analytics/analytics_refresh_error_banner.dart';

import '../services/guest_dialog_service.dart';
import '../services/session_service.dart';
import '../services/analytics_service.dart';
import '../services/report_manager_service.dart';
import '../services/analytics_export_service.dart';

import '../models/analytics_summary.dart';
import '../models/analytics_period.dart';

import '../utils/analytics_theme_helper.dart';
import '../utils/responsive_helper.dart';

import '../repositories/analytics_repository.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with AutomaticKeepAliveClientMixin {
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

  @override
  void initState() {
    super.initState();

    _network = context.read<ConnectivityProvider>();
    _wasOnline = _network.isOnline;
    _network.addListener(_onConnectivityChanged);

    loadSessionState();
    loadReports();
  }

  Future<void> loadSessionState() async {
    final guest = await SessionService.isGuest();

    if (!mounted) return;

    setState(() {
      isGuest = guest;
    });

    if (guest) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    await _loadAnalytics();
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

      if (_analyticsRequestInProgress) {
        return;
      }

      _loadAnalytics(showFullSkeleton: summary == null);
    }
  }

  @override
  void dispose() {
    _network.removeListener(_onConnectivityChanged);
    super.dispose();
  }

  Future<void> _loadAnalytics({bool showFullSkeleton = false}) async {
    if (_analyticsRequestInProgress) {
      return;
    }

    if (isGuest == true) {
      return;
    }

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
      final result = await analyticsService.loadAnalytics(
        period: requestPeriod,
      );

      if (!mounted) return;

      setState(() {
        summary = result;
        isLoading = false;
        isRefreshingAnalytics = false;
        _analyticsError = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isRefreshingAnalytics = false;

        if (!_network.isOnline) {
          _isOffline = true;
          _analyticsError =
              'You are offline. Your existing analytics are still available.';
        } else {
          _analyticsError =
              'We couldn\'t load your analytics. Please try again.';
        }
      });
    } finally {
      _analyticsRequestInProgress = false;
    }
  }

  Future<void> _refreshAnalytics() async {
    if (_isOffline) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You are offline. Your existing analytics are still available.',
          ),
        ),
      );

      return;
    }

    await _loadAnalytics();
  }

  Future<void> _retryAnalytics() async {
    if (_isOffline) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are offline. Please reconnect and try again.'),
        ),
      );

      return;
    }

    await _loadAnalytics();
  }

  Future<void> shareExistingReport(String path) async {
    final exists = await ReportManagerService.shareExistingReport(path);

    if (!exists && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report file no longer exists')),
      );
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
    final result = await ReportManagerService.loadReports();

    if (!mounted) return;

    setState(() {
      reports = result;
    });
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
        body: _analyticsError != null
            ? AnalyticsErrorState(
                isOffline: _isOffline,
                message: _analyticsError!,
                isRetrying: _analyticsRequestInProgress,
                onRetry: _retryAnalytics,
              )
            : buildEmptyState(context, EmptyStateType.analyticsNoData),
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
          ? buildEmptyState(context, EmptyStateType.analyticsNoData)
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

                            setState(() {
                              selectedPeriod = value;
                            });

                            await _loadAnalytics();
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
