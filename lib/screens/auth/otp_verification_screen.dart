import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/components/custom_auth/auth_background.dart';
import 'package:root2route/components/custom_auth/auth_header.dart';
import 'package:root2route/components/custom_auth/otp_field.dart';
import 'package:root2route/components/custom_button.dart';
import 'package:root2route/core/responsive/app_sizes.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/screens/auth/create_new_password.dart';
import 'package:root2route/screens/guest/guest_home_screen.dart';
import 'package:root2route/services/api.dart';

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
      _showError("Please enter the full 6-digit code");
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
      await ApiService().verifyOTP(email: widget.email, otpCode: otpCode);

      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          title: "Success",
          text: "Email Verified Successfully!",
          confirmBtnColor: green,
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

  void _resendOtp() async {
    try {
      await ApiService().resendOTP(email: widget.email);
      _startTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Code resent successfully"),
            backgroundColor: green,
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError("Failed to resend code. Try again.");
    }
  }

  void _showError(String message) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: "Failed",
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
                        'Enter the 6-digit code sent to \n${widget.email}',
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
                                    onPressed: _resendOtp,
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
