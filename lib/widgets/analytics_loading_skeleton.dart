import 'package:flutter/material.dart';

class AnalyticsLoadingSkeleton extends StatelessWidget {
  const AnalyticsLoadingSkeleton({super.key});

  Widget skeleton({double height = 20, double width = double.infinity}) {
    return Container(
      height: height,
      width: width,

      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget cardPlaceholder({double height = 120}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            children: [
              cardPlaceholder(height: 150),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(child: cardPlaceholder()),
                  const SizedBox(width: 12),
                  Expanded(child: cardPlaceholder()),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: cardPlaceholder()),
                  const SizedBox(width: 12),
                  Expanded(child: cardPlaceholder()),
                ],
              ),

              const SizedBox(height: 24),

              cardPlaceholder(height: 220),

              const SizedBox(height: 24),

              cardPlaceholder(height: 170),

              const SizedBox(height: 24),

              cardPlaceholder(height: 300),

              const SizedBox(height: 24),

              cardPlaceholder(height: 260),

              const SizedBox(height: 24),

              cardPlaceholder(height: 220),

              const SizedBox(height: 24),

              cardPlaceholder(height: 180),
            ],
          ),
        ),
      ),
    );
  }
}
