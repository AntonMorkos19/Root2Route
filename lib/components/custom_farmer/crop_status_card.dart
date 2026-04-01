import 'package:flutter/material.dart';
import 'package:root2route/models/crop_status_card_model.dart';

class CropStatusCard extends StatelessWidget {
  final CropStatusCardModel featureCrop;

  const CropStatusCard({super.key, required this.featureCrop});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: featureCrop.seasonColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(
                featureCrop.seasonIcon,
                size: 16,
                color: featureCrop.seasonColor,
              ),
              const SizedBox(width: 6),
              Text(
                featureCrop.season,
                style: TextStyle(
                  color: featureCrop.seasonColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: featureCrop.marketColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(
                featureCrop.marketIcon,
                size: 16,
                color: featureCrop.marketColor,
              ),
              const SizedBox(width: 6),
              Text(
                featureCrop.marketStatus,
                style: TextStyle(
                  color: featureCrop.marketColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
