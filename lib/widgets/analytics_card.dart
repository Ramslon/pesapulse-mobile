import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class AnalyticsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const AnalyticsCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight;
        final hasBoundedWidth = constraints.hasBoundedWidth;

        final width = hasBoundedWidth
            ? constraints.maxWidth
            : ResponsiveHelper.width(context);

        // ─────────────────────────────────────
        // Responsive sizing
        // ─────────────────────────────────────

        final veryNarrow = width < 155;
        final narrow = width < 190;

        final effectiveCompact = compact || landscape || veryNarrow || narrow;

        final padding = _calculatePadding(
          compact: effectiveCompact,
          tablet: tablet,
          desktop: desktop,
          veryNarrow: veryNarrow,
        );

        final iconBoxSize = _calculateIconBoxSize(
          compact: effectiveCompact,
          tablet: tablet,
          desktop: desktop,
          veryNarrow: veryNarrow,
        );

        final iconSize = _calculateIconSize(
          compact: effectiveCompact,
          tablet: tablet,
          desktop: desktop,
          veryNarrow: veryNarrow,
        );

        final titleSize = _calculateTitleSize(
          compact: effectiveCompact,
          tablet: tablet,
          desktop: desktop,
          veryNarrow: veryNarrow,
        );

        final valueSize = _calculateValueSize(
          compact: effectiveCompact,
          tablet: tablet,
          desktop: desktop,
          veryNarrow: veryNarrow,
        );

        final spacing = _calculateSpacing(
          compact: effectiveCompact,
          desktop: desktop,
          veryNarrow: veryNarrow,
        );

        final radius = desktop
            ? 22.0
            : tablet
            ? 20.0
            : effectiveCompact
            ? 16.0
            : 20.0;

        final dividerHeight = veryNarrow
            ? 5.0
            : effectiveCompact
            ? 8.0
            : 12.0;

        final cardContent = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─────────────────────────────────
            // Icon
            // ─────────────────────────────────
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: iconSize),
            ),

            SizedBox(height: spacing),

            // ─────────────────────────────────
            // Title
            // ─────────────────────────────────
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(.65),
                fontWeight: FontWeight.w600,
                fontSize: titleSize,
                letterSpacing: .1,
                height: 1.1,
              ),
            ),

            // ─────────────────────────────────
            // Divider
            // ─────────────────────────────────
            Divider(
              color: colorScheme.onSurface.withOpacity(.08),
              thickness: .8,
              height: dividerHeight,
            ),

            // ─────────────────────────────────
            // Amount
            // ─────────────────────────────────
            _buildValue(
              context,
              theme,
              valueSize: valueSize,
              hasBoundedHeight: hasBoundedHeight,
            ),
          ],
        );

        return Card(
          elevation: effectiveCompact ? 1 : 2,
          shadowColor: color.withOpacity(.12),
          surfaceTintColor: color.withOpacity(.025),
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Padding(padding: EdgeInsets.all(padding), child: cardContent),
        );
      },
    );
  }

  // ─────────────────────────────────────────
  // VALUE
  // ─────────────────────────────────────────

  Widget _buildValue(
    BuildContext context,
    ThemeData theme, {
    required double valueSize,
    required bool hasBoundedHeight,
  }) {
    final valueWidget = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animation, child) {
        return Opacity(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(0, 6 * (1 - animation)),
            child: child,
          ),
        );
      },
      child: SizedBox(
        width: double.infinity,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            softWrap: false,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: valueSize,
              height: 1.1,
              letterSpacing: -.25,
            ),
          ),
        ),
      ),
    );

    // If the card has a fixed height, allow the
    // amount to consume only the remaining space.
    //
    // This prevents bottom overflow on tablet/desktop
    // cards that have an explicit height.
    if (hasBoundedHeight) {
      return Flexible(
        fit: FlexFit.loose,
        child: Align(alignment: Alignment.bottomLeft, child: valueWidget),
      );
    }

    // On mobile the card may have natural height.
    //
    // Do NOT use Expanded/Flexible here because the
    // card can be inside an unbounded-height Column.
    return Align(alignment: Alignment.centerLeft, child: valueWidget);
  }

  // ─────────────────────────────────────────
  // PADDING
  // ─────────────────────────────────────────

  double _calculatePadding({
    required bool compact,
    required bool tablet,
    required bool desktop,
    required bool veryNarrow,
  }) {
    if (veryNarrow) {
      return 10;
    }

    if (desktop) {
      return 18;
    }

    if (tablet) {
      return 16;
    }

    if (compact) {
      return 12;
    }

    return 15;
  }

  // ─────────────────────────────────────────
  // ICON BOX
  // ─────────────────────────────────────────

  double _calculateIconBoxSize({
    required bool compact,
    required bool tablet,
    required bool desktop,
    required bool veryNarrow,
  }) {
    if (veryNarrow) {
      return 28;
    }

    if (desktop) {
      return 44;
    }

    if (tablet) {
      return 40;
    }

    if (compact) {
      return 32;
    }

    return 38;
  }

  // ─────────────────────────────────────────
  // ICON
  // ─────────────────────────────────────────

  double _calculateIconSize({
    required bool compact,
    required bool tablet,
    required bool desktop,
    required bool veryNarrow,
  }) {
    if (veryNarrow) {
      return 15;
    }

    if (desktop) {
      return 24;
    }

    if (tablet) {
      return 22;
    }

    if (compact) {
      return 17;
    }

    return 20;
  }

  // ─────────────────────────────────────────
  // TITLE
  // ─────────────────────────────────────────

  double _calculateTitleSize({
    required bool compact,
    required bool tablet,
    required bool desktop,
    required bool veryNarrow,
  }) {
    if (veryNarrow) {
      return 9.5;
    }

    if (desktop) {
      return 14;
    }

    if (tablet) {
      return 13;
    }

    if (compact) {
      return 10.5;
    }

    return 12;
  }

  // ─────────────────────────────────────────
  // VALUE
  // ─────────────────────────────────────────

  double _calculateValueSize({
    required bool compact,
    required bool tablet,
    required bool desktop,
    required bool veryNarrow,
  }) {
    if (veryNarrow) {
      return 12;
    }

    if (desktop) {
      return 20;
    }

    if (tablet) {
      return 18;
    }

    if (compact) {
      return 14;
    }

    return 17;
  }

  // ─────────────────────────────────────────
  // SPACING
  // ─────────────────────────────────────────

  double _calculateSpacing({
    required bool compact,
    required bool desktop,
    required bool veryNarrow,
  }) {
    if (veryNarrow) {
      return 5;
    }

    if (desktop) {
      return 9;
    }

    if (compact) {
      return 6;
    }

    return 8;
  }
}
