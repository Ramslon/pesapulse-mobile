import 'package:flutter/material.dart';

class ExpenseLoadingSkeleton extends StatefulWidget {
  const ExpenseLoadingSkeleton({super.key});

  @override
  State<ExpenseLoadingSkeleton> createState() => _ExpenseLoadingSkeletonState();
}

class _ExpenseLoadingSkeletonState extends State<ExpenseLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _placeholder({
    double height = 16,
    double width = double.infinity,
    BorderRadius? radius,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Color.lerp(
              Colors.grey.shade300,
              Colors.grey.shade100,
              _controller.value,
            ),
            borderRadius: radius ?? BorderRadius.circular(8),
          ),
        );
      },
    );
  }

  Widget _card() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _placeholder(width: 150, height: 18),

            const SizedBox(height: 12),

            _placeholder(width: 100),

            const SizedBox(height: 10),

            _placeholder(width: 80),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: _placeholder(height: 42)),
                const SizedBox(width: 10),
                Expanded(child: _placeholder(height: 42)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (_, __) => _card(),
    );
  }
}
