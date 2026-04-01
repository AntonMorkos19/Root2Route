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
import 'package:root2route/screens/auth/configuration_screen.dart';
import 'package:root2route/screens/auth/login_screen.dart';
import 'package:root2route/services/api.dart';

class RegisterScreen extends StatefulWidget {
  static const String id = '/registerScreen';
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Register Form
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AuthHeader(
                      title: 'Create Account',
                      description: 'Enter your details to create a new account',
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
                                              "Login",
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Text(
                                            "New Account",
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
                                CustomTextFormField(
                                  icon: Icons.person_outline,
                                  label: 'Full Name',
                                  controller: nameController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter the name';
                                    }
                                    if (!RegExp(
                                      r'^[a-zA-Z\u0600-\u06FF\s]+$',
                                    ).hasMatch(value)) {
                                      return 'The name must contain only letters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                CustomTextFormField(
                                  icon: Icons.phone_outlined,
                                  label: 'Phone Number',
                                  controller: phoneController,
                                  keyboardType: TextInputType.phone,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your phone';
                                    }
                                    if (!RegExp(
                                      r'^[0-9]{7,15}$',
                                    ).hasMatch(value)) {
                                      return 'Enter a valid phone number';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                CustomTextFormField(
                                  icon: Icons.location_on_outlined,
                                  label: 'Address',
                                  controller: addressController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
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
                                const SizedBox(height: 12),
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
                                const SizedBox(height: 12),
                                CustomTextFormField(
                                  icon: Icons.lock_outline,
                                  label: 'Confirm Password',
                                  controller: confirmPasswordController,
                                  isPassword: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please confirm your password";
                                    }
                                    if (passwordController.text !=
                                        confirmPasswordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                CustomButton(
                                  text: 'Register',
                                  onPressed: () async {
                                    if (formKey.currentState!.validate()) {
                                      // 1. إظهار الـ Loading
                                      showDialog(
                                        context: context,
                                        barrierDismissible:
                                            false, // يمنع المستخدم من إغلاق التحميل بالضغط خارج النافذة
                                        builder:
                                            (context) => const Center(
                                              child:
                                                  CircularProgressIndicator(), // شكل التحميل الدائري
                                            ),
                                      );

                                      try {
                                        // 2. طلب الـ API
                                        await api.registerUser(
                                          UserModel(
                                            fullName: nameController.text,
                                            address: addressController.text,
                                            email: emailController.text,
                                            password: passwordController.text,
                                            confirmPassword:
                                                confirmPasswordController.text,
                                            phoneNumber: phoneController.text,
                                          ),
                                        );

                                        // 3. إغلاق الـ Loading (مهم جداً!)
                                        if (context.mounted)
                                          Navigator.pop(context);

                                        // 4. إظهار رسالة النجاح
                                        QuickAlert.show(
                                          context: context,
                                          type: QuickAlertType.success,
                                          text:
                                              'Registration successful! Please log in to continue.',
                                          autoCloseDuration: const Duration(
                                            seconds: 3,
                                          ), // يغلق التنبيه تلقائياً
                                          showConfirmBtn: false,
                                        );

                                        // 5. الانتقال لصفحة اللوجن
                                        Future.delayed(
                                          const Duration(seconds: 3),
                                          () {
                                            if (context.mounted) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (context) =>
                                                          ConfigurationScreen(
                                                            email:
                                                                emailController
                                                                    .text,
                                                          ),
                                                ),
                                              );
                                            }
                                          },
                                        );
                                      } catch (e) {
                                        // إغلاق الـ Loading
                                        if (context.mounted)
                                          Navigator.pop(context);

                                        // إظهار رسالة الخطأ الحقيقية
                                        QuickAlert.show(
                                          context: context,
                                          type: QuickAlertType.error,
                                          text: e.toString().replaceAll(
                                            'Exception: ',
                                            '',
                                          ), // هنا سيظهر السبب الفعلي
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
                                      'Already have an account?',
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
                                      child: const Text(' Login'),
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
    );
  }
}
