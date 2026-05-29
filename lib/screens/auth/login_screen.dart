import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:root2route/components/custom_auth/auth_background.dart';
import 'package:root2route/components/custom_auth/auth_header.dart';
import 'package:root2route/components/custom_button.dart';
import 'package:root2route/components/custom_text_form_field.dart';
import 'package:root2route/core/responsive/app_sizes.dart';
import 'package:root2route/screens/auth/forgot_password_screen.dart';
import 'package:root2route/screens/auth/otp_verification_screen.dart';
import 'package:root2route/screens/auth/register_screen.dart';
import 'package:root2route/screens/guest/guest_home_screen.dart';
import 'package:root2route/screens/farmer/farmer_home_screen.dart';
import 'package:root2route/services/api.dart';
import 'package:root2route/services/storage_service.dart';

class LoginScreen extends StatefulWidget {
  static const String id = '/loginScreen';

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  ApiService api = ApiService();

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
                        title: "أهلاً بك في Root2Route",
                        description: "سجّل دخولك للمتابعة",
                        icon: Icons.eco,
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
                              ),
                            ),
                            child: Form(
                              key: formKey,
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(.16),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      children: [
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
                                              "تسجيل الدخول",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(width: 8),

                                        Expanded(
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            onTap: () {
                                              Navigator.pushNamed(
                                                context,
                                                RegisterScreen.id,
                                              );
                                            },
                                            child: const SizedBox(
                                              height: 38,
                                              child: Center(
                                                child: Text(
                                                  "حساب جديد",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  CustomTextFormField(
                                    icon: Icons.email_outlined,
                                    label: "البريد الإلكتروني",
                                    controller: emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    color: Colors.white,
                                    labelColor: Colors.white70,
                                    iconColor: Colors.white70,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "برجاء إدخال البريد الإلكتروني";
                                      }
                                      if (!RegExp(
                                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                      ).hasMatch(value)) {
                                        return "بريد إلكتروني غير صحيح";
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 14),

                                  CustomTextFormField(
                                    icon: Icons.lock_outline,
                                    label: "كلمة المرور",
                                    controller: passwordController,
                                    isPassword: true,
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

                                  const SizedBox(height: 10),

                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.pushNamed(
                                          context,
                                          ForgotPasswordScreen.id,
                                        );
                                      },
                                      child: Text(
                                        "نسيت كلمة المرور؟",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  CustomButton(
                                    text: 'دخول',
                                    onPressed: () async {
                                      if (formKey.currentState!.validate()) {
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder:
                                              (context) => const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                    ),
                                              ),
                                        );

                                        try {
                                          await api.loginUser(
                                            emailController.text,
                                            passwordController.text,
                                          );

                                          if (context.mounted) {
                                            Navigator.pop(context);
                                          }

                                          final hasOrganization =
                                              StorageService().hasOrganization;

                                          if (context.mounted) {
                                            if (hasOrganization) {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) =>
                                                          const FarmerHomeScreen(),
                                                ),
                                              );
                                            } else {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) =>
                                                          const GuestHomeScreen(),
                                                ),
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                          }

                                          String errorMessage = e
                                              .toString()
                                              .replaceAll('Exception: ', '');

                                          if (errorMessage
                                                  .toLowerCase()
                                                  .contains("confirm") ||
                                              errorMessage
                                                  .toLowerCase()
                                                  .contains("verify")) {
                                            QuickAlert.show(
                                              context: context,
                                              type: QuickAlertType.warning,
                                              title: 'البريد غير مفعّل',
                                              text:
                                                  'برجاء تفعيل بريدك الإلكتروني للمتابعة.',
                                              confirmBtnText: 'فعّل الآن',
                                              onConfirmBtnTap: () async {
                                                Navigator.pop(context);

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
                                                  await api.resendOTP(
                                                    email: emailController.text,
                                                  );

                                                  if (context.mounted) {
                                                    Navigator.pop(context);
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
                                                } catch (resendError) {
                                                  if (context.mounted) {
                                                    Navigator.pop(context);
                                                    QuickAlert.show(
                                                      context: context,
                                                      type:
                                                          QuickAlertType.error,
                                                      text:
                                                          "فشل إرسال كود التحقق. برجاء المحاولة مرة أخرى.",
                                                    );
                                                  }
                                                }
                                              },
                                            );
                                          } else {
                                            QuickAlert.show(
                                              context: context,
                                              type: QuickAlertType.error,
                                              text: errorMessage,
                                              title: "فشل تسجيل الدخول",
                                            );
                                          }
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
      ),
    );
  }
}
