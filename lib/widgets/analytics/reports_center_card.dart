import 'package:flutter/material.dart';

import '../fade_slide_animation.dart';
import '/utils/responsive_helper.dart';

class ReportsCenterCard extends StatelessWidget {
  final List<Map<String, dynamic>> reports;

  final Future Function(String path) onShare;
  final Future Function(Map<String, dynamic> report) onPreview;
  final Future Function(int index) onDelete;
  final Future Function() onClearHistory;

  const ReportsCenterCard({
    super.key,
    required this.reports,
    required this.onShare,
    required this.onPreview,
    required this.onDelete,
    required this.onClearHistory,
  });

  bool _isPdf(Map<String, dynamic> report) {
    return report['name'].toString().toLowerCase().endsWith('.pdf');
  }

  String _formatDate(dynamic value) {
    final raw = value?.toString() ?? '';

    if (raw.isEmpty) {
      return 'Date unavailable';
    }

    final date = DateTime.tryParse(raw);

    if (date == null) {
      return raw.length >= 10 ? raw.substring(0, 10) : raw;
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _reportType(Map<String, dynamic> report) {
    return _isPdf(report) ? 'PDF' : 'CSV';
  }

  IconData _reportIcon(Map<String, dynamic> report) {
    return _isPdf(report)
        ? Icons.picture_as_pdf_rounded
        : Icons.table_chart_rounded;
  }

  Color _reportColor(BuildContext context, Map<String, dynamic> report) {
    if (_isPdf(report)) {
      return const Color(0xFFE53935);
    }

    return const Color(0xFF0F9D8A);
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final mobile = ResponsiveHelper.isMobile(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final iconSize = desktop
        ? 48.0
        : mobile
        ? 40.0
        : 44.0;

    final icon = desktop
        ? 23.0
        : mobile
        ? 20.0
        : 22.0;

    final titleSize = desktop
        ? 19.0
        : mobile
        ? 16.0
        : 18.0;

    final subtitleSize = desktop
        ? 12.5
        : mobile
        ? 11.0
        : 12.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.09),
            borderRadius: BorderRadius.circular(mobile ? 13 : 15),
            border: Border.all(color: colorScheme.primary.withOpacity(0.10)),
          ),
          child: Icon(
            Icons.assessment_rounded,
            color: colorScheme.primary,
            size: icon,
          ),
        ),

        SizedBox(width: mobile ? 10 : 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reports Center',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                'Your exported financial reports',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: subtitleSize,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        Container(
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? 8 : 10,
            vertical: mobile ? 5 : 6,
          ),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${reports.length}',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: mobile ? 10 : 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportActions(
    BuildContext context,
    Map<String, dynamic> report,
    int index, {
    required bool compact,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          context,
          tooltip: 'Preview report',
          icon: Icons.visibility_outlined,
          color: colorScheme.primary,
          onPressed: () => onPreview(report),
          compact: compact,
        ),

        const SizedBox(width: 4),

        _buildActionButton(
          context,
          tooltip: 'Share report',
          icon: Icons.share_outlined,
          color: colorScheme.onSurfaceVariant,
          onPressed: () => onShare(report['path'].toString()),
          compact: compact,
        ),

        const SizedBox(width: 4),

        _buildActionButton(
          context,
          tooltip: 'Delete report',
          icon: Icons.delete_outline_rounded,
          color: colorScheme.error,
          onPressed: () => onDelete(index),
          compact: compact,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String tooltip,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required bool compact,
  }) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: BoxConstraints(
        minWidth: compact ? 34 : 36,
        minHeight: compact ? 34 : 36,
      ),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: compact ? 18 : 19),
    );
  }

  Widget _buildReportItem(
    BuildContext context,
    Map<String, dynamic> report,
    int index,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final mobile = ResponsiveHelper.isMobile(context);
    final compact = ResponsiveHelper.useCompactLayout(context);
    final desktop = ResponsiveHelper.isDesktop(context);
    final tablet = ResponsiveHelper.isTablet(context);

    final reportColor = _reportColor(context, report);

    final reportBackground = reportColor.withOpacity(
      theme.brightness == Brightness.dark ? 0.12 : 0.07,
    );

    final itemRadius = desktop ? 17.0 : 15.0;

    final iconSize = desktop
        ? 46.0
        : compact
        ? 42.0
        : 45.0;

    final reportIconSize = desktop
        ? 23.0
        : compact
        ? 21.0
        : 22.0;

    final horizontalPadding = desktop
        ? 15.0
        : tablet
        ? 13.0
        : 11.0;

    final verticalPadding = desktop
        ? 13.0
        : compact
        ? 10.0
        : 12.0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: index == reports.length - 1
            ? 0
            : desktop
            ? 9
            : 8,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(itemRadius),
          onTap: () => onPreview(report),
          child: Ink(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(
                theme.brightness == Brightness.dark ? 0.34 : 0.46,
              ),
              borderRadius: BorderRadius.circular(itemRadius),
              border: Border.all(color: colorScheme.outline.withOpacity(0.07)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: reportBackground,
                          borderRadius: BorderRadius.circular(
                            compact ? 12 : 14,
                          ),
                        ),
                        child: Icon(
                          _reportIcon(report),
                          color: reportColor,
                          size: reportIconSize,
                        ),
                      ),

                      SizedBox(width: compact ? 10 : 12),

                      Expanded(
                        child: _buildReportInformation(
                          context,
                          report: report,
                          reportColor: reportColor,
                          compact: compact,
                          desktop: desktop,
                        ),
                      ),

                      if (!mobile)
                        _buildReportActions(
                          context,
                          report,
                          index,
                          compact: compact,
                        ),
                    ],
                  ),

                  if (mobile) ...[
                    const SizedBox(height: 8),

                    Container(
                      height: 1,
                      color: colorScheme.outline.withOpacity(0.06),
                    ),

                    const SizedBox(height: 5),

                    Align(
                      alignment: Alignment.centerRight,
                      child: _buildReportActions(
                        context,
                        report,
                        index,
                        compact: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportInformation(
    BuildContext context, {
    required Map<String, dynamic> report,
    required Color reportColor,
    required bool compact,
    required bool desktop,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final titleSize = desktop
        ? 14.5
        : compact
        ? 12.5
        : 13.5;

    final metadataSize = desktop
        ? 11.5
        : compact
        ? 10.0
        : 10.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          report['name']?.toString() ?? 'Unnamed report',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),

        const SizedBox(height: 6),

        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 7 : 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: reportColor.withOpacity(0.09),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                _reportType(report),
                style: TextStyle(
                  color: reportColor,
                  fontSize: metadataSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),

            const SizedBox(width: 8),

            Flexible(
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: compact ? 12 : 13,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.58),
                  ),

                  const SizedBox(width: 4),

                  Flexible(
                    child: Text(
                      _formatDate(report['created_at']),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.68),
                        fontSize: metadataSize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final mobile = ResponsiveHelper.isMobile(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final padding = ResponsiveHelper.cardPadding(context);

    final iconSize = desktop
        ? 70.0
        : mobile
        ? 58.0
        : 64.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding + 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(desktop ? 22 : 20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.10)),
      ),
      child: Column(
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(mobile ? 18 : 20),
            ),
            child: Icon(
              Icons.assessment_outlined,
              size: mobile ? 29 : 33,
              color: colorScheme.primary,
            ),
          ),

          SizedBox(height: ResponsiveHelper.spacing(context)),

          Text(
            'No reports yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 6),

          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Text(
              'Export a PDF or CSV report and your financial documents will appear here for quick access.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final cardPadding = ResponsiveHelper.isDesktop(context)
        ? 14.0
        : ResponsiveHelper.isTablet(context)
        ? 12.0
        : 9.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.isDesktop(context) ? 22 : 20,
        ),
        border: Border.all(color: colorScheme.outline.withOpacity(0.10)),
      ),
      child: Column(
        children: [
          _buildHeader(context),

          SizedBox(height: ResponsiveHelper.isDesktop(context) ? 17 : 14),

          Column(
            children: reports.asMap().entries.map((entry) {
              return _buildReportItem(context, entry.value, entry.key);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildClearHistoryButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final mobile = ResponsiveHelper.isMobile(context);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onClearHistory,
        icon: const Icon(Icons.delete_sweep_outlined),
        label: Text(
          'Clear Report History',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: mobile ? 12.5 : 13.5,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.error,
          side: BorderSide(color: colorScheme.error.withOpacity(0.28)),
          backgroundColor: colorScheme.error.withOpacity(0.025),
          padding: EdgeInsets.symmetric(vertical: mobile ? 12 : 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentMaxWidth = ResponsiveHelper.contentMaxWidth(context);

    if (reports.isEmpty) {
      return FadeSlideAnimation(
        delay: 450,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: _buildEmptyState(context),
          ),
        ),
      );
    }

    return FadeSlideAnimation(
      delay: 450,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: Column(
            children: [
              _buildReportList(context),

              SizedBox(height: ResponsiveHelper.spacing(context)),

              _buildClearHistoryButton(context),
            ],
          ),
        ),
      ),
    );
  }
}
