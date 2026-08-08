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
    if (_network.isOnline && isGuest == false) {
      _loadAnalytics();
    }
  }

  @override
  void dispose() {
    _network.removeListener(_onConnectivityChanged);

    super.dispose();
  }

  Future<void> _loadAnalytics({bool showFullSkeleton = false}) async {
    if (showFullSkeleton) {
      setState(() {
        isLoading = true;
      });
    } else {
      setState(() {
        isRefreshingAnalytics = true;
      });
    }

    try {
      final result = await analyticsService.loadAnalytics(
        period: selectedPeriod,
      );

      if (!mounted) return;

      setState(() {
        summary = result;
        isLoading = false;
        isRefreshingAnalytics = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isRefreshingAnalytics = false;
      });
    }
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

  String _periodLabel(AnalyticsPeriod period) {
    switch (period) {
      case AnalyticsPeriod.thisMonth:
        return 'This Month';
      case AnalyticsPeriod.lastMonth:
        return 'Last Month';
      case AnalyticsPeriod.last3Months:
        return 'Last 3 Months';
      case AnalyticsPeriod.last6Months:
        return 'Last 6 Months';
      case AnalyticsPeriod.thisYear:
        return 'This Year';
      case AnalyticsPeriod.allTime:
        return 'All Time';
    }
  }

  Widget _buildPeriodSelector(BuildContext context) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_outlined, size: 20),

            const SizedBox(width: 10),

            const Text(
              'Period',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AnalyticsPeriod>(
                  value: selectedPeriod,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down),
                  borderRadius: BorderRadius.circular(14),

                  items: AnalyticsPeriod.values.map((period) {
                    return DropdownMenuItem<AnalyticsPeriod>(
                      value: period,
                      child: Text(
                        _periodLabel(period),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),

                  onChanged: isRefreshingAnalytics
                      ? null
                      : (AnalyticsPeriod? value) async {
                          if (value == null || value == selectedPeriod) {
                            return;
                          }

                          setState(() {
                            selectedPeriod = value;
                          });

                          await _loadAnalytics();
                        },
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
    if (isGuest == null || isLoading) {
      return const AnalyticsLoadingSkeleton();
    }

    // Guest users don't need an AnalyticsSummary.
    if (isGuest!) {
      return AppScaffold(
        showOfflineBanner: false,
        appBar: const AdaptiveAppBar(title: null),
        body: buildEmptyState(context, EmptyStateType.analyticsGuest),
      );
    }

    final analytics = summary;

    // Registered user but no analytics data could be loaded.
    if (analytics == null) {
      return AppScaffold(
        showOfflineBanner: false,
        appBar: const AdaptiveAppBar(title: null),
        body: buildEmptyState(context, EmptyStateType.analyticsNoData),
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
      showOfflineBanner: false,
      appBar: const AdaptiveAppBar(title: null),
      body: hasNoData
          ? buildEmptyState(context, EmptyStateType.analyticsNoData)
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
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
                        _buildPeriodSelector(context),

                        SizedBox(height: smallSpacing),

                        if (hasPartialData)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: buildEmptyState(
                              context,
                              EmptyStateType.analyticsInProgress,
                            ),
                          ),

                        const SizedBox(height: 4),

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
                          icon: Icons.pie_chart,
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
                          icon: Icons.flag,
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
                          icon: Icons.show_chart,
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
                        SizedBox(height: smallSpacing),
                        Center(
                          child: Text(
                            '${analytics.completedGoals} of ${analytics.totalGoals} goals completed',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        SizedBox(height: sectionSpacing * 1.2),

                        const AnalyticsSectionHeader(
                          icon: Icons.lightbulb,
                          title: "Smart Insights",
                        ),

                        SizedBox(height: smallSpacing),

                        SmartInsightsCard(insights: analytics.insights),
                        SizedBox(height: sectionSpacing * 1.2),

                        const AnalyticsSectionHeader(
                          icon: Icons.description,
                          title: "Reports Center",
                        ),

                        const SizedBox(height: 10),

                        Text(
                          '${reports.length} Reports Generated',
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
