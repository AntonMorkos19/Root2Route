import 'package:flutter/material.dart';
import 'package:root2route/core/theme/app_colors.dart';

class SettingsAccountCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final IconData iconButton;
  final VoidCallback onPressed;

  const SettingsAccountCard({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    required this.iconButton,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 7),

        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 17, color: AppColors.iconSecondary),
              ),
            ),
            Text(
              value ?? '',
              style: TextStyle(fontSize: 17, color: AppColors.textPrimary),
            ),
            IconButton(
              onPressed: onPressed,
              icon: Icon(iconButton, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
