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
import '../utils/analytics_layout_helper.dart';

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

    // Guests do not need analytics data.
    if (guest) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Registered users continue loading analytics.
    await _loadAnalytics();
  }

  void _onConnectivityChanged() {
    final isOnline = _network.isOnline;
    final wasOnline = _wasOnline;

    _wasOnline = isOnline;

    if (!mounted) return;

    // Device has gone offline.
    if (!isOnline) {
      if (!_isOffline) {
        setState(() {
          _isOffline = true;
        });
      }

      return;
    }

    // Device is online again.
    if (_isOffline) {
      setState(() {
        _isOffline = false;
      });
    }

    // Only refresh on a genuine offline -> online transition.
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

    final sectionSpacing = AnalyticsLayoutHelper.sectionSpacing(context);

    final chartHeight = AnalyticsLayoutHelper.chartHeight(context);

    final contentPadding = AnalyticsLayoutHelper.contentPadding(context);

    final smallSpacing = AnalyticsLayoutHelper.smallSpacing(context);
    // Session state / analytics are still being determined.
    if (isGuest == null || (isLoading && summary == null)) {
      return const AnalyticsLoadingSkeleton();
    }

    // Guest users don't need an AnalyticsSummary.
    if (isGuest!) {
      return AppScaffold(
        showOfflineBanner: _isOffline,
        appBar: const AdaptiveAppBar(title: null),
        body: buildEmptyState(context, EmptyStateType.analyticsGuest),
      );
    }

    final analytics = summary;

    // Registered user but no analytics data could be loaded.
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
    return AppScaffold(
      showOfflineBanner: _isOffline,
      appBar: const AdaptiveAppBar(title: null),
      body: hasNoData
          ? buildEmptyState(context, EmptyStateType.analyticsNoData)
          : RefreshIndicator(
              onRefresh: _refreshAnalytics,
              child: SingleChildScrollView(
                key: const PageStorageKey("analytics"),

                padding: EdgeInsets.all(contentPadding),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: AnalyticsLayoutHelper.maxContentWidth(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        if (isRefreshingAnalytics)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: LinearProgressIndicator(minHeight: 2),
                          ),

                        AnalyticsRefreshErrorBanner(
                          error: _analyticsError,
                          isOffline: _isOffline,
                          isRetrying: _analyticsRequestInProgress,
                          onRetry: _retryAnalytics,
                        ),

                        SizedBox(height: smallSpacing),

                        if (hasPartialData)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: buildEmptyState(
                              context,
                              EmptyStateType.analyticsInProgress,
                            ),
                          ),

                        SizedBox(height: smallSpacing),

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

                        SizedBox(height: smallSpacing),

                        AnalyticsOverviewCard(
                          totalSpending: analytics.totalSpending,
                        ),
                        SizedBox(height: sectionSpacing),

                        AnalyticsStatsGrid(
                          totalGoals: analytics.totalGoals,
                          completedGoals: analytics.completedGoals,
                          activeGoals: analytics.activeGoals,
                          completionRate: analytics.completionRate,
                        ),

                        SizedBox(height: sectionSpacing),
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
                        const SizedBox(
                          height: AnalyticsLayoutHelper.cardSpacing,
                        ),

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

                        const AnalyticsSectionHeader(
                          icon: Icons.pie_chart_outline_rounded,
                          title: "Category Breakdown",
                        ),

                        SizedBox(height: smallSpacing),

                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: AnalyticsLayoutHelper.maxChartWidth(
                                context,
                              ),
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
                        SizedBox(height: sectionSpacing * 1.2),

                        const AnalyticsSectionHeader(
                          icon: Icons.flag_outlined,
                          title: "Goal Status",
                        ),
                        SizedBox(height: smallSpacing),

                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: AnalyticsLayoutHelper.maxChartWidth(
                                context,
                              ),
                            ),
                            child: GoalStatusChart(
                              completedGoals: analytics.completedGoals,
                              activeGoals: analytics.activeGoals,
                              totalGoals: analytics.totalGoals,
                              chartHeight: chartHeight,
                            ),
                          ),
                        ),

                        SizedBox(height: sectionSpacing * 1.2),

                        const AnalyticsSectionHeader(
                          icon: Icons.show_chart_rounded,
                          title: "Monthly Spending Trend",
                        ),

                        const SizedBox(
                          height: AnalyticsLayoutHelper.cardSpacing,
                        ),

                        MonthlySpendingChart(
                          monthlyTotals: analytics.monthlyTotals,
                          expenses: analytics.expenses,
                          chartHeight: chartHeight,
                        ),

                        SizedBox(height: sectionSpacing * 1.2),

                        const AnalyticsSectionHeader(
                          icon: Icons.lightbulb_outline_rounded,
                          title: "Smart Insights",
                        ),

                        SizedBox(height: smallSpacing),

                        SmartInsightsCard(insights: analytics.insights),
                        SizedBox(height: sectionSpacing * 1.2),

                        const AnalyticsSectionHeader(
                          icon: Icons.description_outlined,
                          title: "Reports Center",
                        ),

                        SizedBox(height: smallSpacing),

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
                        SizedBox(height: smallSpacing),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              reports.length == 1
                                  ? '1 report generated'
                                  : '${reports.length} reports generated',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        SizedBox(height: AnalyticsLayoutHelper.internalSpacing),

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
}
