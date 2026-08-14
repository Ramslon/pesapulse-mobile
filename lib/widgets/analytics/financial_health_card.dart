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

    final spacing = ResponsiveHelper.spacing(context);
    final cardPadding = ResponsiveHelper.cardPadding(context);

    final score = healthScore.clamp(0.0, 100.0);

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
            colors: [color, Color.lerp(color, Colors.black, 0.16) ?? color],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.20),
              blurRadius: desktop ? 22 : 18,
              offset: const Offset(0, 8),
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
                    ? 26
                    : compact
                    ? 18
                    : 24,
              ),

              _buildScoreSection(
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
                    ? 26
                    : compact
                    ? 18
                    : 22,
              ),

              _buildRecommendation(
                context,
                compact: compact,
                desktop: desktop,
                spacing: spacing,
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
    required double spacing,
  }) {
    final iconBox = desktop
        ? 52.0
        : compact
        ? 38.0
        : 46.0;

    final iconSize = desktop
        ? 27.0
        : compact
        ? 20.0
        : 25.0;

    final titleSize = desktop
        ? 21.0
        : compact
        ? 16.0
        : 20.0;

    final subtitleSize = desktop
        ? 13.0
        : compact
        ? 10.5
        : 12.5;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: iconBox,
          height: iconBox,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(compact ? 11 : 15),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
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
                  fontWeight: FontWeight.bold,
                  height: 1.15,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                'Your current financial wellbeing',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: subtitleSize,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),

        SizedBox(width: compact ? 6 : 10),

        Flexible(
          flex: 0,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: compact ? 90 : 130),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 11,
                vertical: compact ? 5 : 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.16)),
              ),
              child: Text(
                healthStatus,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 10 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreSection(
    BuildContext context, {
    required double score,
    required bool compact,
    required bool dense,
    required bool landscape,
    required bool tablet,
    required bool desktop,
    required double spacing,
  }) {
    final scoreCircleSize = desktop
        ? 126.0
        : tablet
        ? 116.0
        : compact
        ? 88.0
        : landscape
        ? 96.0
        : 108.0;

    final scoreSize = desktop
        ? 46.0
        : compact
        ? 30.0
        : 42.0;

    final strokeWidth = compact ? 7.0 : 9.0;

    // On very narrow compact screens, vertical layout gives
    // the score enough room and prevents text from being squeezed.
    final stackScoreContent = compact && !landscape;

    if (stackScoreContent) {
      return Column(
        children: [
          Center(
            child: _buildScoreCircle(
              score: score,
              size: scoreCircleSize,
              scoreSize: scoreSize,
              strokeWidth: strokeWidth,
            ),
          ),

          SizedBox(height: spacing),

          _buildScoreInformation(
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
        _buildScoreCircle(
          score: score,
          size: scoreCircleSize,
          scoreSize: scoreSize,
          strokeWidth: strokeWidth,
        ),

        SizedBox(
          width: desktop
              ? 24
              : compact
              ? 12
              : 20,
        ),

        Expanded(
          child: _buildScoreInformation(
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

  Widget _buildScoreCircle({
    required double score,
    required double size,
    required double scoreSize,
    required double strokeWidth,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
        tween: Tween<double>(begin: 0, end: score / 100),
        builder: (context, value, child) {
          return CustomPaint(
            painter: _HealthScorePainter(
              progress: value,
              color: Colors.white,
              trackColor: Colors.white.withOpacity(0.14),
              strokeWidth: strokeWidth,
            ),
            child: Center(
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: 0, end: score),
                builder: (_, animatedScore, __) {
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      animatedScore.toStringAsFixed(0),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: scoreSize,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreInformation(
    BuildContext context, {
    required double score,
    required bool compact,
    required bool desktop,
    required bool centered,
  }) {
    final labelSize = desktop
        ? 14.0
        : compact
        ? 11.0
        : 13.0;

    final valueSize = desktop
        ? 21.0
        : compact
        ? 16.0
        : 18.0;

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
          'Health Score',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: Colors.white70,
            fontSize: labelSize,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          '${score.toStringAsFixed(0)} / 100',
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: Colors.white,
            fontSize: valueSize,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          _scoreDescription(score),
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            color: Colors.white70,
            fontSize: descriptionSize,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendation(
    BuildContext context, {
    required bool compact,
    required bool desktop,
    required double spacing,
  }) {
    final iconBox = compact ? 30.0 : 34.0;
    final iconSize = compact ? 17.0 : 19.0;

    final titleSize = desktop
        ? 14.0
        : compact
        ? 11.0
        : 13.0;

    final recommendationSize = desktop
        ? 14.0
        : compact
        ? 11.5
        : 13.5;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 11 : 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(compact ? 14 : 17),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: iconBox,
            height: iconBox,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: Colors.white,
              size: iconSize,
            ),
          ),

          SizedBox(width: spacing),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommendation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  recommendation.isEmpty
                      ? 'Keep monitoring your spending and financial goals.'
                      : recommendation,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: recommendationSize,
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
      return 'You are maintaining a strong financial position.';
    }

    if (score >= 60) {
      return 'Your finances are generally healthy with some room to improve.';
    }

    if (score >= 40) {
      return 'Your finances are fair. A few improvements could make a difference.';
    }

    return 'Consider reviewing your spending and savings habits.';
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

    canvas.drawCircle(center, radius, trackPaint);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HealthScorePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
