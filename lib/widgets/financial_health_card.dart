import 'package:flutter/material.dart';

class FinancialHealthCard extends StatelessWidget {
  final int score;
  final String label;

  const FinancialHealthCard({
    super.key,
    required this.score,
    required this.label,
  });

  Color get scoreColor {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    if (score >= 20) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Financial Health",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: 175,
              height: 175,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 16,
                    backgroundColor: Colors.grey.shade300,
                    color: scoreColor,
                  ),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "$score",
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        label,
                        style: TextStyle(
                          color: scoreColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 14,
                backgroundColor: Colors.grey.shade300,
                color: scoreColor,
              ),
            ),
            const SizedBox(height: 12),

            Column(
              children: [
                Text(
                  "$score / 100",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Financial Health Score",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
