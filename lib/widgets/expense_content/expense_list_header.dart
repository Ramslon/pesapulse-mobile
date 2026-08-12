import 'package:flutter/material.dart';
import 'package:pesapulse_mobile/utils/responsive_helper.dart';

class ExpenseListHeader extends StatelessWidget {
  final double horizontalPadding;

  const ExpenseListHeader({super.key, required this.horizontalPadding});

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Expenses",
            style: TextStyle(
              fontSize: compact ? 24 : 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "Track and manage your spending",
            style: TextStyle(color: Colors.grey, fontSize: compact ? 13 : 15),
          ),
        ],
      ),
    );
  }
}
