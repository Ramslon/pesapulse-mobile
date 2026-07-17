import 'package:flutter/material.dart';

class GoalLoadingSkeleton extends StatelessWidget {
  const GoalLoadingSkeleton({super.key});

  Widget skeletonBox({double height = 20, double width = double.infinity}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        skeletonBox(height: 120),

        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(child: skeletonBox(height: 90)),
            const SizedBox(width: 12),
            Expanded(child: skeletonBox(height: 90)),
          ],
        ),

        const SizedBox(height: 24),

        skeletonBox(height: 220),

        const SizedBox(height: 24),

        skeletonBox(height: 220),
      ],
    );
  }
}
