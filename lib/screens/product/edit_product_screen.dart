import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:root2route/components/custom_text_form_field.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/services/api.dart';

class EditProductScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _descriptionController;
  late TextEditingController _directPriceController;
  late TextEditingController _auctionPriceController;
  late TextEditingController _barcodeController;

  bool _directSale = false;
  bool _forAuction = false;
  DateTime? _expiryDate;

  // Added these variables here to read them correctly in initState
  int _weightUnit = 0;
  int _productType = 0;

  @override
  void initState() {
    super.initState();
    final p = widget.product;

    // Safe extraction of fields to deal with Backend casing issues
    final name = p['name'] ?? p['Name'] ?? '';
    final description = p['description'] ?? p['Description'] ?? '';
    final barcode = p['barcode'] ?? p['Barcode'] ?? '';

    final stockQty = p['stockQuantity'] ?? p['StockQuantity'] ?? 0;
    final directPrice = p['directSalePrice'] ?? p['DirectSalePrice'] ?? 0;
    final auctionPrice = p['startBiddingPrice'] ?? p['StartBiddingPrice'] ?? 0;

    _directSale =
        p['isAvailableForDirectSale'] ?? p['IsAvailableForDirectSale'] ?? false;
    _forAuction =
        p['isAvailableForAuction'] ?? p['IsAvailableForAuction'] ?? false;

    final expiryRaw = p['expiryDate'] ?? p['ExpiryDate'];
    if (expiryRaw != null && expiryRaw.toString().isNotEmpty) {
      _expiryDate = DateTime.tryParse(expiryRaw.toString());
    }

    // Safe Enum extraction
    _weightUnit =
        int.tryParse((p['weightUnit'] ?? p['WeightUnit'] ?? 0).toString()) ?? 0;
    _productType =
        int.tryParse((p['productType'] ?? p['ProductType'] ?? 0).toString()) ??
        0;

    _nameController = TextEditingController(text: name);
    _quantityController = TextEditingController(text: stockQty.toString());
    _descriptionController = TextEditingController(text: description);
    _directPriceController = TextEditingController(
      text: directPrice.toString(),
    );
    _auctionPriceController = TextEditingController(
      text: auctionPrice.toString(),
    );
    _barcodeController = TextEditingController(text: barcode.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _directPriceController.dispose();
    _auctionPriceController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_directSale && !_forAuction) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Selling Method Required',
        text:
            'Please enable at least one selling method\n(Direct Sale or Auction).',
      );
      return;
    }

    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: 'Updating...',
      text: 'Saving product updates on the server.',
      barrierDismissible: false,
    );

    final navigator = Navigator.of(context, rootNavigator: true);

    try {
      final p = widget.product;
      final id = (p['id'] ?? p['Id']).toString();

      final result = await _api.updateProduct(
        id: id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        stockQuantity: int.tryParse(_quantityController.text.trim()) ?? 0,
        isAvailableForDirectSale: _directSale,
        directSalePrice:
            _directSale
                ? (double.tryParse(_directPriceController.text.trim()) ?? 0.0)
                : 0.0,
        isAvailableForAuction: _forAuction,
        startBiddingPrice:
            _forAuction
                ? (double.tryParse(_auctionPriceController.text.trim()) ?? 0.0)
                : 0.0,
        expiryDate: _expiryDate?.toUtc().toIso8601String(),
        barcode: _barcodeController.text.trim(),
        weightUnit: _weightUnit,
        productType: _productType,
      );

       navigator.pop();

      if (!mounted) return;

       final successValue = result['success'];
      final isSuccess =
          successValue == true ||
          successValue.toString().toLowerCase() == 'true';

      if (isSuccess) {
        await QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          title: 'Updated!',
          text: 'Product successfully updated.',
          showConfirmBtn: false,
          autoCloseDuration: const Duration(seconds: 2),
        );
        if (!mounted) return;
        Navigator.pop(context, true); // Return to previous page successfully
      } else {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Update Failed',
          text: result['message'] ?? 'An error occurred while updating.',
        );
      }
    } catch (e) {
      try {
        navigator.pop();
      } catch (_) {}

      if (!mounted) return;
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Unexpected Error',
        text: e.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          'Edit Product',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20.sp),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade800),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Image updating is not currently supported for this action.",
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildFormCard(),
              const SizedBox(height: 20),
              _buildSellingOptionsCard(),
              const SizedBox(height: 28),
              _buildActionButtons(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label('Product Name'),
          const SizedBox(height: 8),
          CustomTextFormField(
            icon: Icons.grass_outlined,
            validator:
                (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            label: 'Product Name',
            color: Colors.black,
            controller: _nameController,
          ),
          const SizedBox(height: 18),

          _Label('Stock Quantity'),
          const SizedBox(height: 8),
          _buildField(
            controller: _quantityController,
            hint: 'Amount (Stock)',
            icon: Icons.scale_outlined,
            keyboardType: TextInputType.number,
            validator:
                (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 18),

          _Label('Expiry Date (Optional)'),
          const SizedBox(height: 8),
          _DatePickerWidget(),
          const SizedBox(height: 18),

          _Label('Barcode (Optional)'),
          const SizedBox(height: 8),
          CustomTextFormField(
            color: Colors.black,
            icon: Icons.qr_code_scanner,
            label: 'e.g. 123456789012',
            controller: _barcodeController,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 18),

          _Label('Description (Optional)'),
          const SizedBox(height: 8),
          CustomTextFormField(
            color: Colors.black,
            icon: Icons.description_outlined,
            label: 'Describe your product...',
            controller: _descriptionController,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildSellingOptionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selling Options',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildOptionToggle(
            icon: Icons.sell_outlined,
            title: 'Direct Sale',
            subtitle: 'Set a fixed price for buyers',
            value: _directSale,
            onChanged: (v) => setState(() => _directSale = v),
          ),
          if (_directSale) ...[
            const SizedBox(height: 12),
            _buildField(
              controller: _directPriceController,
              hint: 'Direct sale price (EGP)',
              icon: Icons.attach_money_rounded,
              keyboardType: TextInputType.number,
              validator:
                  (v) =>
                      (_directSale && (v == null || v.trim().isEmpty))
                          ? 'Required'
                          : null,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          _buildOptionToggle(
            icon: Icons.gavel_rounded,
            title: 'Auction',
            subtitle: 'Let buyers bid on your product',
            value: _forAuction,
            onChanged: (v) => setState(() => _forAuction = v),
          ),
          if (_forAuction) ...[
            const SizedBox(height: 12),
            _buildField(
              controller: _auctionPriceController,
              hint: 'Starting bid price (EGP)',
              icon: Icons.price_change_outlined,
              keyboardType: TextInputType.number,
              validator:
                  (v) =>
                      (_forAuction && (v == null || v.trim().isEmpty))
                          ? 'Required'
                          : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
              fontSize: 16.sp,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.update_rounded, size: 20),
            label: Text(
              'Update Product',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16.sp),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: AppColors.primary.withOpacity(0.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _Label(String text) => Text(
    text,
    style: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 16.sp,
      color: Colors.black87,
    ),
  );

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: Colors.black87, fontSize: 16.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15.sp),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade500),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _DatePickerWidget() {
    final label =
        _expiryDate == null
            ? 'Select expiry date'
            : '${_expiryDate!.day.toString().padLeft(2, '0')} / ${_expiryDate!.month.toString().padLeft(2, '0')} / ${_expiryDate!.year}';

    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 20,
              color: Colors.grey.shade500,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16.sp,
                color:
                    _expiryDate == null ? Colors.grey.shade400 : Colors.black87,
              ),
            ),
            const Spacer(),
            if (_expiryDate != null)
              GestureDetector(
                onTap: () => setState(() => _expiryDate = null),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:
                value
                    ? AppColors.primary.withOpacity(0.12)
                    : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 22,
            color: value ? AppColors.primary : Colors.grey.shade400,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16.sp,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        ),
      ],
    );
  }
}
