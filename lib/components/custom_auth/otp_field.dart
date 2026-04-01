import 'package:flutter/material.dart';

class OtpField extends StatefulWidget {
  final Function(String) onChanged;

  const OtpField({super.key, required this.onChanged});

  @override
  State<OtpField> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpField> {
  // تثبيت الطول على 6
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
      // نستخدم المتغير المحلي length
      children: List.generate(length, (index) => _buildOtpBox(index)),
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      // عرض أصغر ليناسب الـ 6 خانات بجانب بعضها
      width: 45,
      child: TextField(
        controller: controllers[index],
        focusNode: focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          counterText: "",
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 2),
          ),
        ),
        onChanged: (value) {
          // منطق التنقل التلقائي
          if (value.isNotEmpty && index < length - 1) {
            focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            focusNodes[index - 1].requestFocus();
          }
          // إرجاع القيمة للشاشة الأم
          widget.onChanged(fullOtp);
        },
      ),
    );
  }
}
