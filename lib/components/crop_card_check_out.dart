import 'package:flutter/material.dart';

class CropCardCheckOut extends StatelessWidget {
  final String nameCrod;
  final double quantity;
  final double price;
  final String url;

  const CropCardCheckOut({
    super.key,
    required this.nameCrod,
    required this.quantity,
    required this.price,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(url, width: 70, height: 70, fit: BoxFit.cover),
        ),

        const SizedBox(width: 20),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// NAME
              Text(
                nameCrod,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 6),

              /// QUANTITY
              Text(
                "$quantity kg",
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),

              const SizedBox(height: 6),

              /// PRICE
              Text(
                "$price \$",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
