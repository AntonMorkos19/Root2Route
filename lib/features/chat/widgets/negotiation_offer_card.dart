import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:root2route/core/theme/app_colors.dart';

class NegotiationOfferCard extends StatelessWidget {
  final double? price;
  final int? quantity;
  final String offerStatus;
  final bool isMe;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const NegotiationOfferCard({
    Key? key,
    this.price,
    this.quantity,
    required this.offerStatus,
    this.isMe = false,
    required this.onAccept,
    required this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = offerStatus.toLowerCase();
    final isPending = status.isEmpty || status == 'pending';
    final isAccepted = status == 'accepted';
    final isRejected = status == 'rejected';

    Color bgColor = Colors.blue.shade50;
    Color iconColor = Colors.blue;
    if (isAccepted) {
      bgColor = Colors.green.shade50;
      iconColor = Colors.green;
    } else if (isRejected) {
      bgColor = Colors.red.shade50;
      iconColor = Colors.red;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.handshake_outlined, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(
                'عرض تفاوض',
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (price != null)
            Text(
              'السعر: ${price!.toStringAsFixed(2)} جنيه',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (quantity != null) ...[
            const SizedBox(height: 4),
            Text(
              'الكمية: $quantity',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (isPending)
            if (isMe)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'في انتظار الرد...',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'قبول',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'رفض',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: isAccepted ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  isAccepted ? 'تم قبول العرض' : 'تم رفض العرض',
                  style: TextStyle(
                    color: isAccepted ? AppColors.primary : Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
        ],
      ),
    ));
  }
}
