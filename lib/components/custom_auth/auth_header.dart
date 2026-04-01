import 'package:flutter/material.dart';
import 'package:root2route/core/theme/app_colors.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const AuthHeader({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 38,
          backgroundColor: Colors.white.withOpacity(0.15),
          child: Icon(
            icon,
            size: 36,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: const Color.fromARGB(240, 255, 255, 255),
          ),
        ),
      ],
    );
  }
}