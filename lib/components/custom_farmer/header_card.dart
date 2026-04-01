import 'package:flutter/material.dart';
import 'package:root2route/core/theme/app_colors.dart';

class HeaderCard extends StatelessWidget {
  final String url;
  final String title;

  const HeaderCard({super.key, required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 230,
          child: Image.asset(url, fit: BoxFit.cover),
        ),

        Positioned(
          left: 12,
          bottom: 12,
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.iconPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
            ),
          ),
        ),
      ],
    );
  }
}
