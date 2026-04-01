import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:root2route/components/custom_auth/auth_background.dart';
import 'package:root2route/components/custom_auth/auth_header.dart';
import 'package:root2route/components/custom_auth/otp_field.dart';
import 'package:root2route/components/custom_button.dart';
import 'package:root2route/core/responsive/app_sizes.dart';
import 'package:root2route/screens/auth/create_new_password.dart';

class RecoveryScreen extends StatefulWidget {
  static const String id = '/VerificationScreen';
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  static const Color green = Color(0xFF2ECC71);
  dynamic otpCode;
  int secondsLeft = 30;
  String email = "";

  @override
  Widget build(BuildContext context) {
    email = ModalRoute.of(context)!.settings.arguments as String;
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
                  const AuthHeader(
                    title: 'Verification Code',
                    description: 'Enter the 4-digit code we sent to your email',
                    icon: Icons.verified_outlined,
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 10),
                            OtpField(
                              onChanged: (value) {
                                otpCode = value;
                              },
                            ),
                            const SizedBox(height: 26),

                            CustomButton(
                              text: 'Verify',
                              onPressed: () {
                                if (otpCode.length == 6) {
                                  print("Verifying with code: $otpCode");
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    CreateNewPassword.id,
                                    (route) => false,
                                    arguments: {
                                      "email": email,
                                      "code": otpCode,
                                    },
                                  );
                                } else {
                                  // إظهار رسالة تنبيه أن الكود غير مكتمل
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Please enter the full 4-digit code",
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),

                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  secondsLeft > 0
                                      ? 'Resend in 00:${secondsLeft.toString().padLeft(2, '0')}'
                                      : 'Didn’t receive the code?',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: secondsLeft > 0 ? null : () {},
                                  style: TextButton.styleFrom(
                                    foregroundColor: green,
                                    disabledForegroundColor: Colors.grey,
                                  ),
                                  child: const Text('Resend'),
                                ),
                              ],
                            ),
                          ],
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
