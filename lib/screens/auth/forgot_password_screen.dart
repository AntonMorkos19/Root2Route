import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:root2route/components/custom_auth/auth_background.dart';
import 'package:root2route/components/custom_auth/auth_header.dart';
import 'package:root2route/components/custom_button.dart';
import 'package:root2route/components/custom_text_form_field.dart';
import 'package:root2route/core/responsive/app_sizes.dart';
import 'package:root2route/screens/auth/recovery_screen.dart';
import 'package:root2route/services/api.dart';

class ForgotPasswordScreen extends StatefulWidget {
  static const String id = '/ForgotPasswordScreen';
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: AuthBackground(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSizes.paddingSize(context)),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AuthHeader(
                    title: 'Forgot Password?',
                    description:
                        'Enter your email address to receive a password reset link',
                    icon: Icons.lock_reset,
                  ),
                  const SizedBox(height: 16),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 11, sigmaY: 11),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                            width: 1,
                          ),
                        ),
                        child: Form(
                          key: formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomTextFormField(
                                icon: Icons.email_outlined,
                                label: 'Email Address',
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email address';
                                  }
                                  if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  ).hasMatch(value)) {
                                    return 'Email is incorrect';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 25),

                              CustomButton(
                                text: 'Send verification code',
                                onPressed: () async {
                                  if (!formKey.currentState!.validate()) return;
                                  QuickAlert.show(
                                    context: context,
                                    type: QuickAlertType.loading,
                                    title: 'Please Wait',
                                    text: 'Sending verification code...',
                                    barrierDismissible: false,
                                  );

                                  try {
                                    final result = await ApiService()
                                        .forgetPassword(emailController.text);

                                    // 2. Close Loading Alert
                                    Navigator.pop(context);

                                    if (result['success']) {
                                      // 3. Show Success Alert
                                      // 1. إظهار الـ Alert
                                      QuickAlert.show(
                                        context: context,
                                        type: QuickAlertType.success,
                                        title: 'Success',
                                        text:
                                            "Verification code sent to your email address",
                                        showConfirmBtn:
                                            false, // اختياري: لو عايز تخفي الزرار خالص بما إنه هينقل لوحده
                                      );

                                      // 2. الانتظار لمدة 3 ثواني ثم التنفيذ
                                      Future.delayed(
                                        const Duration(seconds: 3),
                                        () {
                                          if (mounted) {
                                            // إغلاق الـ Alert أولاً
                                            Navigator.pop(context);

                                            // الانتقال للصفحة التالية
                                            Navigator.pushNamedAndRemoveUntil(
                                              context,
                                              RecoveryScreen.id,
                                              (route) => false,
                                              arguments: emailController.text,
                                            );
                                          }
                                        },
                                      );
                                    } else {
                                      // 4. Show Error Alert (e.g., Email not found)
                                      QuickAlert.show(
                                        context: context,
                                        type: QuickAlertType.error,
                                        title: 'Oops...',
                                        text:
                                            result['message'], // This will show the server error in English
                                        confirmBtnText: 'Try Again',
                                      );
                                    }
                                  } catch (e) {
                                    Navigator.pop(context); // Close Loading
                                    QuickAlert.show(
                                      context: context,
                                      type: QuickAlertType.error,
                                      title: 'Error',
                                      text:
                                          'Something went wrong. Please check your connection.',
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
