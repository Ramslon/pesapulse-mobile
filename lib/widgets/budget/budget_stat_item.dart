import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_spacing.dart';

class BudgetStatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final double amount;

  const BudgetStatItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,##0.00");

    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: backgroundColor,
          child: Icon(icon, color: iconColor),
        ),

        const SizedBox(height: 6),

        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: amount),
          duration: const Duration(milliseconds: 1000),
          builder: (context, value, child) {
            return Text(
              "KES ${formatter.format(value)}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            );
          },
        ),

        AppSpacing.sm,

        Text(title),
      ],
    );
  }
}
