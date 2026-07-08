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
              width: 110,
              height: 110,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey.shade300,
                    color: scoreColor,
                  ),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "$score",
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        label,
                        style: TextStyle(
                          color: scoreColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            LinearProgressIndicator(
              value: score / 100,
              color: scoreColor,
              minHeight: 10,
              borderRadius: BorderRadius.circular(20),
            ),

            const SizedBox(height: 12),

            Text(
              "Financial health score",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
