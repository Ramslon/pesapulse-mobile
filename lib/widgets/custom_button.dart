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

        icon: icon != null ? Icon(icon) : const SizedBox(),

        label: isLoading ? const CircularProgressIndicator() : Text(text),
      ),
    );
  }
}
