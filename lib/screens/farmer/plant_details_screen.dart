import 'package:flutter/material.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/models/plant_model.dart';

class PlantDetailsScreen extends StatelessWidget {
  final PlantModel plant;

  const PlantDetailsScreen({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildHeroImage(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.40),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            plant.name,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 8),
                              ],
                            ),
                          ),
                          if (plant.scientificName != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              plant.scientificName!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _QuickInfoRow(plant: plant),

                  const SizedBox(height: 28),

                  if (plant.description != null)
                    _DetailSection(
                      icon: Icons.info_outline,
                      iconColor: const Color(0xFF3498DB),
                      title: 'description',
                      content: plant.description!,
                    ),

                  // Medical Benefits
                  if (plant.medicalBenefits != null)
                    _DetailSection(
                      icon: Icons.local_hospital_outlined,
                      iconColor: const Color(0xFFE74C3C),
                      title: '  Medical benefits',
                      content: plant.medicalBenefits!,
                    ),

                  // Ideal Soil
                  if (plant.idealSoil != null)
                    _DetailSection(
                      icon: Icons.terrain,
                      iconColor: Colors.brown.shade400,
                      title: 'Ideal soil ',
                      content: plant.idealSoil!,
                    ),

                  // Planting Season
                  if (plant.plantingSeason != null)
                    _DetailSection(
                      icon: Icons.calendar_month_outlined,
                      iconColor: const Color(0xFF2ECC71),
                      title: 'Planting season  ',
                      content: plant.plantingSeason!,
                    ),

                  // Empty state when no details available
                  if (plant.description == null &&
                      plant.medicalBenefits == null &&
                      plant.idealSoil == null &&
                      plant.plantingSeason == null)
                    _EmptyDetails(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroImage() {
    final url = plant.fullImageUrl;
    if (url == null) return _PlaceholderImage();
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _PlaceholderImage(),
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(
          color: Colors.grey.shade200,
          child: Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              value:
                  progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
            ),
          ),
        );
      },
    );
  }
}

// ── Private Widgets ────────────────────────────────────────────────────────────

class _QuickInfoRow extends StatelessWidget {
  final PlantModel plant;
  const _QuickInfoRow({required this.plant});

  @override
  Widget build(BuildContext context) {
    final items = <_QuickInfoItem>[];

    if (plant.plantingSeason != null)
      items.add(
        _QuickInfoItem(
          icon: Icons.local_florist,
          label: 'Season',
          value: plant.plantingSeason!,
          color: const Color(0xFF2ECC71),
        ),
      );

    if (plant.idealSoil != null)
      items.add(
        _QuickInfoItem(
          icon: Icons.terrain,
          label: 'Soil',
          value: plant.idealSoil!,
          color: Colors.brown.shade400,
        ),
      );

    if (plant.medicalBenefits != null)
      items.add(
        _QuickInfoItem(
          icon: Icons.spa_outlined,
          label: 'Benefits',
          value: 'Available',
          color: const Color(0xFFE74C3C),
        ),
      );

    if (items.isEmpty) return const SizedBox.shrink();

    return Row(
      children:
          items
              .map(
                (item) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: item.color.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: item.color.withValues(alpha: 0.15),
                          child: Icon(item.icon, color: item.color, size: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.value,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: item.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _QuickInfoItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _QuickInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;

  const _DetailSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: iconColor.withValues(alpha: 0.12),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: Color(0xFFEEEEEE)),
            ),

            // Content
            Text(
              content,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(Icons.eco_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text(
              'No additional details available',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(Icons.eco, size: 80, color: Color(0xFF2ECC71)),
      ),
    );
  }
}
