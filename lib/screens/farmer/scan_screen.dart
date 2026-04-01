import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/components/custom_farmer/selection_card.dart';
import 'package:root2route/core/packages/Image_picker_helper.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/services/api.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isLoading = false;

  // دالة معالجة الصورة ورفعها
  Future<void> _processImage(ImageSource source) async {
    final file = await ImagePickerHelper.pickImage(source);

    if (file != null) {
      setState(() => _isLoading = true);

      try {
        // نداء الـ API الخاص بتحليل الصورة
        final result = await ApiService().analyzeCropImage(File(file.path));

        setState(() => _isLoading = false);

        if (result != null) {
          // المنطق الجديد للتعامل مع رد السيرفر
          if (result['succeeded'] == true) {
            // حالة النجاح في التشخيص
            QuickAlert.show(
              context: context,
              type: QuickAlertType.success,
              title: 'تم التحليل',
              text: "النتيجة: ${result['message']}",
              confirmBtnText: 'ممتاز',
              confirmBtnColor: AppColors.primary,
            );
          } else {
            // حالة فشل التشخيص (مثل: لم يتم اكتشاف ورقة نبات)
            QuickAlert.show(
              context: context,
              type: QuickAlertType.warning,
              title: 'تنبيه',
              text: result['message'] ?? "يرجى تصوير الورقة بشكل أوضح",
              confirmBtnText: 'حاول مرة أخرى',
              confirmBtnColor: Colors.orange,
            );
          }
        } else {
          _showError("تعذر الاتصال بالسيرفر، يرجى المحاولة لاحقاً");
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showError("حدث خطأ ما، تأكد من اتصالك بالإنترنت");
      }
    }
  }

  void _showError(String message) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: 'عذراً...',
      text: message,
      confirmBtnText: 'حسناً',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 70,
        title: const Text(
          "Scan Crop",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Take a photo of the affected plant to identify the disease.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: SelectionCard(
                          title: "Camera",
                          icon: Icons.camera_alt_rounded,
                          onTap: () => _processImage(ImageSource.camera),
                          gradientColors: const [
                            Color(0xFF66BB6A),
                            Color(0xFF388E3C),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: SelectionCard(
                          title: "Gallery",
                          icon: Icons.photo_library_rounded,
                          onTap: () => _processImage(ImageSource.gallery),
                          gradientColors: const [
                            Color(0xFFFFA726),
                            Color(0xFFF57C00),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 35),
                  _buildTipContainer(),
                ],
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 20),
                    Text(
                      "AI is Analyzing...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTipContainer() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb_outline, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child:
           
            Text(
              "Focus on the affected part of the plant for 98% more accurate results.",
              style: TextStyle(
                fontSize: 13,
                color: Color.fromARGB(255, 137, 136, 136),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
