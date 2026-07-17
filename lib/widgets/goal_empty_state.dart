import 'package:flutter/material.dart';

class GoalEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const GoalEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 54,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 28),

            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 32),

            Text(
              "Start by creating your first financial goal.",
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
