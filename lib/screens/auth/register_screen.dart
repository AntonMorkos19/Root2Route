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
import 'package:root2route/models/user_model.dart';
import 'package:root2route/screens/auth/login_screen.dart';
import 'package:root2route/screens/auth/otp_verification_screen.dart';
import 'package:root2route/services/api.dart';
import 'package:root2route/core/utils/snackbar_helper.dart';

class RegisterScreen extends StatefulWidget {
  static const String id = '/registerScreen';
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: AuthBackground(
        child: SafeArea(
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
                        title: 'إنشاء حساب جديد',
                        description: 'أدخل بياناتك لإنشاء حساب جديد',
                        icon: Icons.person_add_alt_1,
                      ),
                      const SizedBox(height: 5),
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
                                  const SizedBox(height: 5),
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(.15),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap: () {
                                              Navigator.pushReplacementNamed(
                                                context,
                                                LoginScreen.id,
                                              );
                                            },
                                            child: Container(
                                              height: 38,
                                              alignment: Alignment.center,
                                              child: const Text(
                                                "تسجيل الدخول",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Container(
                                            height: 38,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              "حساب جديد",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
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
                                        fillColor: Colors.white.withOpacity(
                                          0.15,
                                        ),
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
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.white54,
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
                                    child: Column(
                                      children: [
                                        CustomTextFormField(
                                          icon: Icons.person_outline,
                                          label: 'الاسم الكامل',
                                          controller: nameController,
                                          color: Colors.white,
                                          labelColor: Colors.white70,
                                          iconColor: Colors.white70,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'برجاء إدخال الاسم';
                                            }
                                            if (!RegExp(
                                              r'^[a-zA-Z\u0600-\u06FF\s]+$',
                                            ).hasMatch(value)) {
                                              return 'الاسم يجب أن يحتوي على حروف فقط';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        CustomTextFormField(
                                          icon: Icons.phone_outlined,
                                          label: 'رقم الهاتف',
                                          controller: phoneController,
                                          color: Colors.white,
                                          labelColor: Colors.white70,
                                          iconColor: Colors.white70,
                                          keyboardType: TextInputType.phone,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'برجاء إدخال رقم الهاتف';
                                            }
                                            if (!RegExp(
                                              r'^[0-9]{7,15}$',
                                            ).hasMatch(value)) {
                                              return 'أدخل رقم هاتف صحيح';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        CustomTextFormField(
                                          icon: Icons.location_on_outlined,
                                          label: 'العنوان',
                                          controller: addressController,
                                          color: Colors.white,
                                          labelColor: Colors.white70,
                                          iconColor: Colors.white70,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'برجاء إدخال عنوانك';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        CustomTextFormField(
                                          icon: Icons.email_outlined,
                                          label: 'البريد الإلكتروني',
                                          controller: emailController,
                                          color: Colors.white,
                                          labelColor: Colors.white70,
                                          iconColor: Colors.white70,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
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
                                        const SizedBox(height: 12),
                                        CustomTextFormField(
                                          icon: Icons.lock_outline,
                                          label: 'كلمة المرور',
                                          controller: passwordController,
                                          color: Colors.white,
                                          labelColor: Colors.white70,
                                          iconColor: Colors.white70,
                                          isPassword: true,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
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
                                        const SizedBox(height: 12),
                                        CustomTextFormField(
                                          icon: Icons.lock_outline,
                                          label: 'تأكيد كلمة المرور',
                                          controller: confirmPasswordController,
                                          color: Colors.white,
                                          labelColor: Colors.white70,
                                          iconColor: Colors.white70,
                                          isPassword: true,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return "برجاء تأكيد كلمة المرور";
                                            }
                                            if (passwordController.text !=
                                                confirmPasswordController
                                                    .text) {
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
                                    text: 'إنشاء الحساب',
                                    onPressed: () async {
                                      if (formKey.currentState!.validate()) {
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder:
                                              (context) => const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                        );

                                        try {
                                          await ApiService().registerUser(
                                            UserModel(
                                              fullName: nameController.text,
                                              address: addressController.text,
                                              email: emailController.text,
                                              password: passwordController.text,
                                              confirmPassword:
                                                  confirmPasswordController
                                                      .text,
                                              phoneNumber: phoneController.text,
                                            ),
                                          );

                                          if (context.mounted) {
                                            Navigator.pop(context);
                                          }

                                          QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', context: context, type: QuickAlertType.success, title: 'نجاح', text: 'تم إنشاء الحساب بنجاح! برجاء تفعيل بريدك الإلكتروني للمتابعة.',);

                                          Future.delayed(
                                            const Duration(seconds: 2),
                                            () {
                                              if (context.mounted) {
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
                                                                  .emailVerification,
                                                        ),
                                                  ),
                                                );
                                              }
                                            },
                                          );
                                        } catch (e) {
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                          }

                                          QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', 
                                            context: context,
                                            type: QuickAlertType.error,
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
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'لديك حساب بالفعل؟',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(.85),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pushReplacementNamed(
                                            context,
                                            LoginScreen.id,
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('تسجيل الدخول'),
                                      ),
                                    ],
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
      ),
    );
  }
}
