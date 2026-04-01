import 'package:flutter/material.dart';
import 'package:root2route/components/custom_button.dart';
import 'package:root2route/components/custom_farmer/crop_info_card.dart';
import 'package:root2route/components/custom_farmer/crop_status_card.dart';
import 'package:root2route/components/custom_farmer/header_card.dart';
import 'package:root2route/core/responsive/app_sizes.dart';
import 'package:root2route/models/crop_status_card_model.dart';
import 'package:root2route/models/info_crop_model.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/screens/farmer/crop_details_screen.dart';

class CropCard extends StatelessWidget {
  const CropCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(AppSizes.marginSize(context)),
          padding: EdgeInsets.all(AppSizes.paddingSize(context)),
          decoration: BoxDecoration(
            color: AppColors.OnSecondary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: HeaderCard(
                  url: 'assets/images/crop.jpg',
                  title: 'Wheat',
                ),
              ),
              const SizedBox(height: 12),

              CropStatusCard(
                featureCrop: CropStatusCardModel(
                  season: "winter",
                  marketStatus: "High market demand",
                  seasonIcon: Icons.local_florist,
                  seasonColor: Colors.green,
                  marketIcon: Icons.store,
                  marketColor: Colors.blue,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: CropInfoCard(
                      infoCrop: InfoCropModel(
                        icon: Icons.eco,
                        iconColor: Colors.green,
                        label: "Soil",
                        value: "Sandy",
                        valueColor: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CropInfoCard(
                      infoCrop: InfoCropModel(
                        icon: Icons.schedule,
                        iconColor: Colors.blue,
                        label: "Duration",
                        value: "140 days",
                        valueColor: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CropInfoCard(
                      infoCrop: InfoCropModel(
                        icon: Icons.water_drop,
                        iconColor: Colors.orange,
                        label: "Water",
                        value: "Medium",
                        valueColor: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              CustomButton(
                text: "View details",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CropDetailsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
