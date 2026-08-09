import 'package:flutter/material.dart';

class AnalyticsRefreshErrorBanner extends StatelessWidget {
  final String? error;
  final bool isOffline;
  final bool isRetrying;
  final VoidCallback onRetry;

  const AnalyticsRefreshErrorBanner({
    super.key,
    required this.error,
    required this.isOffline,
    required this.isRetrying,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (error == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              isOffline ? Icons.cloud_off_outlined : Icons.error_outline,
              size: 20,
              color: Theme.of(context).colorScheme.error,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                error!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            TextButton(
              onPressed: isRetrying ? null : onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
