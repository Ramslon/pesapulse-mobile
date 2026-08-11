import 'package:flutter/material.dart';
import '/core/constants/app_constants.dart';

class AboutPesaPulseDialog extends StatelessWidget {
  const AboutPesaPulseDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('About PesaPulse'),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PesaPulse is a personal finance management application '
              'designed to help users take control of their finances.',
            ),

            SizedBox(height: 15),

            Text('Features'),

            SizedBox(height: 8),

            Text('• Expense Tracking'),
            Text('• Budget Management'),
            Text('• Savings Goals'),
            Text('• Financial Analytics'),
            Text('• Smart Insights'),
            Text('• Secure Account Management'),

            SizedBox(height: 20),

            Text(
              AppConstants.appVersionText,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 10),
            Text('© ${AppConstants.appYear} ${AppConstants.appName}'),
          ],
        ),
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
