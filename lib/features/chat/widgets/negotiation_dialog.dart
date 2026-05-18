import 'package:flutter/material.dart';
import 'package:root2route/core/theme/app_colors.dart';

class NegotiationDialog extends StatefulWidget {
  final Function(double price, int quantity) onSend;

  const NegotiationDialog({Key? key, required this.onSend}) : super(key: key);

  @override
  State<NegotiationDialog> createState() => _NegotiationDialogState();
}

class _NegotiationDialogState extends State<NegotiationDialog> {
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
      widget.onSend(price, quantity);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.handshake_outlined, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Make an Offer'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _priceController,
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
              controller: _quantityController,
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: const Text('Send Offer', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
