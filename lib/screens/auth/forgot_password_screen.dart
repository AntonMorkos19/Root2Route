import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:root2route/components/custom_auth/auth_background.dart';
import 'package:root2route/components/custom_auth/auth_header.dart';
import 'package:root2route/components/custom_button.dart';
import 'package:root2route/components/custom_text_form_field.dart';
import 'package:root2route/core/responsive/app_sizes.dart';
import 'package:root2route/screens/auth/otp_verification_screen.dart';
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
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AuthHeader(
                      title: 'نسيت كلمة المرور؟',
                      description:
                          'أدخل بريدك الإلكتروني لاستلام كود إعادة تعيين كلمة المرور',
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
                                  label: 'البريد الإلكتروني',
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  color: Colors.white,
                                  labelColor: Colors.white70,
                                  iconColor: Colors.white70,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'برجاء إدخال البريد الإلكتروني';
                                    }
                                    if (!RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(value)) {
                                      return 'بريد إلكتروني غير صحيح';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 25),

                                CustomButton(
                                  text: 'إرسال كود التحقق',
                                  onPressed: () async {
                                    if (!formKey.currentState!.validate()) return;
                                    QuickAlert.show(
                                      context: context,
                                      type: QuickAlertType.loading,
                                      title: 'برجاء الانتظار',
                                      text: 'جارٍ إرسال كود التحقق...',
                                      barrierDismissible: false,
                                    );

                                    try {
                                      final result = await ApiService()
                                          .forgetPassword(emailController.text);

                                      if (mounted) Navigator.pop(context);

                                      if (result['success']) {
                                        if (mounted) {
                                          QuickAlert.show(
                                            context: context,
                                            type: QuickAlertType.success,
                                            title: 'تم بنجاح!',
                                            text:
                                                "تم إرسال كود التحقق إلى بريدك الإلكتروني",
                                            showConfirmBtn: false,
                                          );
                                        }

                                        Future.delayed(
                                          const Duration(seconds: 3),
                                          () {
                                            if (mounted) {
                                              Navigator.pop(context);

                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (
                                                        context,
                                                      ) => OtpVerificationScreen(
                                                        email:
                                                            emailController.text,
                                                        type:
                                                            OtpType
                                                                .passwordRecovery, // ✅ Telling it that this is password recovery
                                                      ),
                                                ),
                                              );
                                            }
                                          },
                                        );
                                      } else {
                                        if (mounted) {
                                          QuickAlert.show(
                                            context: context,
                                            type: QuickAlertType.error,
                                            title: 'عذراً...',
                                            text: result['message'],
                                            confirmBtnText: 'المحاولة مرة أخرى',
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        Navigator.pop(context);
                                        QuickAlert.show(
                                          context: context,
                                          type: QuickAlertType.error,
                                          title: 'فشلت العملية',
                                          text:
                                              'حدث خطأ ما. برجاء التحقق من الاتصال بالشبكة.',
                                        );
                                      }
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
      ),
    );
  }
}
