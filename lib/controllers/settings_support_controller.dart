import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_constants.dart';

class SettingsSupportController {
  Future<void> contactSupport(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@pesapulse.app',
      queryParameters: {'subject': '${AppConstants.appName} Support'},
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
      return;
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open email application')),
    );
  }

  void shareApp() {
    Share.share('''
I'm using ${AppConstants.appName} to manage my expenses, budgets and savings goals.

Download it here:

https://github.com/ramslon/PesaPulse
''');
  }

  void showRateAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Rate ${AppConstants.appName}'),
        content: const Text(
          'Thank you for using PesaPulse!\n\n'
          'The app will be available on Google Play soon, where '
          "you'll be able to leave a rating and review.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
