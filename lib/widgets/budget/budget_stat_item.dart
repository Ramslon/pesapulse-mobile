import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BudgetStatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final double amount;
  final bool compact;

  //final bool isLandscape;

  const BudgetStatItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.amount,
    required this.compact,

    //required this.isLandscape,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,##0");

    return Column(
      children: [
        CircleAvatar(
          radius: compact ? 16 : 20,
          backgroundColor: backgroundColor,
          child: Icon(icon, size: compact ? 18 : 24, color: iconColor),
        ),

        SizedBox(height: compact ? 6 : 10),

        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: amount),
          duration: const Duration(milliseconds: 1000),
          builder: (context, value, child) {
            return Text(
              "KES ${formatter.format(value)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: compact ? 15 : 17,
              ),
            );
          },
        ),

        SizedBox(height: compact ? 4 : 8),

        Text(title, style: TextStyle(fontSize: compact ? 12 : 14)),
      ],
    );
  }
}
