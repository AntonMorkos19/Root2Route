import 'package:quickalert/quickalert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:root2route/components/custom_text_form_field.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/core/services/api.dart';
import 'package:root2route/core/utils/snackbar_helper.dart';

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
        title: 'طريقة البيع مطلوبة',
        text: 'يرجى تفعيل طريقة بيع واحدة على الأقل\n(بيع مباشر أو مزاد).',
        confirmBtnText: 'موافق',
        barrierDismissible: false,
      );
      return;
    }

    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: 'جاري التحديث...',
      text: 'جاري حفظ تحديثات المنتج على الخادم.',
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

      // هنا إحنا بنقفل الـ Loading Alert
      navigator.pop();

      if (!mounted) return;

      final successValue = result['success'];
      final isSuccess =
          successValue == true ||
          successValue.toString().toLowerCase() == 'true';

      if (isSuccess) {
        // التعديل هنا: أضفنا await عشان الكود يستنى المستخدم يدوس موافق
        await QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          title: 'نجاح',
          text: 'تم تحديث المنتج بنجاح.',
          confirmBtnText: 'موافق',
        );

        if (!mounted) return;

        // دلوقتي الـ pop ده هيقفل الشاشة بتاعت التعديل بشكل سليم
        Navigator.pop(context, true);
      } else {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'فشل التحديث',
          text: result['message'] ?? 'حدث خطأ أثناء التحديث.',
          confirmBtnText: 'موافق',
          barrierDismissible: false,
        );
      }
    } catch (e) {
      try {
        navigator.pop(); // قفل الـ Loading لو حصل Exception
      } catch (_) {}

      if (!mounted) return;

      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'خطأ غير متوقع',
        text: e.toString(),
        confirmBtnText: 'موافق',
        barrierDismissible: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'تعديل المنتج',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
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
                          "تحديث الصور غير مدعوم حالياً في هذا الإجراء.",
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextFormField(
            icon: Icons.grass_outlined,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
            label: 'اسم المنتج',
            controller: _nameController,
          ),
          const SizedBox(height: 18),

          _buildField(
            controller: _quantityController,
            hint: 'الكمية (المخزون)',
            icon: Icons.scale_outlined,
            keyboardType: TextInputType.number,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
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
    );
  }

  Widget _buildSellingOptionsCard() {
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'خيارات البيع',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color:
                  Theme.of(context).textTheme.titleSmall?.color ??
                  Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          _buildOptionToggle(
            icon: Icons.sell_outlined,
            title: 'بيع مباشر',
            subtitle: 'حدد سعراً ثابتاً للمشترين',
            value: _directSale,
            onChanged: (v) => setState(() => _directSale = v),
          ),
          if (_directSale) ...[
            const SizedBox(height: 12),
            _buildField(
              controller: _directPriceController,
              hint: 'سعر البيع المباشر (جنيه)',
              icon: Icons.attach_money_rounded,
              textDirection: TextDirection.ltr,
              keyboardType: TextInputType.number,
              validator:
                  (v) =>
                      (_directSale && (v == null || v.trim().isEmpty))
                          ? 'مطلوب'
                          : null,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          _buildOptionToggle(
            icon: Icons.gavel_rounded,
            title: 'مزاد',
            subtitle: 'دع المشترين يزايدون على منتجك',
            value: _forAuction,
            onChanged: (v) => setState(() => _forAuction = v),
          ),
          if (_forAuction) ...[
            const SizedBox(height: 12),
            _buildField(
              controller: _auctionPriceController,
              hint: 'سعر بدء المزاد (جنيه)',
              icon: Icons.price_change_outlined,
              textDirection: TextDirection.ltr,
              keyboardType: TextInputType.number,
              validator:
                  (v) =>
                      (_forAuction && (v == null || v.trim().isEmpty))
                          ? 'مطلوب'
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
              'تحديث المنتج',
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

  Widget _Label(String text) => Text(
    text,
    style: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 16.sp,
      color: Theme.of(context).textTheme.titleSmall?.color ?? Colors.white70,
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
      textAlign:
          textDirection == TextDirection.ltr ? TextAlign.left : TextAlign.start,
      style: TextStyle(
        color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87,
        fontSize: 16.sp,
      ),
      decoration: InputDecoration(labelText: hint, suffixIcon: Icon(icon)),
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
          suffixIcon:
              _expiryDate != null
                  ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _expiryDate = null),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.calendar_month_outlined),
                      const SizedBox(width: 8),
                    ],
                  )
                  : const Icon(Icons.calendar_month_outlined),
        ),
        child:
            _expiryDate == null
                ? const Text('')
                : Text(
                  label,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color:
                        Theme.of(context).textTheme.bodyMedium?.color ??
                        Colors.black87,
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
                  color:
                      Theme.of(context).textTheme.titleSmall?.color ??
                      Colors.white70,
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
