import 'package:flutter/material.dart';

class BudgetLoadingSkeleton extends StatelessWidget {
  const BudgetLoadingSkeleton({super.key});

  Widget skeleton({
    double height = 20,
    double width = double.infinity,
    BorderRadius? radius,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: radius ?? BorderRadius.circular(12),
      ),
    );
  }

  Widget statCardSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }

  Widget analyticsCardSkeleton() {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(18),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              skeleton(width: 220, height: 32),

              const SizedBox(height: 10),

              skeleton(width: 180, height: 18),

              const SizedBox(height: 25),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
                children: List.generate(4, (_) => statCardSkeleton()),
              ),

              const SizedBox(height: 25),

              skeleton(height: 140, radius: BorderRadius.circular(18)),

              const SizedBox(height: 25),

              skeleton(height: 420, radius: BorderRadius.circular(20)),

              const SizedBox(height: 30),

              skeleton(width: 200, height: 28),

              const SizedBox(height: 8),

              skeleton(width: 170, height: 18),

              const SizedBox(height: 18),

              skeleton(height: 420, radius: BorderRadius.circular(20)),

              const SizedBox(height: 30),

              skeleton(width: 200, height: 28),

              const SizedBox(height: 8),

              skeleton(width: 180, height: 18),

              const SizedBox(height: 18),

              skeleton(height: 280, radius: BorderRadius.circular(20)),

              const SizedBox(height: 25),

              analyticsCardSkeleton(),

              const SizedBox(height: 15),

              analyticsCardSkeleton(),

              const SizedBox(height: 15),

              analyticsCardSkeleton(),

              const SizedBox(height: 25),

              skeleton(height: 260, radius: BorderRadius.circular(20)),

              const SizedBox(height: 20),

              skeleton(height: 170, radius: BorderRadius.circular(18)),

              const SizedBox(height: 20),

              skeleton(height: 120, radius: BorderRadius.circular(18)),
            ],
          ),
        ),
      ),
    );
  }
}
