import 'package:quickalert/quickalert.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:root2route/components/custom_auth/auth_background.dart';
import 'package:root2route/components/custom_auth/auth_header.dart';
import 'package:root2route/components/custom_button.dart';
import 'package:root2route/components/custom_text_form_field.dart';
import 'package:root2route/core/responsive/app_sizes.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/features/auth/ui/otp_verification_screen.dart';
import 'package:root2route/core/services/api.dart';
 
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
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    textTheme: Theme.of(
                                      context,
                                    ).textTheme.copyWith(
                                      titleMedium: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                    inputDecorationTheme: Theme.of(
                                      context,
                                    ).inputDecorationTheme.copyWith(
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.15),
                                      hintStyle: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      labelStyle: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                      iconColor: Colors.white70,
                                      prefixIconColor: Colors.white70,
                                      suffixIconColor: Colors.white70,
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                          color: Colors.white54,
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                          color: AppColors.primary,
                                          width: 1.5,
                                        ),
                                      ),
                                      floatingLabelStyle: WidgetStateTextStyle.resolveWith((Set<WidgetState> states) {
                                        if (states.contains(WidgetState.error)) {
                                          return const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold);
                                        }
                                        if (states.contains(WidgetState.focused)) {
                                          return const TextStyle(color: Colors.green, fontWeight: FontWeight.bold);
                                        }
                                        return const TextStyle(color: Colors.white70);
                                      }),
                                    ),
                                  ),
                                  child: CustomTextFormField(
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
                                ),
                                const SizedBox(height: 25),

                                CustomButton(
                                  text: 'إرسال كود التحقق',
                                  onPressed: () async {
                                    if (!formKey.currentState!.validate())
                                      return;
                                    QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', 
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
                                          QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', context: context, type: QuickAlertType.success, title: 'نجاح', text: "تم إرسال كود التحقق إلى بريدك الإلكتروني",);
                                        }

                                        Future.delayed(
                                          const Duration(seconds: 2),
                                          () {
                                            if (mounted) {

                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (
                                                        context,
                                                      ) => OtpVerificationScreen(
                                                        email:
                                                            emailController
                                                                .text,
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
                                            barrierDismissible: false,
                                            confirmBtnText: 'المحاولة مرة أخرى',
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        Navigator.pop(context);
                                          QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', 
                                            context: context,
                                            type: QuickAlertType.error,
                                            title: 'فشلت العملية',
                                            text:
                                                'حدث خطأ ما. برجاء التحقق من الاتصال بالشبكة.',
                                            barrierDismissible: false,
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
