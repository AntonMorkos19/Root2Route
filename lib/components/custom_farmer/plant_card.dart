import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/models/plant_model.dart';
import 'package:root2route/screens/farmer/plant_details_screen.dart';

class PlantCard extends StatelessWidget {
  final PlantModel plant;

  const PlantCard({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PlantDetailsScreen(plant: plant)),
          ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.OnSecondary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PlantImage(plant: plant),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      plant.name,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),

                  if (plant.scientificName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      plant.scientificName!,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (plant.plantingSeason != null)
                        _InfoChip(
                          icon: Icons.local_florist,
                          label: plant.plantingSeason!,
                          color: const Color(0xFF2ECC71),
                        ),
                      if (plant.plantingSeason != null &&
                          plant.idealSoil != null)
                        const SizedBox(width: 8),
                      if (plant.idealSoil != null)
                        _InfoChip(
                          icon: Icons.terrain,
                          label: plant.idealSoil!,
                          color: Colors.brown.shade400,
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (plant.description != null)
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        plant.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                    ),

                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlantDetailsScreen(plant: plant),
                            ),
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: Text(
                        'View Details',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                           fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private helpers ────────────────────────────────────────────────────────────

class _PlantImage extends StatelessWidget {
  final PlantModel plant;
  const _PlantImage({required this.plant});

  @override
  Widget build(BuildContext context) {
    final url = plant.fullImageUrl;
    return Stack(
      children: [
        SizedBox(
          height: 200,
          width: double.infinity,
          child:
              url != null
                  ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _PlaceholderImage(),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          value:
                              progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                        ),
                      );
                    },
                  )
                  : _PlaceholderImage(),
        ),
        // Gradient overlay for readability
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 60,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(Icons.eco, size: 64, color: Color(0xFF2ECC71)),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
