import 'package:flutter/material.dart';

class AnalyticsErrorState extends StatelessWidget {
  final bool isOffline;
  final String message;
  final bool isRetrying;
  final VoidCallback onRetry;

  const AnalyticsErrorState({
    super.key,
    required this.isOffline,
    required this.message,
    required this.isRetrying,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOffline ? Icons.cloud_off_outlined : Icons.error_outline,
              size: 52,
              color: Theme.of(context).colorScheme.error,
            ),

            const SizedBox(height: 14),

            Text(
              isOffline ? 'You are offline' : 'Unable to load analytics',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: isRetrying ? null : onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
