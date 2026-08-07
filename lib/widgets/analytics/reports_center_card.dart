import 'package:flutter/material.dart';

class ReportsCenterCard extends StatelessWidget {
  final List<Map<String, dynamic>> reports;

  final Future<void> Function(String path) onShare;

  final Future<void> Function(Map<String, dynamic> report) onPreview;

  final Future<void> Function(int index) onDelete;

  final Future<void> Function() onClearHistory;

  const ReportsCenterCard({
    super.key,
    required this.reports,
    required this.onShare,
    required this.onPreview,
    required this.onDelete,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: const Padding(
          padding: EdgeInsets.all(22),
          child: Center(child: Text("No reports generated yet")),
        ),
      );
    }

    return Column(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: reports.asMap().entries.map((entry) {
              final index = entry.key;
              final report = entry.value;

              return ListTile(
                leading: Icon(
                  report["name"].toString().toLowerCase().endsWith(".pdf")
                      ? Icons.picture_as_pdf
                      : Icons.table_chart,
                ),

                title: Text(report["name"]),

                subtitle: Text(
                  report["created_at"].toString().substring(0, 10),
                ),

                onTap: () => onPreview(report),

                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () => onShare(report["path"]),
                    ),

                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => onDelete(index),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        ElevatedButton.icon(
          onPressed: onClearHistory,
          icon: const Icon(Icons.delete),
          label: const Text("Clear Report History"),
        ),
      ],
    );
  }
}
