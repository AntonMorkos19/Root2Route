import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomSummaryCard extends StatelessWidget {
  

   final String title;
    final String amount;

  const CustomSummaryCard({
    super.key, required this.title, required this.amount,
    
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey, fontSize: 18.sp)),
          const SizedBox(height: 14),
          Text(
            amount,
            style: TextStyle(
                fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
                  const SizedBox(height: 10),

        ],
      ),
    );
  }
}

