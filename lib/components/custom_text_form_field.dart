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
        fillColor: widget.fillColor ?? Colors.white.withOpacity(0.001),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        labelText: widget.label,
        labelStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(WidgetState.error)) {
            return const TextStyle(color: AppColors.colorError);
          }
          if (states.contains(WidgetState.focused)) {
            return const TextStyle(color: AppColors.primary);
          }
          return TextStyle(color: widget.labelColor ?? onSurfaceVariant);
        }),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(WidgetState.error)) {
            return const TextStyle(color: AppColors.colorError);
          }
          if (states.contains(WidgetState.focused)) {
            return TextStyle(color: widget.borderColor ?? AppColors.primary);
          }
          return TextStyle(color: widget.labelColor ?? onSurfaceVariant);
        }),
        suffixIcon: Icon(widget.icon),
        suffixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.error)) {
            return AppColors.colorError;
          }
          if (states.contains(WidgetState.focused)) {
            return widget.borderColor ?? AppColors.primary;
          }
          return widget.iconColor ?? onSurfaceVariant;
        }),
        prefixIcon:
            widget.isPassword
                ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: widget.iconColor ?? onSurfaceVariant,
                  ),
                  onPressed: () {
                    setState(() {
                      obscureText = !obscureText;
                    });
                  },
                )
                : null,
        errorMaxLines: 3,
        errorStyle: const TextStyle(color: AppColors.colorError),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: widget.borderColor ?? Colors.white.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.colorError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.colorError, width: 2),
        ),
      ),
    ));
  }
}
