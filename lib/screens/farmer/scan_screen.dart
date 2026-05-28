import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:root2route/components/custom_farmer/selection_card.dart';
import 'package:root2route/core/packages/Image_picker_helper.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/features/scan/cubit/scan_cubit.dart';
import 'package:root2route/features/scan/cubit/scan_state.dart';
import 'package:root2route/features/scan/models/plant_analysis_response_model.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ScanCubit(),
      child: const _ScanView(),
    );
  }
}

// ── Private stateful view (owns the BlocListener) ─────────────────────────────

class _ScanView extends StatelessWidget {
  const _ScanView();

  Future<void> _pickAndAnalyze(
    BuildContext context,
    ImageSource source,
  ) async {
    final file = await ImagePickerHelper.pickImage(source);
    if (file == null) return;
    if (!context.mounted) return;
    context.read<ScanCubit>().uploadAndAnalyzeImage(File(file.path));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScanCubit, ScanState>(
      listener: (context, state) {
        if (state is ScanSuccess) {
          _showResultSheet(context, state.result);
        } else if (state is ScanFailure) {
          _showErrorSheet(context, state.error);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: 70,
          title: Text(
            'Scan Crop',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<ScanCubit, ScanState>(
          builder: (context, state) {
            final isLoading = state is ScanLoading;

            return Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'Take a photo of the affected plant to identify the disease.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18.sp,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 40),
                        AbsorbPointer(
                          absorbing: isLoading,
                          child: Row(
                            children: [
                              Expanded(
                                child: SelectionCard(
                                  title: 'Camera',
                                  icon: Icons.camera_alt_rounded,
                                  onTap: () => _pickAndAnalyze(
                                    context,
                                    ImageSource.camera,
                                  ),
                                  gradientColors: const [
                                    Color(0xFF66BB6A),
                                    Color(0xFF388E3C),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: SelectionCard(
                                  title: 'Gallery',
                                  icon: Icons.photo_library_rounded,
                                  onTap: () => _pickAndAnalyze(
                                    context,
                                    ImageSource.gallery,
                                  ),
                                  gradientColors: const [
                                    Color(0xFFFFA726),
                                    Color(0xFFF57C00),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 35),
                        _TipContainer(),
                      ],
                    ),
                  ),
                ),

                // ── Fullscreen loading overlay ─────────────────────────────
                if (isLoading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.6),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'AI is Analyzing...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Result bottom sheet ────────────────────────────────────────────────────

  void _showResultSheet(BuildContext context, PlantAnalysisResponseModel result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ResultSheet(result: result, scanCubit: context.read<ScanCubit>()),
    );
  }

  void _showErrorSheet(BuildContext context, String error) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ErrorSheet(error: error, scanCubit: context.read<ScanCubit>()),
    );
  }
}

// ── Tip Container ──────────────────────────────────────────────────────────────

class _TipContainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Focus on the affected part of the plant for 98% more accurate results.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Result Sheet ───────────────────────────────────────────────────────────────

class _ResultSheet extends StatelessWidget {
  final PlantAnalysisResponseModel result;
  final ScanCubit scanCubit;

  const _ResultSheet({required this.result, required this.scanCubit});

  Color _severityColor(String? severity) {
    switch ((severity ?? '').toLowerCase()) {
      case 'high':
      case 'critical':
      case 'severe':
        return Colors.red.shade600;
      case 'medium':
      case 'moderate':
        return Colors.orange.shade600;
      case 'low':
      case 'mild':
        return Colors.green.shade600;
      default:
        return Colors.blueGrey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ────────────────────────────────────────────
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Header row ────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.biotech_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Analysis Result',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Disease name ──────────────────────────────────────
          _InfoRow(
            icon: Icons.local_florist_rounded,
            label: 'Disease Detected',
            value: result.diseaseName ?? 'Unknown',
            valueColor: AppColors.primary,
          ),
          const SizedBox(height: 12),

          // ── Confidence ────────────────────────────────────────
          if (result.confidenceScore != null) ...[
            _InfoRow(
              icon: Icons.percent_rounded,
              label: 'Confidence',
              value: result.confidencePercent,
            ),
            const SizedBox(height: 12),
          ],

          // ── Severity ──────────────────────────────────────────
          if (result.severity != null) ...[
            _InfoRow(
              icon: Icons.warning_amber_rounded,
              label: 'Severity',
              value: result.severity!,
              valueColor: _severityColor(result.severity),
            ),
            const SizedBox(height: 12),
          ],

          // ── Recommendation ────────────────────────────────────
          if (result.recommendation != null) ...[
            Divider(
              color: isDark ? Colors.white12 : Colors.black12,
              height: 24,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.recommend_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommendation',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.recommendation!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          height: 1.5,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 16),

          // ── Scan Again button ─────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Scan Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                scanCubit.reset();
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error Sheet ────────────────────────────────────────────────────────────────

class _ErrorSheet extends StatelessWidget {
  final String error;
  final ScanCubit scanCubit;

  const _ErrorSheet({required this.error, required this.scanCubit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 52),
          const SizedBox(height: 12),
          Text(
            'Analysis Failed',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                scanCubit.reset();
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Row ───────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: valueColor ?? theme.textTheme.titleMedium?.color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
