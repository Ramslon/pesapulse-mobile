import 'package:flutter/material.dart';
import '../fade_slide_animation.dart';

class ExportReportsSection extends StatelessWidget {
  final bool isGuest;

  final Future<void> Function() onGuestTap;

  final Future<void> Function() onExportPdf;

  final Future<void> Function() onExportCsv;

  const ExportReportsSection({
    super.key,
    required this.isGuest,
    required this.onGuestTap,
    required this.onExportPdf,
    required this.onExportCsv,
  });

  @override
  Widget build(BuildContext context) {
    if (isGuest) {
      return Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onGuestTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.shade100,
                  child: const Icon(Icons.picture_as_pdf, color: Colors.orange),
                ),

                const SizedBox(width: 14),

                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Export Reports",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text("Create an account to export PDF and CSV reports."),
                    ],
                  ),
                ),

                const Icon(Icons.arrow_forward_ios, size: 18),
              ],
            ),
          ),
        ),
      );
    }

    return FadeSlideAnimation(
      delay: 400,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Export PDF"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: onExportPdf,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.table_chart),
              label: const Text("Export CSV"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: onExportCsv,
            ),
          ),
        ],
      ),
    );
  }
}
