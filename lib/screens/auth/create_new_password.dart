import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:root2route/components/custom_auth/auth_background.dart';
import 'package:root2route/components/custom_auth/auth_header.dart';
import 'package:root2route/components/custom_button.dart';
import 'package:root2route/components/custom_text_form_field.dart';
import 'package:root2route/core/responsive/app_sizes.dart';
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AuthHeader(
                    title: 'Create New Password',
                    description:
                        'Your new password must be different from previously used passwords.',
                    icon: Icons.password_rounded,
                  ),
                  const SizedBox(height: 16),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 11, sigmaY: 11),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16), // زي login
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
                              CustomTextFormField(
                                icon: Icons.lock_outline,
                                label: 'New Password',
                                controller: passwordController,
                                isPassword: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Please enter your password";
                                  }
                                  if (value.length < 6) {
                                    return 'The password must be at least 6 characters long';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 15), // زي login spacing

                              CustomTextFormField(
                                icon: Icons.lock_outline,
                                label: 'Confirm Password',
                                controller: confirmPasswordController,
                                isPassword: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Please confirm your password";
                                  }
                                  if (value != passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              CustomButton(
                                text: "Reset Password",
                                onPressed: () async {
                                  if (!formKey.currentState!.validate()) return;

                                  // 1. إظهار رسالة تحميل
                                  QuickAlert.show(
                                    context: context,
                                    type: QuickAlertType.loading,
                                    title: 'Please Wait',
                                    text: 'Resetting your password...',
                                    barrierDismissible: false,
                                  );

                                  try {
                                    // 2. ننتظر رد السيرفر (لازم نضيف await)
                                    await ApiService().resetPassword(
                                      email: email,
                                      otp: otp.toString(),
                                      newPassword: passwordController.text,
                                    );

                                    // 3. نقفل رسالة التحميل
                                    if (mounted) Navigator.pop(context);

                                    // 4. نظهر رسالة النجاح، ولما يدوس عليها ننقله للـ Login
                                    if (mounted) {
                                      QuickAlert.show(
                                        context: context,
                                        type: QuickAlertType.success,
                                        title: 'Success!',
                                        text:
                                            'Your password has been reset successfully.',
                                        confirmBtnText: 'Login Now',
                                        barrierDismissible: false,
                                        onConfirmBtnTap: () {
                                          Navigator.pop(
                                            context,
                                          ); // نقفل الرسالة دي
                                          Navigator.pushNamedAndRemoveUntil(
                                            context,
                                            LoginScreen.id,
                                            (route) => false,
                                          );
                                        },
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      Navigator.pop(context);
                                      QuickAlert.show(
                                        context: context,
                                        type: QuickAlertType.error,
                                        title: 'Failed',
                                        text: e.toString().replaceAll(
                                          'Exception: ',
                                          '',
                                        ),
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
    );
  }
}
