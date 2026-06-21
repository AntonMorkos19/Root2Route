import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/components/custom_text_form_field.dart';
import 'package:root2route/core/services/storage_service.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/features/withdrawals/logic/withdrawal_cubit/withdrawal_cubit.dart';
import 'package:root2route/features/withdrawals/logic/withdrawal_cubit/withdrawal_state.dart';

/// Screen that lets an organization member submit a withdrawal request.
/// All form validation and submission logic delegates to [WithdrawalCubit].
class WithdrawalRequestScreen extends StatefulWidget {
  const WithdrawalRequestScreen({super.key});

  @override
  State<WithdrawalRequestScreen> createState() =>
      _WithdrawalRequestScreenState();
}

class _WithdrawalRequestScreenState extends State<WithdrawalRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  late final WithdrawalCubit _cubit;

  // Form field controllers
  final _amountController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _swiftCodeController = TextEditingController();

  /// Set to true after a successful submission to prevent re-submission.
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _cubit = WithdrawalCubit();
  }

  @override
  void dispose() {
    _cubit.close();
    _amountController.dispose();
    _bankNameController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _swiftCodeController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final orgId = StorageService().currentUserOrgId;
    if (orgId == null || orgId.isEmpty) {
      if (!mounted) return;
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'خطأ',
        text: 'لا يمكن تحديد هوية المؤسسة. يرجى تسجيل الدخول مجدداً.',
        confirmBtnText: 'حسناً',
        confirmBtnColor: AppColors.primary,
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    await _cubit.requestWithdrawal(
      organizationId: orgId,
      amount: amount,
      bankName: _bankNameController.text.trim(),
      accountName: _accountNameController.text.trim(),
      accountNumber: _accountNumberController.text.trim(),
      swiftCode: _swiftCodeController.text.trim().toUpperCase(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WithdrawalCubit>.value(
      value: _cubit,
      child: BlocListener<WithdrawalCubit, WithdrawalState>(
        // Side-effect listener: show dialogs without rebuilding the whole tree.
        listener: (context, state) {
          if (state is WithdrawalLoading) {
            // Show loading alert while the request is in flight.
            QuickAlert.show(
              context: context,
              type: QuickAlertType.loading,
              title: 'جاري الإرسال...',
              text: 'الرجاء الانتظار',
              barrierDismissible: false,
            );
          } else if (state is WithdrawalActionSuccess) {
            // Dismiss loading dialog, then show success and disable the button.
            Navigator.of(context, rootNavigator: true).pop();
            setState(() => _submitted = true);
            QuickAlert.show(
              context: context,
              type: QuickAlertType.success,
              title: 'نجاح',
              text: state.message,
              confirmBtnText: 'موافق',
              confirmBtnColor: AppColors.primary,
              onConfirmBtnTap: () => Navigator.of(context, rootNavigator: true).pop(),
            );
          } else if (state is WithdrawalError) {
            // Dismiss loading dialog if it is still visible, then show error.
            Navigator.of(context, rootNavigator: true).pop();
            QuickAlert.show(
              context: context,
              type: QuickAlertType.error,
              title: 'خطأ',
              text: state.message,
              confirmBtnText: 'حسناً',
              confirmBtnColor: AppColors.primary,
            );
          }
        },
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              title: const Text(
                'طلب سحب',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
              backgroundColor: AppColors.primary,
              iconTheme: const IconThemeData(color: Colors.white),
              elevation: 0,
            ),
            body: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header card ────────────────────────────────────────
                    Container(
                      padding: EdgeInsets.all(16.w),
                      margin: EdgeInsets.only(bottom: 24.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.primary,
                            size: 22.w,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              'سيتم مراجعة طلب السحب من قِبل الإدارة قبل تنفيذه.',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: AppColors.primary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Amount ─────────────────────────────────────────────
                    CustomTextFormField(
                      icon: Icons.attach_money_rounded,
                      label: 'المبلغ (جنيه)',
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        final parsed = double.tryParse(value?.trim() ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'يرجى إدخال مبلغ أكبر من صفر';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),

                    // ── Bank Name ──────────────────────────────────────────
                    CustomTextFormField(
                      icon: Icons.account_balance_rounded,
                      label: 'اسم البنك',
                      controller: _bankNameController,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'يرجى إدخال اسم البنك'
                              : null,
                    ),
                    SizedBox(height: 16.h),

                    // ── Account Name ───────────────────────────────────────
                    CustomTextFormField(
                      icon: Icons.person_outline_rounded,
                      label: 'اسم صاحب الحساب',
                      controller: _accountNameController,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'يرجى إدخال اسم الحساب'
                              : null,
                    ),
                    SizedBox(height: 16.h),

                    // ── Account Number ─────────────────────────────────────
                    CustomTextFormField(
                      icon: Icons.credit_card_rounded,
                      label: 'رقم الحساب',
                      controller: _accountNumberController,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'يرجى إدخال رقم الحساب'
                              : null,
                    ),
                    SizedBox(height: 16.h),

                    // ── SWIFT Code ─────────────────────────────────────────
                    CustomTextFormField(
                      icon: Icons.code_rounded,
                      label: 'رمز SWIFT',
                      controller: _swiftCodeController,
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        // SWIFT codes are 8 or 11 alphanumeric characters.
                        final swiftRegex = RegExp(r'^[A-Za-z0-9]{8,11}$');
                        if (!swiftRegex.hasMatch(v)) {
                          return 'رمز SWIFT يجب أن يتكون من 8 إلى 11 حرفاً أو رقماً';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 32.h),

                    // ── Submit button ──────────────────────────────────────
                    BlocBuilder<WithdrawalCubit, WithdrawalState>(
                      builder: (context, state) {
                        final isLoading = state is WithdrawalLoading;
                        final isDisabled = isLoading || _submitted;

                        return ElevatedButton(
                          onPressed: isDisabled ? null : _onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor:
                                AppColors.primary.withValues(alpha: 0.4),
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child:
                              isLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Text(
                                    _submitted ? 'تم الإرسال' : 'إرسال الطلب',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.sp,
                                    ),
                                  ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
