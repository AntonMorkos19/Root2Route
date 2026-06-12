import 'package:quickalert/quickalert.dart';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:root2route/components/custom_auth/auth_background.dart';
import 'package:root2route/components/custom_auth/auth_header.dart';
import 'package:root2route/components/custom_auth/otp_field.dart';
import 'package:root2route/components/custom_button.dart';
import 'package:root2route/core/responsive/app_sizes.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/screens/guest/guest_home_screen.dart';
import 'package:root2route/screens/auth/create_new_password.dart';
import 'package:root2route/screens/auth/login_screen.dart';
import 'package:root2route/services/api.dart';
import 'package:root2route/core/utils/snackbar_helper.dart';

enum OtpType { emailVerification, passwordRecovery }

class OtpVerificationScreen extends StatefulWidget {
  static const String id = '/otpVerificationScreen';

  final String email;
  final OtpType type;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.type,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const Color green = Color(0xFF2ECC71);

  int secondsLeft = 30;
  Timer? _timer;
  String otpCode = "";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() => secondsLeft = 30);
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
    _timer?.cancel();
    super.dispose();
  }

  void _verifyOtp() async {
    if (otpCode.length < 6) {
      _showError("برجاء إدخال الكود المكون من 6 أرقام كاملاً");
      return;
    }

    if (widget.type == OtpType.passwordRecovery) {
      print("Proceeding to create new password with code: $otpCode");
      Navigator.pushNamedAndRemoveUntil(
        context,
        CreateNewPassword.id,
        (route) => false,
        arguments: {"email": widget.email, "code": otpCode},
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final result = await ApiService().verifyOTP(
        email: widget.email,
        otpCode: otpCode,
      );

      if (mounted) {
        if (result['success'] == true) {
          final hasToken = result['hasToken'] ?? false;

          QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', context: context, type: QuickAlertType.success, title: 'نجاح', text: hasToken
                ? "تم تفعيل البريد الإلكتروني وتسجيل الدخول بنجاح!"
                : "تم تفعيل البريد الإلكتروني بنجاح! برجاء تسجيل الدخول.",);
          if (hasToken) {
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                GuestHomeScreen.id,
                (route) => false,
              );
            }
          } else {
            Navigator.pushNamedAndRemoveUntil(
              context,
              LoginScreen.id,
              (route) => false,
            );
          }
        } else {
          _showError(result['message'] ?? "فشلت عملية التحقق");
        }
      }
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _resendOtp() async {
    try {
      await ApiService().resendOTP(email: widget.email);
      _startTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم إعادة إرسال الكود بنجاح"),
            backgroundColor: green,
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError("فشل إرسال كود التحقق. برجاء المحاولة مرة أخرى.");
    }
  }

  void _showError(String message) {
    QuickAlert.show(cancelBtnText: 'إلغاء', 
      context: context,
      type: QuickAlertType.error,
      title: "فشلت العملية",
      text: message,
      barrierDismissible: false,
      confirmBtnText: "موافق",
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
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AuthHeader(
                      title: 'كود التحقق',
                      description:
                          'أدخل الكود المكون من 6 أرقام المرسل إلى \n${widget.email}',
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
                              OtpField(onChanged: (value) => otpCode = value),
                              const SizedBox(height: 26),

                              isLoading
                                  ? const CircularProgressIndicator(
                                    color: green,
                                  )
                                  : CustomButton(
                                    text: 'تحقق',
                                    onPressed: _verifyOtp,
                                  ),

                              const SizedBox(height: 16),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    secondsLeft > 0
                                        ? 'إعادة الإرسال خلال 00:${secondsLeft.toString().padLeft(2, '0')}'
                                        : 'لم تصلك الرسالة؟',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(width: 4),
                                  if (secondsLeft == 0)
                                    TextButton(
                                      onPressed: _resendOtp,
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                      ),
                                      child: const Text('إعادة إرسال'),
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
      ),
    );
  }
}
