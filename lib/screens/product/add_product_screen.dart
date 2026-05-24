import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:root2route/components/custom_text_form_field.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/services/api.dart';

class AddProductScreen extends StatefulWidget {
  final String organizationId;

  const AddProductScreen({super.key, required this.organizationId});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _directPriceController = TextEditingController();
  final _descriptionController = TextEditingController();
   final _auctionPriceController = TextEditingController();
  final _barcodeController = TextEditingController();

  String? _selectedCategory;
  String? _selectedUnit;
  DateTime? _expiryDate;
  bool _directSale = true;
  bool _forAuction = false;
  bool _isLoading = false;

  List<XFile> _pickedImages = [];
  final ImagePicker _picker = ImagePicker();

  final Map<String, int> _categoryMap = {
    'RawCrop': 0,
    'Processed': 1,
    'Tool': 2,
    'Chemical': 3,
  };
  final List<String> _units = ['Kg', 'pkg', 'Liter'];

  final _api = ApiService();

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _directPriceController.dispose();
    _descriptionController.dispose();
     _auctionPriceController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
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

    // Show loading before starting
    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: 'Publishing...',
      text: 'Creating your product, please wait.',
      barrierDismissible: false,
    );

    try {
      final result = await _api.addProduct(
        organizationId: widget.organizationId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        stockQuantity: int.tryParse(_quantityController.text.trim()) ?? 0,
        weightUnit: _selectedUnit != null ? _units.indexOf(_selectedUnit!) : 0,
        productType: _categoryMap[_selectedCategory] ?? 0,
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
         expiryDate: _expiryDate?.toIso8601String(),
         barcode: _barcodeController.text.trim(),
        images: _pickedImages,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading alert

      if (result['success'] == true) {
         await QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          title: 'Success',
          text: 'Product published successfully',
          confirmBtnText: 'Okay',
          confirmBtnColor: AppColors.primary,
          onConfirmBtnTap: () {
            Navigator.pop(context); // Close alert
            Navigator.pop(
              context,
              true,
            ); // Return to previous screen with data refresh
          },
        );
      } else {
        // In case of failure (actual error)
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Failure',
          text: result['message'] ?? 'Failed to publish product',
          confirmBtnText: 'Try Again',
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Unexpected Error',
        text: 'Something went wrong, please try again later.',
      );
    }
  }

  void _showErrorAlert(String message) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: 'Failure',
      text: message.length > 100 ? '${message.substring(0, 100)}...' : message,
      confirmBtnText: 'Try Again',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Add Product',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20.sp,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black87),
            onPressed: () => _showInfoGuide(context),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            children: [
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageArea(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('Product Name'),
                const SizedBox(height: 8),
                CustomTextFormField(
                  color: Colors.black,
                  icon: Icons.grass_outlined,
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                  label: 'e.g. Fresh Tomatoes',
                  controller: _nameController,
                ),
                const SizedBox(height: 18),
                _Label('Category'),
                const SizedBox(height: 8),
                _Dropdown(
                  hint: 'Select a category',
                  value: _selectedCategory,
                  items: _categoryMap.keys.toList(),
                  icon: Icons.category_outlined,
                  onChanged: (v) => setState(() => _selectedCategory = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 18),
                _Label('Quantity & Unit'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _quantityController,
                        hint: 'Stock',
                        icon: Icons.scale_outlined,
                        keyboardType: TextInputType.number,
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Dropdown(
                        hint: 'Unit',
                        value: _selectedUnit,
                        items: _units,
                        icon: Icons.straighten_outlined,
                        onChanged: (v) => setState(() => _selectedUnit = v),
                        validator: (v) => v == null ? 'Required' : null,
                      ),
                    ),
                  ],
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
          ),
        ],
      ),
    );
  }

  // --- Modified image functions ---
  bool _isPickerActive = false;

  Future<void> _pickImages() async {
    if (_isPickerActive) return;

    try {
      _isPickerActive = true;
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty && mounted) {
        setState(() => _pickedImages.addAll(images));
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    } finally {
      _isPickerActive = false;
    }
  }

  void _removeImage(int index) {
    setState(() => _pickedImages.removeAt(index));
  }

  Widget _buildImageArea() {
    if (_pickedImages.isEmpty) {
      return GestureDetector(
        onTap: _pickImages,
        child: Container(
          width: double.infinity,
          height: 170,
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.35),
              width: 1.8,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 40,
                color: AppColors.primary,
              ),
              const SizedBox(height: 10),
              const Text(
                'Add Product Photos',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 120,
      margin: const EdgeInsets.all(20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _pickedImages.length + 1,
        itemBuilder: (context, index) {
          if (index == _pickedImages.length) {
            return _buildAddMoreButton();
          }
          return _buildImageItem(index);
        },
      ),
    );
  }

  Widget _buildAddMoreButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: const Icon(Icons.add_rounded, color: AppColors.primary),
      ),
    );
  }

  Widget _buildImageItem(int index) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(_pickedImages[index].path),
              width: 100,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Selling Options and Buttons functions ---

  Widget _buildSellingOptionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20),
        ],
      ),
      child: Column(
        children: [
          _buildOptionToggle(
            icon: Icons.sell_outlined,
            title: 'Direct Sale',
            subtitle: 'Fixed price',
            value: _directSale,
            onChanged: (v) => setState(() => _directSale = v),
          ),
          if (_directSale) ...[
            const SizedBox(height: 12),
            _buildField(
              controller: _directPriceController,
              hint: 'Price (EGP)',
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
            ),
          ],
          const Divider(height: 32),
          _buildOptionToggle(
            icon: Icons.gavel_rounded,
            title: 'Auction',
            subtitle: 'Bidding system',
            value: _forAuction,
            onChanged: (v) => setState(() => _forAuction = v),
          ),
          if (_forAuction) ...[
            const SizedBox(height: 12),
            _buildField(
              controller: _auctionPriceController,
              hint: 'Start Bid (EGP)',
              icon: Icons.price_change,
              keyboardType: TextInputType.number,
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
              'Sell Product',
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

  // Helper components (Helpers)
  Widget _Label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 16.sp,
        color: Colors.black87,
      ),
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
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8F9FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _Dropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8F9FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _DatePickerWidget() {
    return InkWell(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, size: 20, color: Colors.grey),
            const SizedBox(width: 12),
            Text(
              _expiryDate == null
                  ? 'Select Date'
                  : _expiryDate!.toLocal().toString().split(' ')[0],
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
        Icon(icon, color: value ? AppColors.primary : Colors.grey),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                subtitle,
                style: TextStyle(fontSize: 14.sp, color: Colors.grey),
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

  void _showInfoGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 24.0,
            bottom: MediaQuery.of(context).padding.bottom + 24.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to list your product?',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              _buildGuideRow(
                '🏷️',
                'Direct Sale',
                'Sell your product at a fixed price. Buyers can purchase immediately or negotiate with you via chat.',
              ),
              const SizedBox(height: 16),
              _buildGuideRow(
                '⚖️',
                'Auction',
                'Start a bidding system. Set a starting price and let buyers compete. Highest bidder wins.',
              ),
              const SizedBox(height: 16),
              _buildGuideRow(
                '📅',
                'Expiry Date',
                'Optional but highly recommended for fresh crops and perishables to ensure buyer trust.',
              ),
              const SizedBox(height: 16),
              _buildGuideRow(
                '🔤',
                'Barcode / Description',
                'Add details or a barcode to make your product easily scannable and searchable.',
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Got it!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuideRow(String emoji, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: TextStyle(fontSize: 26.sp)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
