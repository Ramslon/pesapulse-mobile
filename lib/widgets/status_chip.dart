import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const StatusChip({
    super.key,
    required this.text,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).orientation == Orientation.landscape;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 5 : 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 16, color: color),

          SizedBox(width: compact ? 4 : 6),

          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 11 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
