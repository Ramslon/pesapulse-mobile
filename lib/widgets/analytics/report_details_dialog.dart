import 'package:flutter/material.dart';

class ReportDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> report;

  const ReportDetailsDialog({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Name: ${report['name']}'),

          const SizedBox(height: 10),

          Text('Created: ${report['created_at']}'),

          const SizedBox(height: 10),

          Text(
            'Path: ${report['path']}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
