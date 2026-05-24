import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/components/custom_text_form_field.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/features/reviews/cubit/review_cubit.dart';
import 'package:root2route/features/reviews/cubit/review_state.dart';

/// Shows the Add Review dialog.
///
/// Call this helper from any screen to open the review dialog
/// with the required identifiers already injected.
void showAddReviewDialog(
  BuildContext context, {
  required String targetOrganizationId,
  required String orderId,
  required String productId,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AddReviewDialog(
      targetOrganizationId: targetOrganizationId,
      orderId: orderId,
      productId: productId,
    ),
  );
}

class AddReviewDialog extends StatefulWidget {
  final String targetOrganizationId;
  final String orderId;
  final String productId;

  const AddReviewDialog({
    super.key,
    required this.targetOrganizationId,
    required this.orderId,
    required this.productId,
  });

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  final _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _selectedRating = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit(BuildContext ctx) {
    if (_selectedRating == 0) {
      QuickAlert.show(
        context: ctx,
        type: QuickAlertType.warning,
        title: 'Rating Required',
        text: 'Please select a star rating before submitting.',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    ctx.read<ReviewCubit>().submitReview(
          targetOrganizationId: widget.targetOrganizationId,
          orderId: widget.orderId,
          productId: widget.productId,
          rating: _selectedRating,
          comment: _commentController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReviewCubit(),
      child: BlocConsumer<ReviewCubit, ReviewState>(
        listener: (context, state) {
        if (state is ReviewSubmitSuccess) {
          Navigator.of(context).pop(); // Close the dialog first
          QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            title: 'Thank You!',
            text: state.message,
            confirmBtnColor: AppColors.primary,
          );
        } else if (state is ReviewError) {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.error,
            title: 'Oops...',
            text: state.message,
          );
        }
      },
      builder: (innerContext, state) {
        final isLoading = state is ReviewLoading;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ─────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.rate_review_rounded,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Leave a Review',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Share your experience with this product',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Star Rating ────────────────────────────
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Your Rating',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final starIndex = index + 1;
                            return GestureDetector(
                              onTap: isLoading
                                  ? null
                                  : () => setState(
                                      () => _selectedRating = starIndex),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6),
                                child: Icon(
                                  starIndex <= _selectedRating
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: starIndex <= _selectedRating
                                      ? const Color(0xFFFFB300)
                                      : Colors.grey.shade400,
                                  size: 36,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    if (_selectedRating > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        _ratingLabel(_selectedRating),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.amber.shade700,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Comment Field ──────────────────────────
                    CustomTextFormField(
                      icon: Icons.comment_outlined,
                      label: 'Your Comment',
                      controller: _commentController,
                      maxLines: 3,
                      color: AppColors.textPrimary,
                      fillColor: Colors.white,
                      borderColor: AppColors.primary,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please write a comment';
                        }
                        if (value.trim().length < 3) {
                          return 'Comment must be at least 3 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // ── Buttons ────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                isLoading ? null : () => Navigator.pop(innerContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                  fontSize: 16.sp, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : () => _submit(innerContext),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor:
                                  AppColors.primary.withOpacity(0.5),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Submit Review',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ));
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return '⭐ Poor';
      case 2:
        return '⭐⭐ Fair';
      case 3:
        return '⭐⭐⭐ Good';
      case 4:
        return '⭐⭐⭐⭐ Very Good';
      case 5:
        return '⭐⭐⭐⭐⭐ Excellent!';
      default:
        return '';
    }
  }
}
