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

      child: Padding(
        padding: const EdgeInsets.all(18),

        child: Row(
          children: [
            CircleAvatar(
              radius: 22,

              backgroundColor: color.withOpacity(.12),

              child: Icon(icon, color: color),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(title, style: const TextStyle(color: Colors.grey)),

                  const SizedBox(height: 5),

                  Text(
                    value,

                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
