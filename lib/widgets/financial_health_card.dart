import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/responsive_helper.dart';

class FinancialHealthCard extends StatelessWidget {
  final int score;
  final String label;

  const FinancialHealthCard({
    super.key,
    required this.score,
    required this.label,
  });

  Color get scoreColor {
    if (score >= 80) {
      return const Color(0xFF16A34A);
    }

    if (score >= 60) {
      return const Color(0xFF65A30D);
    }

    if (score >= 40) {
      return const Color(0xFFF59E0B);
    }

    if (score >= 20) {
      return const Color(0xFFF97316);
    }

    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final compact = ResponsiveHelper.useCompactLayout(context);

    final tablet = ResponsiveHelper.isTablet(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final safeScore = score.clamp(0, 100);

    final horizontalLayout = landscape && !compact;

    final cardPadding = desktop
        ? 20.0
        : tablet
        ? 18.0
        : compact
        ? 12.0
        : 16.0;

    final radius = desktop
        ? 22.0
        : compact
        ? 16.0
        : 19.0;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.97, end: 1.0),
      builder: (_, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: scoreColor.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: scoreColor.withOpacity(
                theme.brightness == Brightness.dark ? 0.08 : 0.055,
              ),
              blurRadius: desktop ? 20 : 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, compact: compact, desktop: desktop),

              SizedBox(
                height: desktop
                    ? 18
                    : compact
                    ? 12
                    : 15,
              ),

              if (horizontalLayout)
                _buildLandscapeContent(
                  context,
                  safeScore: safeScore,
                  compact: compact,
                  desktop: desktop,
                )
              else
                _buildPortraitContent(
                  context,
                  safeScore: safeScore,
                  compact: compact,
                  tablet: tablet,
                  desktop: desktop,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required bool compact,
    required bool desktop,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final iconBoxSize = desktop
        ? 42.0
        : compact
        ? 34.0
        : 38.0;

    final iconSize = desktop
        ? 21.0
        : compact
        ? 17.0
        : 19.0;

    final titleSize = desktop
        ? 17.0
        : compact
        ? 13.0
        : 15.5;

    final subtitleSize = desktop
        ? 11.5
        : compact
        ? 9.5
        : 10.5;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: iconBoxSize,
          height: iconBoxSize,
          decoration: BoxDecoration(
            color: scoreColor.withOpacity(0.09),
            borderRadius: BorderRadius.circular(compact ? 10 : 12),
            border: Border.all(color: scoreColor.withOpacity(0.10)),
          ),
          child: Icon(
            Icons.health_and_safety_rounded,
            color: scoreColor,
            size: iconSize,
          ),
        ),

        SizedBox(width: compact ? 9 : 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Financial Health',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                'Your current financial wellness score',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.68),
                  fontSize: subtitleSize,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        _buildStatusBadge(context, compact: compact),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context, {required bool compact}) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 82 : 105),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 9,
          vertical: compact ? 4 : 5,
        ),
        decoration: BoxDecoration(
          color: scoreColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: scoreColor,
            fontSize: compact ? 8.5 : 9.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitContent(
    BuildContext context, {
    required int safeScore,
    required bool compact,
    required bool tablet,
    required bool desktop,
  }) {
    final gaugeSize = desktop
        ? 165.0
        : tablet
        ? 150.0
        : compact
        ? 112.0
        : 140.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildGauge(
          context,
          score: safeScore,
          size: gaugeSize,
          compact: compact,
          tablet: tablet,
          desktop: desktop,
        ),

        SizedBox(height: compact ? 12 : 15),

        _buildScoreSummary(
          context,
          score: safeScore,
          compact: compact,
          desktop: desktop,
          centered: true,
        ),

        SizedBox(height: compact ? 12 : 15),

        _buildScoreIndicator(
          context,
          score: safeScore,
          compact: compact,
          desktop: desktop,
        ),

        SizedBox(height: compact ? 10 : 12),

        _buildDescription(
          context,
          score: safeScore,
          compact: compact,
          desktop: desktop,
        ),
      ],
    );
  }

  Widget _buildLandscapeContent(
    BuildContext context, {
    required int safeScore,
    required bool compact,
    required bool desktop,
  }) {
    final gaugeSize = desktop
        ? 128.0
        : compact
        ? 94.0
        : 112.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildGauge(
          context,
          score: safeScore,
          size: gaugeSize,
          compact: compact,
          tablet: false,
          desktop: desktop,
        ),

        SizedBox(
          width: desktop
              ? 18
              : compact
              ? 10
              : 14,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScoreSummary(
                context,
                score: safeScore,
                compact: compact,
                desktop: desktop,
                centered: false,
              ),

              SizedBox(height: compact ? 9 : 11),

              _buildScoreIndicator(
                context,
                score: safeScore,
                compact: compact,
                desktop: desktop,
              ),

              SizedBox(height: compact ? 8 : 10),

              _buildDescription(
                context,
                score: safeScore,
                compact: compact,
                desktop: desktop,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGauge(
    BuildContext context, {
    required int score,
    required double size,
    required bool compact,
    required bool tablet,
    required bool desktop,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final strokeWidth = desktop
        ? 13.0
        : tablet
        ? 11.0
        : compact
        ? 8.0
        : 10.0;

    final scoreSize = desktop
        ? 40.0
        : tablet
        ? 36.0
        : compact
        ? 27.0
        : 34.0;

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: 0, end: score.toDouble()),
        builder: (context, value, child) {
          return CustomPaint(
            painter: _FinancialHealthPainter(
              progress: value / 100,
              color: scoreColor,
              trackColor: colorScheme.surfaceContainerHighest.withOpacity(0.80),
              strokeWidth: strokeWidth,
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(strokeWidth + 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value.toStringAsFixed(0),
                    maxLines: 1,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: scoreSize,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      letterSpacing: -1.0,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreSummary(
    BuildContext context, {
    required int score,
    required bool compact,
    required bool desktop,
    required bool centered,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final titleSize = desktop
        ? 10.5
        : compact
        ? 8.5
        : 9.5;

    final scoreSize = desktop
        ? 19.0
        : compact
        ? 14.0
        : 17.0;

    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          'OVERALL SCORE',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant.withOpacity(0.60),
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          '$score / 100',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: scoreColor,
            fontSize: scoreSize,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreIndicator(
    BuildContext context, {
    required int score,
    required bool compact,
    required bool desktop,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 11,
        vertical: compact ? 8 : 9,
      ),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(
          Theme.of(context).brightness == Brightness.dark ? 0.08 : 0.045,
        ),
        borderRadius: BorderRadius.circular(compact ? 11 : 13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Health level',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.65),
                    fontSize: desktop
                        ? 10.5
                        : compact
                        ? 8.5
                        : 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${score.toString()}%',
                style: TextStyle(
                  color: scoreColor,
                  fontSize: desktop
                      ? 10.5
                      : compact
                      ? 8.5
                      : 9.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          SizedBox(height: compact ? 6 : 7),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0, end: score / 100),
              builder: (_, value, __) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: compact ? 5 : 6,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription(
    BuildContext context, {
    required int score,
    required bool compact,
    required bool desktop,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      _scoreDescription(score),
      textAlign: ResponsiveHelper.isLandscape(context)
          ? TextAlign.start
          : TextAlign.center,
      style: TextStyle(
        color: colorScheme.onSurfaceVariant.withOpacity(0.66),
        fontSize: desktop
            ? 11.5
            : compact
            ? 9.5
            : 10.5,
        height: 1.4,
      ),
    );
  }

  String _scoreDescription(int score) {
    if (score >= 80) {
      return 'Excellent financial management. Keep protecting the habits that are working.';
    }

    if (score >= 60) {
      return 'Good financial health with some room to strengthen your money habits.';
    }

    if (score >= 40) {
      return 'Your finances are fairly balanced, but there is room to improve consistency.';
    }

    if (score >= 20) {
      return 'Your financial health needs attention. Review spending and budget pressure.';
    }

    return 'Your financial health needs significant attention. Start with your budget and spending habits.';
  }
}

class _FinancialHealthPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const _FinancialHealthPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(center, radius, trackPaint);

    final normalizedProgress = progress.clamp(0.0, 1.0);

    if (normalizedProgress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * normalizedProgress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FinancialHealthPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
