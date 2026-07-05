import 'package:flutter/material.dart';

class DashboardLoadingSkeleton extends StatelessWidget {
  const DashboardLoadingSkeleton({super.key});

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

  Widget dashboardCardSkeleton() {
    return Expanded(
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              skeleton(width: 180, height: 30),

              const SizedBox(height: 10),

              skeleton(width: 220, height: 18),

              const SizedBox(height: 30),

              Row(
                children: [
                  dashboardCardSkeleton(),
                  const SizedBox(width: 15),
                  dashboardCardSkeleton(),
                ],
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  dashboardCardSkeleton(),
                  const SizedBox(width: 15),
                  dashboardCardSkeleton(),
                ],
              ),

              const SizedBox(height: 30),

              skeleton(height: 55, radius: BorderRadius.circular(16)),

              const SizedBox(height: 30),

              skeleton(width: 150, height: 24),

              const SizedBox(height: 15),

              Expanded(
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, __) {
                    return Container(
                      height: 95,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
