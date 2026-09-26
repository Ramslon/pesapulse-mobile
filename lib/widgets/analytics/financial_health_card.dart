import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../fade_slide_animation.dart';
import '../../utils/responsive_helper.dart';

class FinancialHealthCard extends StatelessWidget {
  final double healthScore;
  final String healthStatus;
  final String recommendation;
  final Color color;
  final IconData icon;

  const FinancialHealthCard({
    super.key,
    required this.healthScore,
    required this.healthStatus,
    required this.recommendation,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final dense = ResponsiveHelper.useDenseVerticalLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final cardPadding = ResponsiveHelper.cardPadding(context);
    final spacing = ResponsiveHelper.spacing(context);

    final score = healthScore.clamp(0.0, 100.0).toDouble();

    final radius = desktop
        ? 28.0
        : compact
        ? 18.0
        : 24.0;

    final padding = desktop
        ? math.max(cardPadding, 24.0)
        : compact
        ? math.min(cardPadding, 16.0)
        : cardPadding;

    return FadeSlideAnimation(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, Color.lerp(color, Colors.black, 0.18) ?? color],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.22),
              blurRadius: desktop ? 24 : 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(
                context,
                compact: compact,
                desktop: desktop,
                spacing: spacing,
              ),

              SizedBox(
                height: desktop
                    ? 28
                    : compact
                    ? 18
                    : 24,
              ),

              _buildMainContent(
                context,
                score: score,
                compact: compact,
                dense: dense,
                landscape: landscape,
                tablet: tablet,
                desktop: desktop,
                spacing: spacing,
              ),

              SizedBox(
                height: desktop
                    ? 24
                    : compact
                    ? 16
                    : 20,
              ),

              _buildRecommendation(context, compact: compact, desktop: desktop),
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
    required double spacing,
  }) {
    final iconBox = desktop
        ? 52.0
        : compact
        ? 38.0
        : 46.0;

    final iconSize = desktop
        ? 26.0
        : compact
        ? 20.0
        : 24.0;

    final titleSize = desktop
        ? 21.0
        : compact
        ? 16.0
        : 19.0;

    final subtitleSize = desktop
        ? 13.0
        : compact
        ? 10.5
        : 12.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: iconBox,
          height: iconBox,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(compact ? 12 : 15),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
          ),
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),

        SizedBox(width: spacing),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Financial Health',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'A snapshot of your financial wellbeing',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.70),
                  fontSize: subtitleSize,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: compact ? 92 : 125),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 11,
              vertical: compact ? 5 : 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
            ),
            child: Text(
              healthStatus,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 9.5 : 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(
    BuildContext context, {
    required double score,
    required bool compact,
    required bool dense,
    required bool landscape,
    required bool tablet,
    required bool desktop,
    required double spacing,
  }) {
    final stackLayout = compact && !landscape;

    final circleSize = desktop
        ? 132.0
        : tablet
        ? 122.0
        : compact
        ? 94.0
        : landscape
        ? 102.0
        : 112.0;

    final scoreFontSize = desktop
        ? 46.0
        : tablet
        ? 42.0
        : compact
        ? 32.0
        : 40.0;

    final strokeWidth = compact ? 7.0 : 9.0;

    if (stackLayout) {
      return Column(
        children: [
          Center(
            child: _buildScoreGauge(
              score: score,
              size: circleSize,
              scoreFontSize: scoreFontSize,
              strokeWidth: strokeWidth,
            ),
          ),

          SizedBox(height: dense ? 14 : 18),

          _buildHealthSummary(
            context,
            score: score,
            compact: compact,
            desktop: desktop,
            centered: true,
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildScoreGauge(
          score: score,
          size: circleSize,
          scoreFontSize: scoreFontSize,
          strokeWidth: strokeWidth,
        ),

        SizedBox(
          width: desktop
              ? 26
              : compact
              ? 14
              : 20,
        ),

        Expanded(
          child: _buildHealthSummary(
            context,
            score: score,
            compact: compact,
            desktop: desktop,
            centered: false,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreGauge({
    required double score,
    required double size,
    required double scoreFontSize,
    required double strokeWidth,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: 0, end: score / 100),
        builder: (context, progress, child) {
          return CustomPaint(
            painter: _HealthScorePainter(
              progress: progress,
              color: Colors.white,
              trackColor: Colors.white.withOpacity(0.13),
              strokeWidth: strokeWidth,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(begin: 0, end: score),
                      builder: (_, animatedScore, __) {
                        return SizedBox(
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              animatedScore.toStringAsFixed(0),
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: scoreFontSize,
                                fontWeight: FontWeight.w900,
                                height: 0.95,
                                letterSpacing: -1.0,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'out of 100',
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.68),
                        fontSize: size < 100 ? 8.5 : 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHealthSummary(
    BuildContext context, {
    required double score,
    required bool compact,
    required bool desktop,
    required bool centered,
  }) {
    final titleSize = desktop
        ? 14.0
        : compact
        ? 10.5
        : 12.0;

    final statusSize = desktop
        ? 24.0
        : compact
        ? 18.0
        : 21.0;

    final descriptionSize = desktop
        ? 13.5
        : compact
        ? 11.0
        : 12.5;

    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR FINANCIAL POSITION',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: Colors.white.withOpacity(0.62),
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          healthStatus,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: Colors.white,
            fontSize: statusSize,
            fontWeight: FontWeight.w900,
            height: 1.08,
            letterSpacing: -0.4,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          _scoreDescription(score),
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: Colors.white.withOpacity(0.72),
            fontSize: descriptionSize,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 12),

        _buildScoreRangeIndicator(
          context,
          score: score,
          compact: compact,
          centered: centered,
        ),
      ],
    );
  }

  Widget _buildScoreRangeIndicator(
    BuildContext context, {
    required double score,
    required bool compact,
    required bool centered,
  }) {
    final label = _scoreRangeLabel(score);

    return Align(
      alignment: centered ? Alignment.center : Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 9 : 11,
          vertical: compact ? 5 : 6,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.11),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 6 : 7,
              height: compact ? 6 : 7,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 9.5 : 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendation(
    BuildContext context, {
    required bool compact,
    required bool desktop,
  }) {
    final iconBox = desktop
        ? 38.0
        : compact
        ? 30.0
        : 34.0;

    final iconSize = desktop
        ? 20.0
        : compact
        ? 16.0
        : 18.0;

    final titleSize = desktop
        ? 13.5
        : compact
        ? 10.5
        : 12.0;

    final bodySize = desktop
        ? 14.0
        : compact
        ? 11.0
        : 12.5;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        desktop
            ? 15
            : compact
            ? 11
            : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(compact ? 14 : 17),
        border: Border.all(color: Colors.white.withOpacity(0.11)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: iconBox,
            height: iconBox,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: iconSize,
            ),
          ),

          SizedBox(width: compact ? 9 : 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next best move',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  recommendation.trim().isEmpty
                      ? 'Keep monitoring your spending, savings, and budget progress.'
                      : recommendation,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: bodySize,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _scoreDescription(double score) {
    if (score >= 80) {
      return 'Your finances are in a strong position. Keep protecting the habits that are working.';
    }

    if (score >= 60) {
      return 'Your finances are generally healthy, with a few areas that could be improved.';
    }

    if (score >= 40) {
      return 'Your finances are fairly balanced, but there is room to strengthen your spending and saving habits.';
    }

    if (score >= 20) {
      return 'Your finances need attention. Focus on controlling spending and rebuilding financial stability.';
    }

    return 'Your current position needs attention. Review spending, budget pressure, and savings progress.';
  }

  String _scoreRangeLabel(double score) {
    if (score >= 80) {
      return 'Strong financial position';
    }

    if (score >= 60) {
      return 'Generally healthy';
    }

    if (score >= 40) {
      return 'Room to improve';
    }

    if (score >= 20) {
      return 'Needs attention';
    }

    return 'Critical attention needed';
  }
}

class _HealthScorePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const _HealthScorePainter({
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
  bool shouldRepaint(covariant _HealthScorePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
