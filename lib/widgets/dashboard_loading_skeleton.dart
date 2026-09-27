import 'package:flutter/material.dart';

import '../utils/responsive_helper.dart';

class DashboardLoadingSkeleton extends StatefulWidget {
  const DashboardLoadingSkeleton({super.key});

  @override
  State<DashboardLoadingSkeleton> createState() =>
      _DashboardLoadingSkeletonState();
}

class _DashboardLoadingSkeletonState extends State<DashboardLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _baseColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return brightness == Brightness.dark
        ? Colors.white.withOpacity(0.07)
        : Colors.grey.shade200;
  }

  Color _highlightColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return brightness == Brightness.dark
        ? Colors.white.withOpacity(0.15)
        : Colors.grey.shade100;
  }

  Widget _shimmer({
    required BuildContext context,
    double height = 20,
    double width = double.infinity,
    BorderRadius? borderRadius,
  }) {
    final baseColor = _baseColor(context);
    final highlightColor = _highlightColor(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: borderRadius ?? BorderRadius.circular(10),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                (_controller.value - 0.35).clamp(0.0, 1.0),
                _controller.value,
                (_controller.value + 0.35).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionLabelSkeleton(BuildContext context, {double width = 150}) {
    return _shimmer(
      context: context,
      width: width,
      height: 17,
      borderRadius: BorderRadius.circular(7),
    );
  }

  Widget _dashboardKpiSkeleton(BuildContext context, {required double height}) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.07),
        ),
      ),
      padding: EdgeInsets.all(compact ? 12 : 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _shimmer(
                context: context,
                width: compact ? 34 : 38,
                height: compact ? 34 : 38,
                borderRadius: BorderRadius.circular(compact ? 10 : 11),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _shimmer(
                  context: context,
                  height: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),

          const Spacer(),

          _shimmer(
            context: context,
            width: compact ? 72 : 88,
            height: 10,
            borderRadius: BorderRadius.circular(5),
          ),

          const SizedBox(height: 7),

          _shimmer(
            context: context,
            width: compact ? 110 : 135,
            height: compact ? 22 : 25,
            borderRadius: BorderRadius.circular(7),
          ),

          const SizedBox(height: 10),

          _shimmer(
            context: context,
            width: 34,
            height: 3,
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      ),
    );
  }

  Widget _budgetSkeleton(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 17),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _shimmer(
                context: context,
                width: 38,
                height: 38,
                borderRadius: BorderRadius.circular(11),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmer(
                      context: context,
                      width: 125,
                      height: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 6),
                    _shimmer(
                      context: context,
                      width: 90,
                      height: 9,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ],
                ),
              ),
              _shimmer(
                context: context,
                width: 58,
                height: 22,
                borderRadius: BorderRadius.circular(20),
              ),
            ],
          ),

          SizedBox(height: compact ? 18 : 20),

          _shimmer(
            context: context,
            width: 95,
            height: 9,
            borderRadius: BorderRadius.circular(5),
          ),

          const SizedBox(height: 7),

          _shimmer(
            context: context,
            width: compact ? 140 : 165,
            height: compact ? 28 : 31,
            borderRadius: BorderRadius.circular(8),
          ),

          SizedBox(height: compact ? 18 : 20),

          _shimmer(
            context: context,
            height: 8,
            borderRadius: BorderRadius.circular(20),
          ),

          SizedBox(height: compact ? 14 : 16),

          Row(
            children: [
              Expanded(child: _metricSkeleton(context)),
              const SizedBox(width: 12),
              Expanded(child: _metricSkeleton(context)),
              const SizedBox(width: 12),
              Expanded(child: _metricSkeleton(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _shimmer(
          context: context,
          width: 58,
          height: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 6),
        _shimmer(
          context: context,
          width: 78,
          height: 13,
          borderRadius: BorderRadius.circular(5),
        ),
      ],
    );
  }

  Widget _healthSkeleton(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 17),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.07),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _shimmer(
            context: context,
            width: compact ? 72 : 82,
            height: compact ? 72 : 82,
            borderRadius: BorderRadius.circular(100),
          ),

          SizedBox(width: compact ? 13 : 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmer(
                  context: context,
                  width: 135,
                  height: 10,
                  borderRadius: BorderRadius.circular(5),
                ),

                const SizedBox(height: 8),

                _shimmer(
                  context: context,
                  width: 100,
                  height: 20,
                  borderRadius: BorderRadius.circular(6),
                ),

                const SizedBox(height: 9),

                _shimmer(
                  context: context,
                  height: 9,
                  borderRadius: BorderRadius.circular(5),
                ),

                const SizedBox(height: 5),

                _shimmer(
                  context: context,
                  width: compact ? 145 : 185,
                  height: 9,
                  borderRadius: BorderRadius.circular(5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightSkeleton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmer(
            context: context,
            width: 34,
            height: 34,
            borderRadius: BorderRadius.circular(10),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmer(
                  context: context,
                  width: 100,
                  height: 9,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 7),
                _shimmer(
                  context: context,
                  height: 8,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 5),
                _shimmer(
                  context: context,
                  width: 150,
                  height: 8,
                  borderRadius: BorderRadius.circular(5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _expenseSkeleton(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 8 : 9),
      child: Row(
        children: [
          _shimmer(
            context: context,
            width: compact ? 42 : 46,
            height: compact ? 42 : 46,
            borderRadius: BorderRadius.circular(14),
          ),

          SizedBox(width: compact ? 10 : 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmer(
                  context: context,
                  width: compact ? 110 : 135,
                  height: 11,
                  borderRadius: BorderRadius.circular(5),
                ),

                const SizedBox(height: 7),

                _shimmer(
                  context: context,
                  width: compact ? 125 : 155,
                  height: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),

          SizedBox(width: compact ? 7 : 10),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _shimmer(
                context: context,
                width: compact ? 64 : 78,
                height: 11,
                borderRadius: BorderRadius.circular(5),
              ),
              const SizedBox(height: 6),
              _shimmer(
                context: context,
                width: 14,
                height: 14,
                borderRadius: BorderRadius.circular(7),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);

    final horizontalPadding = compact
        ? 16.0
        : landscape
        ? 20.0
        : 20.0;

    final maxContentWidth = landscape ? 1100.0 : double.infinity;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                compact ? 16 : 20,
                horizontalPadding,
                20,
              ),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─────────────────────────────
                    // Header
                    // ─────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _shimmer(
                                context: context,
                                width: compact ? 150 : 185,
                                height: compact ? 10 : 11,
                                borderRadius: BorderRadius.circular(5),
                              ),

                              const SizedBox(height: 9),

                              _shimmer(
                                context: context,
                                width: compact ? 180 : 230,
                                height: compact ? 25 : 29,
                                borderRadius: BorderRadius.circular(7),
                              ),

                              const SizedBox(height: 8),

                              _shimmer(
                                context: context,
                                width: compact ? 215 : 270,
                                height: 10,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ],
                          ),
                        ),

                        _shimmer(
                          context: context,
                          width: compact ? 40 : 44,
                          height: compact ? 40 : 44,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ],
                    ),

                    SizedBox(height: compact ? 22 : 26),

                    // ─────────────────────────────
                    // Statistics
                    // ─────────────────────────────
                    _sectionLabelSkeleton(context, width: 130),

                    SizedBox(height: compact ? 10 : 12),

                    if (landscape)
                      Row(
                        children: [
                          Expanded(
                            child: _dashboardKpiSkeleton(context, height: 125),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dashboardKpiSkeleton(context, height: 125),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dashboardKpiSkeleton(context, height: 125),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dashboardKpiSkeleton(context, height: 125),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _dashboardKpiSkeleton(
                                  context,
                                  height: 122,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _dashboardKpiSkeleton(
                                  context,
                                  height: 122,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _dashboardKpiSkeleton(
                                  context,
                                  height: 122,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _dashboardKpiSkeleton(
                                  context,
                                  height: 122,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                    SizedBox(height: compact ? 20 : 24),

                    // ─────────────────────────────
                    // Budget
                    // ─────────────────────────────
                    _sectionLabelSkeleton(context, width: 145),

                    const SizedBox(height: 10),

                    _budgetSkeleton(context),

                    SizedBox(height: compact ? 20 : 24),

                    // ─────────────────────────────
                    // Financial health
                    // ─────────────────────────────
                    _sectionLabelSkeleton(context, width: 155),

                    const SizedBox(height: 10),

                    _healthSkeleton(context),

                    SizedBox(height: compact ? 20 : 24),

                    // ─────────────────────────────
                    // Smart insights
                    // ─────────────────────────────
                    Row(
                      children: [
                        _sectionLabelSkeleton(context, width: 135),
                        const Spacer(),
                        _shimmer(
                          context: context,
                          width: 42,
                          height: 22,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Column(
                      children: [
                        _insightSkeleton(context),
                        const SizedBox(height: 8),
                        _insightSkeleton(context),
                      ],
                    ),

                    SizedBox(height: compact ? 20 : 24),

                    // ─────────────────────────────
                    // Recent activity
                    // ─────────────────────────────
                    Row(
                      children: [
                        _sectionLabelSkeleton(context, width: 135),
                        const Spacer(),
                        _shimmer(
                          context: context,
                          width: 62,
                          height: 10,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Column(
                      children: List.generate(
                        4,
                        (_) => _expenseSkeleton(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
