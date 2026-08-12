import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class ExpenseDateHeader extends StatelessWidget {
  final String title;

  const ExpenseDateHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);
    final spacing = ResponsiveHelper.spacing(context);

    final fontSize = compact ? 13.0 : 15.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        compact ? 14 : 18,
        horizontalPadding,
        compact ? 8 : 10,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          SizedBox(width: spacing * 0.75),

          Expanded(child: Divider(thickness: 1, color: Colors.grey.shade300)),
        ],
      ),
    );
  }
}
