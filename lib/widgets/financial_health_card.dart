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

    if (score >= 60) return Colors.blue;

    if (score >= 40) return Colors.orange;

    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,

      child: Padding(
        padding: const EdgeInsets.all(22),

        child: Column(
          children: [
            const Text(
              "Financial Health",

              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),

            const SizedBox(height: 18),

            SizedBox(
              height: 130,

              width: 130,

              child: Stack(
                alignment: Alignment.center,

                children: [
                  CircularProgressIndicator(
                    value: score / 100,

                    strokeWidth: 10,

                    color: scoreColor,

                    backgroundColor: Colors.grey.shade200,
                  ),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      Text(
                        "$score",

                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(label),
                    ],
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
