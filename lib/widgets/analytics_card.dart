import 'package:flutter/material.dart';

class AnalyticsCard extends StatelessWidget {
  final IconData icon;

  final String title;

  final String value;

  final Color color;

  const AnalyticsCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(.12),
              child: Icon(icon, color: color),
            ),

            const Spacer(),

            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
