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
    return _isPdf(report) ? 'PDF Report' : 'CSV Report';
  }

  Widget _buildReportActions(
    BuildContext context,
    Map<String, dynamic> report,
    int index,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Preview report',
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.visibility_outlined, color: colorScheme.primary),
          onPressed: () => onPreview(report),
        ),
        IconButton(
          tooltip: 'Share report',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.share_outlined),
          onPressed: () => onShare(report['path'].toString()),
        ),
        IconButton(
          tooltip: 'Delete report',
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.delete_outline_rounded, color: colorScheme.error),
          onPressed: () => onDelete(index),
        ),
      ],
    );
  }

  Widget _buildReportItem(
    BuildContext context,
    Map<String, dynamic> report,
    int index,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isPdf = _isPdf(report);

    final iconColor = isPdf ? Colors.red.shade600 : Colors.teal.shade600;

    final iconBackground = isPdf
        ? Colors.red.withOpacity(.10)
        : Colors.teal.withOpacity(.10);

    final isCompact = ResponsiveHelper.useCompactLayout(context);
    final isMobile = ResponsiveHelper.isMobile(context);

    final itemPadding = ResponsiveHelper.isDesktop(context)
        ? 16.0
        : ResponsiveHelper.isTablet(context)
        ? 14.0
        : 12.0;

    final iconSize = isCompact ? 42.0 : 46.0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: index == reports.length - 1
            ? 0
            : ResponsiveHelper.spacing(context) * 0.55,
      ),
      child: Material(
        color: colorScheme.surfaceContainerHighest.withOpacity(.45),
        borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
        child: InkWell(
          borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
          onTap: () => onPreview(report),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: itemPadding,
              vertical: isCompact ? 10 : 12,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: iconBackground,
                        borderRadius: BorderRadius.circular(
                          isCompact ? 12 : 14,
                        ),
                      ),
                      child: Icon(
                        isPdf
                            ? Icons.picture_as_pdf_outlined
                            : Icons.table_chart_outlined,
                        color: iconColor,
                        size: isCompact ? 22 : 24,
                      ),
                    ),

                    SizedBox(width: ResponsiveHelper.spacing(context) * 0.8),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report['name']?.toString() ?? 'Unnamed report',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: iconBackground,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _reportType(report),
                                  style: TextStyle(
                                    color: iconColor,
                                    fontSize: isCompact ? 9.5 : 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              Flexible(
                                child: Text(
                                  _formatDate(report['created_at']),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withOpacity(.60),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Desktop/tablet actions stay beside the report.
                    if (!isMobile) ...[
                      const SizedBox(width: 8),
                      _buildReportActions(context, report, index),
                    ],
                  ],
                ),

                // Mobile actions move below the report information.
                if (isMobile) ...[
                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildReportActions(context, report, index),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final padding = ResponsiveHelper.cardPadding(context);

    final iconSize = ResponsiveHelper.isMobile(context) ? 58.0 : 64.0;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outline.withOpacity(.12)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: padding + 6,
        ),
        child: Column(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.description_outlined,
                size: ResponsiveHelper.isMobile(context) ? 29 : 32,
                color: Colors.indigo.shade600,
              ),
            ),

            SizedBox(height: ResponsiveHelper.spacing(context)),

            Text(
              'No reports yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                'Export a PDF or CSV report and it will appear here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(.65),
                  height: 1.4,
                ),
              ),
            ),
          ],
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

    final cardPadding = ResponsiveHelper.isDesktop(context)
        ? 12.0
        : ResponsiveHelper.isTablet(context)
        ? 10.0
        : 8.0;

    return FadeSlideAnimation(
      delay: 450,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: Column(
            children: [
              Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(.12),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Column(
                    children: reports.asMap().entries.map((entry) {
                      return _buildReportItem(context, entry.value, entry.key);
                    }).toList(),
                  ),
                ),
              ),

              SizedBox(height: ResponsiveHelper.spacing(context)),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onClearHistory,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  label: Text(
                    'Clear Report History',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.isMobile(context) ? 13 : 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withOpacity(.35),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveHelper.isMobile(context) ? 12 : 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
