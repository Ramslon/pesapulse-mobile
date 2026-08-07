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

  bool isLoading = true;

  bool isGuest = false;
  final AnalyticsRepository analyticsRepository = AnalyticsRepository();

  late final AnalyticsService analyticsService = AnalyticsService(
    analyticsRepository,
  );

  late ConnectivityProvider _network;

  @override
  void initState() {
    super.initState();
    loadSessionState();
    _network = context.read<ConnectivityProvider>();

    _network.addListener(_onConnectivityChanged);

    _loadAnalytics();

    loadReports();
  }

  Future<void> loadSessionState() async {
    isGuest = await SessionService.isGuest();

    if (mounted) {
      setState(() {});
    }
  }

  void _onConnectivityChanged() {
    if (_network.isOnline) {
      _loadAnalytics();
    }
  }

  @override
  void dispose() {
    _network.removeListener(_onConnectivityChanged);

    super.dispose();
  }

  void _updateSummary(AnalyticsSummary result) {
    summary = result;
    isLoading = false;
  }

  Future<void> _loadAnalytics() async {
    try {
      final result = await analyticsService.loadAnalytics();

      if (!mounted) return;

      setState(() {
        _updateSummary(result);
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
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

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final sectionSpacing = AnalyticsLayoutHelper.sectionSpacing(context);

    final chartHeight = AnalyticsLayoutHelper.chartHeight(context);

    final contentPadding = AnalyticsLayoutHelper.contentPadding(context);

    final smallSpacing = AnalyticsLayoutHelper.smallSpacing(context);

    if (isLoading) {
      return const AnalyticsLoadingSkeleton();
    }

    final analytics = summary;

    if (analytics == null) {
      return const AnalyticsLoadingSkeleton();
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
      body: isGuest
          ? buildEmptyState(context, EmptyStateType.analyticsGuest)
          : hasNoData
          ? buildEmptyState(context, EmptyStateType.analyticsNoData)
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                key: const PageStorageKey("analytics"),

                padding: EdgeInsets.all(contentPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
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
                    const SizedBox(height: AnalyticsLayoutHelper.cardSpacing),
                    ExportReportsSection(
                      isGuest: isGuest,

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

                    analytics.categoryTotals.isEmpty
                        ? buildEmptyState(
                            context,
                            EmptyStateType.categories,
                            isGuest: isGuest,
                          )
                        : CategoryBreakdownChart(
                            categoryTotals: analytics.categoryTotals,
                            chartHeight: chartHeight,
                          ),
                    SizedBox(height: sectionSpacing * 1.2),

                    const AnalyticsSectionHeader(
                      icon: Icons.flag,
                      title: "Goal Status",
                    ),
                    SizedBox(height: smallSpacing),

                    GoalStatusChart(
                      completedGoals: analytics.completedGoals,
                      activeGoals: analytics.activeGoals,
                      totalGoals: analytics.totalGoals,
                      chartHeight: chartHeight,
                    ),

                    SizedBox(height: sectionSpacing * 1.2),

                    const AnalyticsSectionHeader(
                      icon: Icons.show_chart,
                      title: "Monthly Spending Trend",
                    ),

                    const SizedBox(height: AnalyticsLayoutHelper.cardSpacing),

                    MonthlySpendingChart(
                      monthlyTotals: analytics.monthlyTotals,
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
    );
  }
}
