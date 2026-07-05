import 'package:flutter/material.dart';

class InputIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const InputIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(.21),
          borderRadius: BorderRadius.circular(21),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
