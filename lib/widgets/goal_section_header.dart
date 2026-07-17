import 'package:flutter/material.dart';

class GoalSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const GoalSectionHeader({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withOpacity(.12),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),

        const SizedBox(width: 14),

        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
