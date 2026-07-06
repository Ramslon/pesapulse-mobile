import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,

        icon: icon != null ? Icon(icon) : const SizedBox.shrink(),

        label: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,

          child: isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  text,
                  key: const ValueKey('text'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }
}
