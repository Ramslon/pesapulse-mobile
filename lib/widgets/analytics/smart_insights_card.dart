import 'package:flutter/material.dart';
import '../fade_slide_animation.dart';

class SmartInsightsCard extends StatelessWidget {
  final List<String> insights;

  const SmartInsightsCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    return FadeSlideAnimation(
      delay: 350,
      child: Column(
        children: insights
            .map(
              (insight) => Card(
                child: ListTile(
                  leading: const Icon(Icons.lightbulb, color: Colors.amber),
                  title: Text(insight),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
