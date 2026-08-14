import 'package:flutter/material.dart';

import '../fade_slide_animation.dart';
import '../../utils/responsive_helper.dart';

class ExportReportsSection extends StatelessWidget {
  final bool isGuest;

  final Future Function() onGuestTap;
  final Future Function() onExportPdf;
  final Future Function() onExportCsv;

  const ExportReportsSection({
    super.key,
    required this.isGuest,
    required this.onGuestTap,
    required this.onExportPdf,
    required this.onExportCsv,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final spacing = ResponsiveHelper.spacing(context);
    final cardPadding = ResponsiveHelper.cardPadding(context);

    final radius = compact
        ? 16.0
        : desktop
        ? 22.0
        : 18.0;

    if (isGuest) {
      return Card(
        elevation: compact ? 1 : 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onGuestTap,
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildGuestIcon(context, compact: compact, desktop: desktop),

                SizedBox(width: spacing),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export Reports',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: compact
                              ? 13
                              : desktop
                              ? 16
                              : null,
                        ),
                      ),

                      SizedBox(height: compact ? 4 : 5),

                      Text(
                        'Create an account to export PDF and CSV reports.',
                        maxLines: compact ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.35,
                          fontSize: compact ? 11 : 12,
                          color: theme.textTheme.bodySmall?.color?.withOpacity(
                            0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: compact ? 6 : 10),

                _buildArrowButton(context, compact: compact),
              ],
            ),
          ),
        ),
      );
    }

    return FadeSlideAnimation(
      delay: 400,
      child: _buildExportButtons(
        context,
        spacing: spacing,
        compact: compact,
        landscape: landscape,
        tablet: tablet,
        desktop: desktop,
      ),
    );
  }

  Widget _buildGuestIcon(
    BuildContext context, {
    required bool compact,
    required bool desktop,
  }) {
    final size = compact
        ? 38.0
        : desktop
        ? 52.0
        : 46.0;

    final iconSize = compact
        ? 20.0
        : desktop
        ? 27.0
        : 24.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(compact ? 11 : 14),
      ),
      child: Icon(
        Icons.picture_as_pdf_outlined,
        color: Colors.orange,
        size: iconSize,
      ),
    );
  }

  Widget _buildArrowButton(BuildContext context, {required bool compact}) {
    final colorScheme = Theme.of(context).colorScheme;

    final size = compact ? 30.0 : 34.0;
    final iconSize = compact ? 12.0 : 14.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.arrow_forward_ios_rounded, size: iconSize),
    );
  }

  Widget _buildExportButtons(
    BuildContext context, {
    required double spacing,
    required bool compact,
    required bool landscape,
    required bool tablet,
    required bool desktop,
  }) {
    // Very compact mobile layouts get stacked buttons.
    //
    // This prevents text such as "Export PDF" and "Export CSV"
    // from being squeezed into very narrow cards.
    final stackButtons = compact && !landscape && !tablet && !desktop;

    final pdfButton = _ExportButton(
      icon: Icons.picture_as_pdf_outlined,
      label: 'Export PDF',
      color: Colors.red,
      onPressed: onExportPdf,
      compact: compact,
      desktop: desktop,
    );

    final csvButton = _ExportButton(
      icon: Icons.table_chart_outlined,
      label: 'Export CSV',
      color: Colors.teal,
      onPressed: onExportCsv,
      compact: compact,
      desktop: desktop,
    );

    if (stackButtons) {
      return Column(
        children: [
          SizedBox(width: double.infinity, child: pdfButton),

          SizedBox(height: spacing),

          SizedBox(width: double.infinity, child: csvButton),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: pdfButton),

        SizedBox(width: spacing),

        Expanded(child: csvButton),
      ],
    );
  }
}

class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Future Function() onPressed;
  final bool compact;
  final bool desktop;

  const _ExportButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    required this.compact,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final height = compact
        ? 46.0
        : desktop
        ? 56.0
        : 52.0;

    final iconSize = compact
        ? 18.0
        : desktop
        ? 23.0
        : 21.0;

    final fontSize = compact
        ? 12.0
        : desktop
        ? 14.0
        : 13.0;

    final horizontalPadding = compact
        ? 8.0
        : desktop
        ? 18.0
        : 12.0;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: fontSize),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 1,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 12 : 14),
          ),
        ),
      ),
    );
  }
}
