import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.validator,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  Color _getIconColor(IconData? icon) {
    switch (icon) {
      case Icons.person_outline:
        return Colors.blue;

      case Icons.email_outlined:
        return Colors.orange;

      case Icons.lock_outline:
        return Colors.purple;

      case Icons.phone_outlined:
        return Colors.teal;

      case Icons.account_balance_wallet_outlined:
        return Colors.green;

      case Icons.calendar_today_outlined:
        return Colors.redAccent;

      case Icons.savings_outlined:
        return Colors.indigo;

      default:
        return Colors.green;
    }
  }

  Color _getIconBackground(IconData? icon) {
    switch (icon) {
      case Icons.person_outline:
        return Colors.blue.shade50;

      case Icons.email_outlined:
        return Colors.orange.shade50;

      case Icons.lock_outline:
        return Colors.purple.shade50;

      case Icons.phone_outlined:
        return Colors.teal.shade50;

      case Icons.account_balance_wallet_outlined:
        return Colors.green.shade50;

      case Icons.calendar_today_outlined:
        return Colors.red.shade50;

      case Icons.savings_outlined:
        return Colors.indigo.shade50;

      default:
        return Colors.green.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: _obscure,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,

        prefixIcon: widget.prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: _getIconBackground(widget.prefixIcon),
                  child: Icon(
                    widget.prefixIcon,
                    size: 20,
                    color: _getIconColor(widget.prefixIcon),
                  ),
                ),
              )
            : null,

        filled: true,
        fillColor: Theme.of(context).cardColor,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),

        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscure = !_obscure;
                  });
                },
              )
            : null,
      ),
    );
  }
}
