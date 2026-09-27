import 'package:flutter/material.dart';

import '../utils/responsive_helper.dart';

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

  Color _getIconColor(BuildContext context, IconData? icon) {
    final colorScheme = Theme.of(context).colorScheme;

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
        return colorScheme.primary;
    }
  }

  Color _getIconBackground(BuildContext context, IconData? icon) {
    final color = _getIconColor(context, icon);

    return color.withOpacity(0.10);
  }

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final tablet = ResponsiveHelper.isTablet(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final iconColor = _getIconColor(context, widget.prefixIcon);

    final fieldRadius = desktop
        ? 17.0
        : tablet
        ? 16.0
        : compact
        ? 13.0
        : landscape
        ? 14.0
        : 16.0;

    final fieldHeight = desktop
        ? 58.0
        : tablet
        ? 56.0
        : compact
        ? 48.0
        : landscape
        ? 50.0
        : 54.0;

    final fieldFontSize = desktop
        ? 15.0
        : tablet
        ? 14.5
        : compact
        ? 12.5
        : landscape
        ? 13.0
        : 14.5;

    final labelFontSize = desktop
        ? 14.0
        : compact
        ? 11.5
        : 13.0;

    final iconContainerSize = desktop
        ? 36.0
        : tablet
        ? 34.0
        : compact
        ? 29.0
        : landscape
        ? 31.0
        : 34.0;

    final iconSize = desktop
        ? 18.0
        : tablet
        ? 17.0
        : compact
        ? 14.0
        : landscape
        ? 15.0
        : 17.0;

    return SizedBox(
      height: widget.validator == null ? fieldHeight : null,
      child: TextFormField(
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        obscureText: _obscure,
        validator: widget.validator,
        style: TextStyle(
          fontSize: fieldFontSize,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        cursorColor: colorScheme.primary,
        decoration: InputDecoration(
          labelText: widget.label,

          labelStyle: TextStyle(
            fontSize: labelFontSize,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.55),
          ),

          floatingLabelStyle: TextStyle(
            fontSize: labelFontSize,
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),

          prefixIcon: widget.prefixIcon != null
              ? Padding(
                  padding: EdgeInsets.only(
                    left: compact ? 7 : 9,
                    right: compact ? 2 : 4,
                  ),
                  child: SizedBox(
                    width: iconContainerSize,
                    height: iconContainerSize,
                    child: Center(
                      child: Container(
                        width: iconContainerSize,
                        height: iconContainerSize,
                        decoration: BoxDecoration(
                          color: _getIconBackground(context, widget.prefixIcon),
                          borderRadius: BorderRadius.circular(compact ? 9 : 10),
                        ),
                        child: Icon(
                          widget.prefixIcon,
                          size: iconSize,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ),
                )
              : null,

          prefixIconConstraints: BoxConstraints(
            minWidth: compact ? 47 : 54,
            maxWidth: compact ? 54 : 62,
            minHeight: fieldHeight,
            maxHeight: fieldHeight,
          ),

          suffixIcon: widget.obscureText
              ? IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  splashRadius: compact ? 18 : 20,
                  onPressed: () {
                    setState(() {
                      _obscure = !_obscure;
                    });
                  },
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: compact ? 18 : 20,
                    color: colorScheme.onSurface.withOpacity(0.45),
                  ),
                )
              : null,

          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.52),

          contentPadding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 12 : 15,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(fieldRadius),
            borderSide: BorderSide(
              color: colorScheme.outline.withOpacity(0.08),
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(fieldRadius),
            borderSide: BorderSide(
              color: colorScheme.outline.withOpacity(0.08),
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(fieldRadius),
            borderSide: BorderSide(
              color: colorScheme.primary.withOpacity(0.65),
              width: 1.4,
            ),
          ),

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(fieldRadius),
            borderSide: BorderSide(color: colorScheme.error.withOpacity(0.60)),
          ),

          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(fieldRadius),
            borderSide: BorderSide(color: colorScheme.error, width: 1.3),
          ),

          errorStyle: TextStyle(
            fontSize: compact ? 10 : 11,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
