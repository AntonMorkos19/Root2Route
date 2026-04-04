import 'dart:ui';
import 'package:flutter/material.dart';
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
import 'package:root2route/screens/Organizations/ProfileScreen.dart';
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AuthHeader(
                      title: "Welcome to Root2Route",
                      description: "Access your account to continue.",
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Text(
                                            "Login",
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
                                                "New account",
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
                                  label: "Email Address",
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please enter your email";
                                    }

                                    if (!RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                    ).hasMatch(value)) {
                                      return "Invalid Email";
                                    }

                                    return null;
                                  },
                                ),

                                const SizedBox(height: 14),

                                CustomTextFormField(
                                  icon: Icons.lock_outline,
                                  label: "Password",
                                  controller: passwordController,
                                  isPassword: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Enter your password";
                                    }

                                    if (value.length < 6) {
                                      return "Password must be at least 6 characters";
                                    }

                                    return null;
                                  },
                                ),

                                const SizedBox(height: 10),

                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        ForgotPasswordScreen.id,
                                      );
                                    },
                                    child: const Text(
                                      "Forgot password?",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 6),

                                CustomButton(
                                  text: 'Login',
                                  onPressed: () async {
                                    if (formKey.currentState!.validate()) {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder:
                                            (context) => const Center(
                                              child: CircularProgressIndicator(
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
                                        print(
                                          " After login - hasOrganization: $hasOrganization",
                                        );

                                        if (context.mounted) {
                                          if (hasOrganization) {
                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) =>
                                                        const ProfileScreen(),
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
                                          Navigator.pop(
                                            context,
                                          );  
                                        }

                                        String errorMessage = e
                                            .toString()
                                            .replaceAll('Exception: ', '');

                                        if (errorMessage.toLowerCase().contains(
                                              "confirm",
                                            ) ||
                                            errorMessage.toLowerCase().contains(
                                              "verify",
                                            )) {
                                          QuickAlert.show(
                                            context: context,
                                            type: QuickAlertType.warning,
                                            title: 'Email Not Verified',
                                            text:
                                                'Please verify your email to continue.',
                                            confirmBtnText: 'Verify Now',
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
                                                    type: QuickAlertType.error,
                                                    text:
                                                        "Failed to send verification code. Please try again.",
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
                                            title: "Failed ",
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
