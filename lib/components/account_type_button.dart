import 'package:flutter/material.dart';
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: EdgeInsets.all(AppSizes.paddingSize(context)),
        decoration: BoxDecoration(
          color:
              selected
                  ? AppColors.OrganizationColor.withOpacity(0.18)
                  : const Color.fromARGB(255, 255, 255, 255),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                selected
                    ? AppColors.OrganizationColor
                    : const Color.fromARGB(255, 0, 0, 0).withOpacity(0.3),
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
                      ? AppColors.OrganizationColor
                      : const Color.fromARGB(255, 0, 0, 0),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color:
                      selected
                          ? AppColors.OrganizationColor
                          : const Color.fromARGB(255, 0, 0, 0),
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
