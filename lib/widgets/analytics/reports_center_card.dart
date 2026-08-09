import 'package:flutter/material.dart';
import '../fade_slide_animation.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (reports.isEmpty) {
      return FadeSlideAnimation(
        delay: 450,
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: colorScheme.outline.withOpacity(.12)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    size: 32,
                    color: Colors.indigo.shade600,
                  ),
                ),

                const SizedBox(height: 14),

                Text(
                  'No reports yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Export a PDF or CSV report and it will appear here.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(.65),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return FadeSlideAnimation(
      delay: 450,
      child: Column(
        children: [
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: colorScheme.outline.withOpacity(.12)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: reports.asMap().entries.map((entry) {
                  final index = entry.key;
                  final report = entry.value;

                  final isPdf = _isPdf(report);

                  final iconColor = isPdf
                      ? Colors.red.shade600
                      : Colors.teal.shade600;

                  final iconBackground = isPdf
                      ? Colors.red.withOpacity(.10)
                      : Colors.teal.withOpacity(.10);

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == reports.length - 1 ? 0 : 8,
                    ),
                    child: Material(
                      color: colorScheme.surfaceContainerHighest.withOpacity(
                        .45,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => onPreview(report),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: iconBackground,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  isPdf
                                      ? Icons.picture_as_pdf_outlined
                                      : Icons.table_chart_outlined,
                                  color: iconColor,
                                  size: 24,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      report['name']?.toString() ??
                                          'Unnamed report',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
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
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            _reportType(report),
                                            style: TextStyle(
                                              color: iconColor,
                                              fontSize: 10,
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
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.color
                                                      ?.withOpacity(.60),
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 6),

                              IconButton(
                                tooltip: 'Preview report',
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  Icons.visibility_outlined,
                                  color: colorScheme.primary,
                                ),
                                onPressed: () => onPreview(report),
                              ),

                              IconButton(
                                tooltip: 'Share report',
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.share_outlined),
                                onPressed: () =>
                                    onShare(report['path'].toString()),
                              ),

                              IconButton(
                                tooltip: 'Delete report',
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color: colorScheme.error,
                                ),
                                onPressed: () => onDelete(index),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onClearHistory,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Clear Report History'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.error,
                side: BorderSide(color: colorScheme.error.withOpacity(.35)),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
