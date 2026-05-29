import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/models/plant_model.dart';
import 'package:root2route/services/api.dart';
import 'package:root2route/models/plant_step_model.dart';

class PlantDetailsScreen extends StatefulWidget {
  final PlantModel plant;

  const PlantDetailsScreen({super.key, required this.plant});

  @override
  State<PlantDetailsScreen> createState() => _PlantDetailsScreenState();
}

class _PlantDetailsScreenState extends State<PlantDetailsScreen> {
  final ApiService _api = ApiService();
  List<PlantStepModel> _plantSteps = [];
  bool _stepsLoading = true;
  String? _stepsError;

  @override
  void initState() {
    super.initState();
    _loadPlantSteps();
  }

  Future<void> _loadPlantSteps() async {
    setState(() {
      _stepsLoading = true;
      _stepsError = null;
    });

    final result = await _api.getPlantDetails(widget.plant.id);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _plantSteps = result['data'] as List<PlantStepModel>;
        _stepsLoading = false;
      });
    } else {
      setState(() {
        _stepsError = result['message'];
        _stepsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final plant = widget.plant;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plant.name,
                          textAlign: TextAlign.start,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28.sp,
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
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16.sp,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
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
                      title: 'الوصف',
                      content: plant.description!,
                    ),

                  // Medical Benefits
                  if (plant.medicalBenefits != null)
                    _DetailSection(
                      icon: Icons.local_hospital_outlined,
                      iconColor: const Color(0xFFE74C3C),
                      title: 'الفوائد الطبية',
                      content: plant.medicalBenefits!,
                    ),

                  // Ideal Soil
                  if (plant.idealSoil != null)
                    _DetailSection(
                      icon: Icons.terrain,
                      iconColor: Colors.brown.shade400,
                      title: 'التربة المثالية',
                      content: plant.idealSoil!,
                    ),

                  // Planting Season
                  if (plant.plantingSeason != null)
                    _DetailSection(
                      icon: Icons.calendar_month_outlined,
                      iconColor: const Color(0xFF2ECC71),
                      title: 'موسم الزراعة',
                      content: plant.plantingSeason!,
                    ),

                  if (plant.description == null &&
                      plant.medicalBenefits == null &&
                      plant.idealSoil == null &&
                      plant.plantingSeason == null)
                    _EmptyDetails(),

                  const SizedBox(height: 28),
                  Text(
                    'خطوات زراعة النبات',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildPlantingSteps(),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildHeroImage() {
    final url = widget.plant.fullImageUrl;
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

  Widget _buildPlantingSteps() {
    if (_stepsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_stepsError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.orange, size: 32),
            const SizedBox(height: 8),
            Text(
              _stepsError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadPlantSteps,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('إعادة المحاولة'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
      );
    }

    if (_plantSteps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: _plantSteps.length,
        itemBuilder: (context, index) {
          final step = _plantSteps[index];
          final isLast = index == _plantSteps.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${step.stepOrder}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            step.title,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          step.instruction,
                          style: TextStyle(
                            fontSize: 16.sp,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
          label: 'الموسم',
          value: plant.plantingSeason!,
          color: AppColors.primary,
        ),
      );

    if (plant.idealSoil != null)
      items.add(
        _QuickInfoItem(
          icon: Icons.terrain,
          label: 'التربة',
          value: plant.idealSoil!,
          color: Colors.brown.shade400,
        ),
      );

    if (plant.medicalBenefits != null)
      items.add(
        _QuickInfoItem(
          icon: Icons.spa_outlined,
          label: 'الفوائد',
          value: 'متاحة',
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
                            fontSize: 12.sp,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.value,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
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
          color: Theme.of(context).cardColor,
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
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: Theme.of(context).dividerColor),
            ),

            // Content
            Text(
              content,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 16.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            Icon(
              Icons.eco_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 14),
            Text(
              'لا تتوفر تفاصيل إضافية',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16.sp,
              ),
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
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(Icons.eco, size: 80, color: AppColors.primary),
      ),
    );
  }
}
