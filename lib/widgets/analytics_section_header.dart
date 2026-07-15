import 'package:flutter/material.dart';

class AnalyticsSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const AnalyticsSectionHeader({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(.12),
            borderRadius: BorderRadius.circular(19),
          ),
          child: Icon(icon, color: colorScheme.primary),
        ),

        const SizedBox(width: 12),

        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
