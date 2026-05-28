import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:root2route/core/responsive/app_sizes.dart';
import 'package:root2route/core/theme/app_colors.dart';

class AccountTypeButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const AccountTypeButton({
    super.key,
    required this.text,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedBgColor = isDark ? (Theme.of(context).cardColor) : const Color.fromARGB(255, 255, 255, 255);
    final unselectedBorderColor = isDark ? Colors.white24 : const Color.fromARGB(255, 0, 0, 0).withOpacity(0.3);
    final unselectedTextColor = isDark ? Colors.white70 : const Color.fromARGB(255, 0, 0, 0);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.all(AppSizes.paddingSize(context)),
        decoration: BoxDecoration(
          color:
              selected
                  ? AppColors.primary.withOpacity(0.18)
                  : unselectedBgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                selected
                    ? AppColors.primary
                    : unselectedBorderColor,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 26,
              color:
                  selected
                      ? AppColors.primary
                      : unselectedTextColor,
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color:
                      selected
                          ? AppColors.primary
                          : unselectedTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum AccountType { farmer, restaurant, factory, tradesman }
