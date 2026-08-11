import 'package:flutter/material.dart';
import '/core/constants/app_constants.dart';

class TermsOfServiceDialog extends StatelessWidget {
  const TermsOfServiceDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Terms of Service'),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'By using PesaPulse you agree to:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 15),

            Text('• Use the application responsibly.'),
            Text('• Keep your login credentials secure.'),
            Text('• Maintain accurate financial records.'),
            Text('• Comply with applicable laws.'),

            SizedBox(height: 20),

            Text(
              'PesaPulse is intended as a financial management tool and '
              'should not be considered financial or investment advice.',
            ),

            SizedBox(height: 20),

            Text(
              AppConstants.appVersionText,
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
