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
  final bool? isReadOnly;
  final int? maxLines;

  const CustomTextFormField({
    super.key,
    required this.icon,
    required this.label,
    required this.controller,
    this.isPassword = false,
    this.keyboardType,
    this.validator,
    this.isReadOnly = false,
    this.maxLines,
    this.color,
    this.borderColor,
    this.cursorColor,
    this.fillColor,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  bool obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      style: TextStyle(color: widget.color ?? Colors.white),
      obscureText: widget.isPassword ? obscureText : false,
      cursorColor: widget.cursorColor ?? AppColors.primary,
      readOnly: widget.isReadOnly ?? false,
      maxLines: widget.maxLines ?? 1,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      decoration: InputDecoration(
        fillColor: widget.fillColor ?? Colors.transparent,
        filled: true,
        labelText: widget.label,
        labelStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(WidgetState.error)) {
            return const TextStyle(color: AppColors.colorError);
          }
          if (states.contains(WidgetState.focused)) {
            return TextStyle(color: AppColors.primary);
          }
          return TextStyle(color: AppColors.textOnSecondary);
        }),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(WidgetState.error)) {
            return const TextStyle(color: AppColors.colorError);
          }
          if (states.contains(WidgetState.focused)) {
            return TextStyle(color: widget.borderColor ?? AppColors.primary);
          }
          return TextStyle(color: AppColors.textOnSecondary);
        }),
        prefixIcon: Icon(widget.icon),
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.error)) {
            return AppColors.colorError;
          }
          if (states.contains(WidgetState.focused)) {
            return widget.borderColor ?? AppColors.primary;
          }
          return AppColors.iconSecondary;
        }),
        suffixIcon:
            widget.isPassword
                ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.iconSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      obscureText = !obscureText;
                    });
                  },
                )
                : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.Secondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: widget.borderColor ?? AppColors.primary,
            width: 2,
          ),
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
    );
  }
}
