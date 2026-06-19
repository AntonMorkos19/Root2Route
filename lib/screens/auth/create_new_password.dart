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
import 'package:root2route/screens/auth/login_screen.dart';
import 'package:root2route/services/api.dart';
 
class CreateNewPassword extends StatefulWidget {
  static const String id = '/re-enter-passwordScreen';
  const CreateNewPassword({super.key});

  @override
  State<CreateNewPassword> createState() => _CreateNewPasswordState();
}

class _CreateNewPasswordState extends State<CreateNewPassword> {
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  String email = '';
  dynamic otp;
  dynamic data;

  @override
  Widget build(BuildContext context) {
    data = ModalRoute.of(context)!.settings.arguments;
    email = data['email'];
    otp = data['code'];

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
                      title: 'إنشاء كلمة مرور جديدة',
                      description:
                          'يجب أن تكون كلمة المرور الجديدة مختلفة عن كلمات المرور المستخدمة سابقاً.',
                      icon: Icons.password_rounded,
                    ),
                    const SizedBox(height: 16),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 11, sigmaY: 11),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
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
                              children: [
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    textTheme: Theme.of(context).textTheme.copyWith(
                                      titleMedium: const TextStyle(color: Colors.white), 
                                    ),
                                    inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
                                      filled: true,
                                      fillColor: Colors.white.withOpacity(0.15),
                                      hintStyle: const TextStyle(color: Colors.white70),
                                      labelStyle: const TextStyle(color: Colors.white70),
                                      iconColor: Colors.white70,
                                      prefixIconColor: Colors.white70,
                                      suffixIconColor: Colors.white70,
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: Colors.white54, width: 1),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
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
                                  child: Column(
                                    children: [
                                      CustomTextFormField(
                                  icon: Icons.lock_outline,
                                  label: 'كلمة المرور الجديدة',
                                  controller: passwordController,
                                  isPassword: true,
                                  textDirection: TextDirection.ltr,
                                  color: Colors.white,
                                  labelColor: Colors.white70,
                                  iconColor: Colors.white70,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "برجاء إدخال كلمة المرور";
                                    }
                                    if (!RegExp(
                                      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d\w\W]{8,}$',
                                    ).hasMatch(value)) {
                                      return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل وتحتوي على حرف كبير وصغير ورقم';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 15),

                                CustomTextFormField(
                                  icon: Icons.lock_outline,
                                  label: 'تأكيد كلمة المرور',
                                  controller: confirmPasswordController,
                                  isPassword: true,
                                  color: Colors.white,
                                  labelColor: Colors.white70,
                                  iconColor: Colors.white70,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "برجاء تأكيد كلمة المرور";
                                    }
                                    if (value != passwordController.text) {
                                      return 'كلمتا المرور غير متطابقتين';
                                    }
                                    return null;
                                  },
                                ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                CustomButton(
                                  text: "إعادة تعيين كلمة المرور",
                                  onPressed: () async {
                                    if (!formKey.currentState!.validate())
                                      return;

                                    QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', 
                                      context: context,
                                      type: QuickAlertType.loading,
                                      title: 'برجاء الانتظار',
                                      text: 'جارٍ إعادة تعيين كلمة المرور...',
                                      barrierDismissible: false,
                                    );

                                    try {
                                      await ApiService().resetPassword(
                                        email: email,
                                        otp: otp.toString(),
                                        newPassword: passwordController.text,
                                      );

                                      if (mounted) Navigator.pop(context);

                                      if (mounted) {
                                        QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', context: context, type: QuickAlertType.success, title: 'نجاح', text: 'تم إعادة تعيين كلمة المرور بنجاح.',);
                                        Navigator.pushNamedAndRemoveUntil(
                                          context,
                                          LoginScreen.id,
                                          (route) => false,
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        Navigator.pop(context);
                                          QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', 
                                            context: context,
                                            type: QuickAlertType.error,
                                            title: 'فشلت العملية',
                                            text: e.toString().replaceAll(
                                              'Exception: ',
                                              '',
                                            ),
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
