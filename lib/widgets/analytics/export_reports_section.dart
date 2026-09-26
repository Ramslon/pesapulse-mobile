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
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final contentMaxWidth = ResponsiveHelper.contentMaxWidth(context);

    if (isGuest) {
      return FadeSlideAnimation(
        delay: 400,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: _buildGuestState(
              context,
              compact: compact,
              desktop: desktop,
            ),
          ),
        ),
      );
    }

    return FadeSlideAnimation(
      delay: 400,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: _buildExportSection(
            context,
            compact: compact,
            landscape: landscape,
            tablet: tablet,
            desktop: desktop,
          ),
        ),
      ),
    );
  }

  Widget _buildExportSection(
    BuildContext context, {
    required bool compact,
    required bool landscape,
    required bool tablet,
    required bool desktop,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final cardPadding = ResponsiveHelper.cardPadding(context);

    final radius = desktop
        ? 22.0
        : compact
        ? 18.0
        : 20.0;

    final spacing = ResponsiveHelper.spacing(context);

    final stackButtons = compact && !landscape && !tablet && !desktop;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colorScheme.outline.withOpacity(0.09)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.08 : 0.035,
            ),
            blurRadius: desktop ? 20 : 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, compact: compact, desktop: desktop),

          SizedBox(
            height: desktop
                ? 18
                : compact
                ? 14
                : 16,
          ),

          if (stackButtons)
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: _ExportOption(
                    icon: Icons.picture_as_pdf_rounded,
                    title: 'Export PDF',
                    description: 'Create a polished financial report',
                    accent: const Color(0xFFE53935),
                    onPressed: onExportPdf,
                    compact: compact,
                    desktop: desktop,
                  ),
                ),

                SizedBox(height: spacing),

                SizedBox(
                  width: double.infinity,
                  child: _ExportOption(
                    icon: Icons.table_chart_rounded,
                    title: 'Export CSV',
                    description: 'Export your financial data as a spreadsheet',
                    accent: const Color(0xFF0F9D8A),
                    onPressed: onExportCsv,
                    compact: compact,
                    desktop: desktop,
                  ),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ExportOption(
                    icon: Icons.picture_as_pdf_rounded,
                    title: 'Export PDF',
                    description: 'Create a polished financial report',
                    accent: const Color(0xFFE53935),
                    onPressed: onExportPdf,
                    compact: compact,
                    desktop: desktop,
                  ),
                ),

                SizedBox(width: spacing),

                Expanded(
                  child: _ExportOption(
                    icon: Icons.table_chart_rounded,
                    title: 'Export CSV',
                    description: 'Export your financial data as a spreadsheet',
                    accent: const Color(0xFF0F9D8A),
                    onPressed: onExportCsv,
                    compact: compact,
                    desktop: desktop,
                  ),
                ),
              ],
            ),
        ],
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

    final iconBox = desktop
        ? 48.0
        : compact
        ? 40.0
        : 44.0;

    final iconSize = desktop
        ? 24.0
        : compact
        ? 20.0
        : 22.0;

    final titleSize = desktop
        ? 19.0
        : compact
        ? 16.0
        : 18.0;

    final subtitleSize = desktop
        ? 12.5
        : compact
        ? 11.0
        : 12.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: iconBox,
          height: iconBox,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.09),
            borderRadius: BorderRadius.circular(compact ? 13 : 15),
            border: Border.all(color: colorScheme.primary.withOpacity(0.10)),
          ),
          child: Icon(
            Icons.file_download_rounded,
            color: colorScheme.primary,
            size: iconSize,
          ),
        ),

        SizedBox(width: compact ? 10 : 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export Your Finances',
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
                'Take your financial data with you',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: subtitleSize,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuestState(
    BuildContext context, {
    required bool compact,
    required bool desktop,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final padding = ResponsiveHelper.cardPadding(context);

    final radius = desktop
        ? 22.0
        : compact
        ? 18.0
        : 20.0;

    final iconBox = desktop
        ? 52.0
        : compact
        ? 42.0
        : 48.0;

    final iconSize = desktop
        ? 26.0
        : compact
        ? 21.0
        : 24.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onGuestTap,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: colorScheme.primary.withOpacity(0.11)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  theme.brightness == Brightness.dark ? 0.08 : 0.035,
                ),
                blurRadius: desktop ? 20 : 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(compact ? 12 : 15),
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: colorScheme.primary,
                  size: iconSize,
                ),
              ),

              SizedBox(width: compact ? 10 : 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Export Reports',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: desktop
                                  ? 17
                                  : compact
                                  ? 13.5
                                  : 15.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        const SizedBox(width: 7),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ACCOUNT',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: compact ? 7.5 : 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'Create an account to export PDF and CSV reports and keep your report history.',
                      maxLines: compact ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: desktop
                            ? 12.5
                            : compact
                            ? 10.5
                            : 11.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: compact ? 8 : 12),

              Container(
                width: compact ? 32 : 36,
                height: compact ? 32 : 36,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: colorScheme.primary,
                  size: compact ? 16 : 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final Future Function() onPressed;
  final bool compact;
  final bool desktop;

  const _ExportOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.onPressed,
    required this.compact,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final radius = desktop
        ? 17.0
        : compact
        ? 15.0
        : 16.0;

    final iconBox = desktop
        ? 46.0
        : compact
        ? 38.0
        : 42.0;

    final iconSize = desktop
        ? 23.0
        : compact
        ? 19.0
        : 21.0;

    final titleSize = desktop
        ? 14.0
        : compact
        ? 12.0
        : 13.0;

    final descriptionSize = desktop
        ? 11.5
        : compact
        ? 9.5
        : 10.5;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(radius),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.all(
            desktop
                ? 14
                : compact
                ? 10
                : 12,
          ),
          decoration: BoxDecoration(
            color: accent.withOpacity(
              theme.brightness == Brightness.dark ? 0.09 : 0.055,
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: accent.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(compact ? 11 : 13),
                ),
                child: Icon(icon, color: accent, size: iconSize),
              ),

              SizedBox(width: compact ? 9 : 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: descriptionSize,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.arrow_forward_rounded,
                color: accent.withOpacity(0.85),
                size: compact ? 17 : 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
