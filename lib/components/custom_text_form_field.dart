import 'package:flutter/material.dart';
import 'package:root2route/core/theme/app_colors.dart';

class CustomTextFormField extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final Color? fillColor;
  final Color? borderColor;
  final Color? cursorColor;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Color? labelColor;
  final Color? iconColor;
  final bool? isReadOnly;
  final int? maxLines;
  final TextDirection? textDirection;

  const CustomTextFormField({
    super.key,
    required this.icon,
    required this.label,
    required this.controller,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.labelColor,
    this.iconColor,
    this.isReadOnly = false,
    this.maxLines,
    this.color,
    this.borderColor,
    this.cursorColor,
    this.fillColor,
    this.textDirection,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  bool obscureText = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final outlineColor = theme.colorScheme.outline;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: TextFormField(
        textAlign: widget.textDirection == TextDirection.ltr ? TextAlign.left : TextAlign.start,
        textDirection: widget.textDirection,
        controller: widget.controller,
        style: TextStyle(
        color:
            widget.color ??
            (theme.brightness == Brightness.dark
                ? Colors.white
                : Colors.black87),
      ),
      obscureText: widget.isPassword ? obscureText : false,
      cursorColor: widget.cursorColor ?? AppColors.primary,
      readOnly: widget.isReadOnly ?? false,
      maxLines: widget.maxLines ?? 1,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: Icon(widget.icon),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    obscureText = !obscureText;
                  });
                },
              )
            : null,
      ),
    ));
  }
}
