import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/core/theme/app_colors.dart';

void showNegotiationDialog(BuildContext context, Function(double price, int quantity) onSend) {
  final priceController = TextEditingController();
  final quantityController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  QuickAlert.show(
    context: context,
    type: QuickAlertType.custom,
    title: 'Make an Offer',
    widget: Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          TextFormField(
            controller: priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Proposed Price (\$)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Required';
              if (double.tryParse(value.trim()) == null) return 'Invalid number';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantity',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.production_quantity_limits),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Required';
              if (int.tryParse(value.trim()) == null) return 'Invalid number';
              return null;
            },
          ),
        ],
      ),
    ),
    confirmBtnText: 'Send Offer',
    cancelBtnText: 'Cancel',
    showCancelBtn: true,
    confirmBtnColor: AppColors.primary,
    onConfirmBtnTap: () {
      if (formKey.currentState!.validate()) {
        final price = double.tryParse(priceController.text.trim()) ?? 0.0;
        final quantity = int.tryParse(quantityController.text.trim()) ?? 0;
        onSend(price, quantity);
        Navigator.pop(context);
      }
    },
  );
}
