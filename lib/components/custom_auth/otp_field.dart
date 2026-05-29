import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OtpField extends StatefulWidget {
  final Function(String) onChanged;

  const OtpField({super.key, required this.onChanged});

  @override
  State<OtpField> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpField> {
   final int length = 6;
  late List<TextEditingController> controllers;
  late List<FocusNode> focusNodes;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(length, (index) => TextEditingController());
    focusNodes = List.generate(length, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (var c in controllers) c.dispose();
    for (var f in focusNodes) f.dispose();
    super.dispose();
  }

  String get fullOtp => controllers.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      // Use local length variable
      children: List.generate(length, (index) => _buildOtpBox(index)),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 44.w,
      height: 48.w,
      child: TextField(
        controller: controllers[index],
        focusNode: focusNodes[index],
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        keyboardType: TextInputType.visiblePassword, // Allows both letters and digits easily
        maxLength: 1,
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: Colors.white.withOpacity(0.12),
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 2),
          ),
        ),
        onChanged: (value) {
          // Auto-navigation logic
          if (value.isNotEmpty && index < length - 1) {
            focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            focusNodes[index - 1].requestFocus();
          }
          // Return value to parent screen
          widget.onChanged(fullOtp);
        },
      ),
    );
  }
}
