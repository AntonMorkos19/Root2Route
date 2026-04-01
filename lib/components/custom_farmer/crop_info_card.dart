import 'package:flutter/material.dart';
import 'package:root2route/models/info_crop_model.dart';

class CropInfoCard extends StatelessWidget {
  final InfoCropModel infoCrop;

  const CropInfoCard({super.key, required this.infoCrop});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(infoCrop.icon, color: infoCrop.iconColor, size: 20),
            const SizedBox(height: 4),
            Text(
              infoCrop.label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 2),
            Text(
              infoCrop.value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: infoCrop.valueColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
