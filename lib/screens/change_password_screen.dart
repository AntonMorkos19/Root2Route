import 'package:flutter/material.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/components/custom_auth/auth_header.dart';
import 'package:root2route/components/custom_button.dart';
import 'package:root2route/components/custom_text_form_field.dart';
import 'package:root2route/screens/farmer/farmer_home_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final oldPasswordController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AuthHeader(
                    title: 'ChangePassword ',
                    description:
                        'Update your password to keep your account secure',
                    icon: Icons.lock_reset,
                  ),

                  const SizedBox(height: 20),
                  CustomTextFormField(
                    icon: Icons.lock_outline,
                    label: 'Old Password',
                    controller: oldPasswordController,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your old password";
                      }
                      if (value.length < 6) {
                        return 'The password must be at least 6 characters long';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),
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

                  const SizedBox(height: 20),

                  CustomTextFormField(
                    icon: Icons.lock_outline,
                    label: 'Confirm Password',
                    controller: confirmPasswordController,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your password";
                      }

                      if (value.length < 6) {
                        return 'The password must be at least 6 characters long';
                      }
                      if (passwordController.value !=
                          confirmPasswordController.value) {
                        return 'Passwords do not match';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Save',
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;

                            QuickAlert.show(
                              context: context,
                              type: QuickAlertType.success,
                              text: "Saved successfully !",
                              showConfirmBtn: false,
                            );

                            Future.delayed(const Duration(seconds: 3), () {
                              if (!context.mounted) return;
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FarmerHomeScreen(),
                                ),
                              );
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: CustomButton(
                          text: 'Cancel',
                          color: AppColors.iconSecondary,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
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
