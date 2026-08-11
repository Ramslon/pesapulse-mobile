import 'package:flutter/material.dart';

class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Privacy Policy'),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your privacy matters to us.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 15),

            Text(
              'PesaPulse securely stores your financial information to '
              'provide budgeting, expense tracking and savings features.',
            ),

            SizedBox(height: 15),

            Text('We do not:'),

            SizedBox(height: 8),

            Text('• Sell your personal data'),
            Text('• Share your financial records with third parties'),
            Text('• Access your passwords'),

            SizedBox(height: 15),

            Text('We may collect:'),

            SizedBox(height: 8),

            Text('• Your profile information'),
            Text('• Budget and expense data'),
            Text('• Goal progress'),
            Text('• App preferences'),

            SizedBox(height: 20),

            Text(
              'Last Updated: July 2026',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
