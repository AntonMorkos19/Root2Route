import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:root2route/components/custom_text_form_field.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/services/api.dart';
import 'package:root2route/core/utils/snackbar_helper.dart';

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
    'محصول': 0,
    'مصنع': 1,
    'أداة': 2,
    'كيماويات': 3,
  };
  final List<String> _units = ['كجم', 'لتر', 'عبوة'];

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
        title: 'طريقة البيع مطلوبة',
        text:
            'يرجى تفعيل طريقة بيع واحدة على الأقل\n(بيع مباشر أو مزاد).',
        barrierDismissible: false,
      );
      return;
    }

    // Show loading before starting
    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: 'جاري النشر...',
      text: 'جاري إنشاء منتجك، يرجى الانتظار.',
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
      Navigator.pop(context);
      if (result['success'] == true) {
        CustomSnackBar.showSuccess(context, 'تم نشر المنتج بنجاح');
        Navigator.pop(context, true); // Return to previous screen
      } else {
        // In case of failure (actual error)
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'فشل',
          text: result['message'] ?? 'فشل نشر المنتج',
          confirmBtnText: 'حاول مرة أخرى',
          barrierDismissible: false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'خطأ غير متوقع',
        text: 'حدث خطأ ما، يرجى المحاولة مرة أخرى لاحقاً.',
        barrierDismissible: false,
      );
    }
  }

  void _showErrorAlert(String message) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: 'فشل',
      text: message.length > 100 ? '${message.substring(0, 100)}...' : message,
      confirmBtnText: 'حاول مرة أخرى',
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'إضافة منتج',
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
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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

                CustomTextFormField(
                  icon: Icons.grass_outlined,
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  label: ' اسم المنتج',
                  controller: _nameController,
                ),
                const SizedBox(height: 18),

                _Dropdown(
                  hint: 'اختر فئة',
                  value: _selectedCategory,
                  items: _categoryMap.keys.toList(),
                  icon: Icons.category_outlined,
                  onChanged: (v) => setState(() => _selectedCategory = v),
                  validator: (v) => v == null ? 'مطلوب' : null,
                ),
                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _quantityController,
                        hint: 'الكمية (المخزون)',
                        icon: Icons.scale_outlined,
                        keyboardType: TextInputType.number,
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'مطلوب'
                                    : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Dropdown(
                        hint: 'الوحدة',
                        value: _selectedUnit,
                        items: _units,
                        icon: Icons.straighten_outlined,
                        onChanged: (v) => setState(() => _selectedUnit = v),
                        validator: (v) => v == null ? 'مطلوب' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _DatePickerWidget(),
                const SizedBox(height: 18),

                CustomTextFormField(
                  icon: Icons.qr_code_scanner,
                  label: 'الباركود (مثال: 1234567890)',
                  controller: _barcodeController,
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 18),

                CustomTextFormField(
                  icon: Icons.description_outlined,
                  label: 'صف منتجك...',
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
                'إضافة صور المنتج',
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20),
        ],
      ),
      child: Column(
        children: [
          _buildOptionToggle(
            icon: Icons.sell_outlined,
            title: 'بيع مباشر',
            subtitle: 'سعر ثابت',
            value: _directSale,
            onChanged: (v) => setState(() => _directSale = v),
          ),
          if (_directSale) ...[
            const SizedBox(height: 12),
            _buildField(
              controller: _directPriceController,
              hint: 'سعر القطعة الواحدة بالجنيه',
              icon: Icons.attach_money,
              textDirection: TextDirection.ltr,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
          const Divider(height: 32),
          _buildOptionToggle(
            icon: Icons.gavel_rounded,
            title: 'مزاد',
            subtitle: 'نظام المزايدة',
            value: _forAuction,
            onChanged: (v) => setState(() => _forAuction = v),
          ),
          if (_forAuction) ...[
            const SizedBox(height: 12),
            _buildField(
              controller: _auctionPriceController,
              hint: 'بدء المزاد (جنيه)',
              icon: Icons.price_change,
              textDirection: TextDirection.ltr,
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Text(
            'إلغاء',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.update_rounded, size: 20),
            label: Text(
              'بيع المنتج',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
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
    TextDirection? textDirection,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textDirection: textDirection,
      validator: validator,
      textAlign: textDirection == TextDirection.ltr ? TextAlign.left : TextAlign.start,
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87,
        fontSize: 16.sp,
      ),
      decoration: InputDecoration(
        labelText: hint,
        suffixIcon: Icon(icon),
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
      dropdownColor:
          Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : Colors.white,
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87,
        fontSize: 16.sp,
      ),
      initialValue: value,
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: hint,
        suffixIcon: Icon(icon),
      ),
    );
  }

  Widget _DatePickerWidget() {
    final label =
        _expiryDate == null
            ? ''
            : '${_expiryDate!.day.toString().padLeft(2, '0')} / ${_expiryDate!.month.toString().padLeft(2, '0')} / ${_expiryDate!.year}';

    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        isEmpty: _expiryDate == null,
        decoration: InputDecoration(
          labelText: 'تاريخ الصلاحية (اختياري)',
          hintText: 'اختر تاريخ الصلاحية',
          suffixIcon: _expiryDate != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _expiryDate = null),
                      child: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade400),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.calendar_month_outlined),
                    const SizedBox(width: 8),
                  ],
                )
              : const Icon(Icons.calendar_month_outlined),
        ),
        child: _expiryDate == null
            ? const Text('')
            : Text(
                label,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87,
                ),
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
                'كيف تعرض منتجك؟',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              _buildGuideRow(
                '🏷️',
                'بيع مباشر',
                'بع منتجك بسعر ثابت. يمكن للمشترين الشراء فوراً أو التفاوض معك عبر الدردشة.',
              ),
              const SizedBox(height: 16),
              _buildGuideRow(
                '⚖️',
                'مزاد',
                'ابدأ نظام مزايدة. حدد السعر المبدئي ودع المشترين يتنافسون. أعلى مزايد يفوز.',
              ),
              const SizedBox(height: 16),
              _buildGuideRow(
                '📅',
                'تاريخ الصلاحية',
                'اختياري ولكنه يوصى به بشدة للمحاصيل الطازجة والقابلة للتلف لضمان ثقة المشتري.',
              ),
              const SizedBox(height: 16),
              _buildGuideRow(
                '🔤',
                'الباركود / الوصف',
                'أضف تفاصيل أو باركود لجعل منتجك سهل المسح والبحث عنه.',
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'فهمت!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
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
                style: TextStyle(fontSize: 16.sp, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
