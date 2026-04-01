import 'dart:async'; // ضروري جداً للـ Timer
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:root2route/components/custom_auth/auth_background.dart';
import 'package:root2route/components/custom_auth/auth_header.dart';
import 'package:root2route/components/custom_auth/otp_field.dart';
import 'package:root2route/components/custom_button.dart';
import 'package:root2route/core/responsive/app_sizes.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/screens/guest/guest_home_screen.dart';
import 'package:root2route/screens/guest/products_screen.dart';
import 'package:root2route/services/api.dart';

class ConfigurationScreen extends StatefulWidget {
  static const String id = 'configuration-screen';
  final String email;

  const ConfigurationScreen({super.key, required this.email});

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  static const Color green = Color(0xFF2ECC71);

  int secondsLeft = 30;
  Timer? _timer; // تعريف التايمر
  String otpCode = "";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer(); // يبدأ العد التنازلي أول ما الصفحة تفتح
  }

  // دالة تشغيل التايمر
  void _startTimer() {
    secondsLeft = 30; // إعادة ضبط الوقت
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft > 0) {
        setState(() => secondsLeft--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // تنظيف الذاكرة عند إغلاق الصفحة
    super.dispose();
  }

  void _verifyOtp() async {
    // تعديل الشرط ليكون 6 أرقام
    if (otpCode.length < 6) {
      _showError("Please enter the full 6-digit code");
      return;
    }

    setState(() => isLoading = true);

    try {
      await ApiService().verifyOTP(email: widget.email, otpCode: otpCode);

      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          text: "Email Verified Successfully!",
          onConfirmBtnTap: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              GuestHomeScreen.id,
              (route) => false,
            );
          },
        );
      }
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      text: message,
    );
  }

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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AuthHeader(
                    title: 'Verification Code',
                    description:
                        'Enter the 6-digit code sent to \n ${widget.email}',
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
                            isLoading
                                ? const CircularProgressIndicator(color: green)
                                : CustomButton(
                                  text: 'Verify',
                                  onPressed: _verifyOtp,
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
                                const SizedBox(width: 4),
                                if (secondsLeft == 0)
                                  TextButton(
                                    onPressed: () {
                                      ApiService().resendOTP(
                                        email: widget.email,
                                      );
                                      setState(() => _startTimer());
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primary,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
