import 'package:flutter/material.dart';
import 'package:root2route/core/theme/app_colors.dart';

class InfoAccountCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String info;
  const InfoAccountCard({
    super.key,
    required this.icon,
    required this.title,
    required this.info,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              info,
              style: TextStyle(fontSize: 17, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
