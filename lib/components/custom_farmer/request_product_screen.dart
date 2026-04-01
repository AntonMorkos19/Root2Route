import 'package:flutter/material.dart';
import 'package:root2route/components/custom_button.dart';
class RequestProductScreen extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String buttonText;
  final VoidCallback onPressed;

  const RequestProductScreen({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 40),
            ),

            const SizedBox(height: 18),

            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),

            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: buttonText,
                onPressed: onPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
