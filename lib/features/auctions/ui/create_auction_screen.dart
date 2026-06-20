import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:root2route/components/custom_text_form_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/features/auctions/cubit/auction_cubit.dart';
import 'package:root2route/features/auctions/cubit/auction_state.dart';
import 'package:root2route/core/services/api.dart';
import 'package:root2route/core/services/storage_service.dart';
import 'package:root2route/core/utils/price_formatter.dart';

class CreateAuctionScreen extends StatefulWidget {
  static const String id = '/createAuctionScreen';
  final dynamic preSelectedProduct;

  const CreateAuctionScreen({super.key, this.preSelectedProduct});

  @override
  State<CreateAuctionScreen> createState() => _CreateAuctionScreenState();
}

class _CreateAuctionScreenState extends State<CreateAuctionScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _productId;
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _startPriceCtrl = TextEditingController();
  final TextEditingController _minBidIncrCtrl = TextEditingController();
  final TextEditingController _reservePriceCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  List<dynamic> _eligibleProducts = [];
  bool _isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    _fetchEligibleProducts();
  }

  Future<void> _fetchEligibleProducts() async {
    final orgId = StorageService().currentUserOrgId;
    if (orgId == null || orgId.isEmpty) {
      if (mounted) setState(() => _isLoadingProducts = false);
      return;
    }
    try {
      final res = await ApiService().getOrganizationProducts(orgId);
      if (mounted && res['success'] == true) {
        final data = res['data'] as List<dynamic>;
        setState(() {
          _eligibleProducts =
              data.where((p) {
                final isAvailableForAuction =
                    p['isAvailableForAuction'] == true ||
                    p['IsAvailableForAuction'] == true;
                return isAvailableForAuction;
              }).toList();

          // Auto-fill title and price if we have a productId
          if (_productId != null) {
            try {
              final selectedProduct = _eligibleProducts.firstWhere(
                (p) => (p['id'] ?? p['Id']).toString() == _productId,
              );
              _titleCtrl.text =
                  selectedProduct['name'] ?? selectedProduct['Name'] ?? '';

              final rawPrice =
                  selectedProduct['directSalePrice'] ??
                  selectedProduct['DirectSalePrice'] ??
                  0;
              final price = double.tryParse(rawPrice.toString()) ?? 0.0;
              if (price > 0 && _startPriceCtrl.text.isEmpty) {
                _startPriceCtrl.text = PriceFormatter.format(price);
              }
            } catch (_) {}
          }

          _isLoadingProducts = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingProducts = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_productId == null) {
      if (widget.preSelectedProduct != null) {
        _productId =
            (widget.preSelectedProduct['id'] ?? widget.preSelectedProduct['Id'])
                ?.toString();
        _titleCtrl.text =
            widget.preSelectedProduct['name'] ??
            widget.preSelectedProduct['Name'] ??
            '';
      } else {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is String && args.isNotEmpty) {
          _productId = args;
        } else if (args is Map) {
          _productId = (args['id'] ?? args['Id'])?.toString();
          _titleCtrl.text = (args['name'] ?? args['Name'] ?? '').toString();
        }
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _startPriceCtrl.dispose();
    _minBidIncrCtrl.dispose();
    _reservePriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final initialDate =
        isStart
            ? (_startDate ?? now)
            : (_endDate ??
                (_startDate != null
                    ? _startDate!.add(const Duration(hours: 1))
                    : now));

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
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

    if (date == null) return;

    if (!mounted) return;

    final initialTime = TimeOfDay.fromDateTime(initialDate);
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
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

    if (time == null) return;

    final pickedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isStart) {
        _startDate = pickedDateTime;
        if (_endDate != null && _endDate!.isBefore(pickedDateTime)) {
          _endDate = null; // Reset end date if it's before new start date
        }
      } else {
        _endDate = pickedDateTime;
      }
    });
  }

  void _submitAuction() {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تحديد تاريخي البدء والانتهاء.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب أن يكون تاريخ الانتهاء بعد تاريخ البدء.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى التأكد من اختيار منتج.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final isValidProduct = _eligibleProducts.any(
      (p) => (p['id'] ?? p['Id']).toString() == _productId,
    );
    if (!isValidProduct) {
      QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', 
        context: context,
        type: QuickAlertType.error,
        title: 'منتج غير صالح',
        text: 'المنتج المحدد غير متاح للمزاد.',
      );
      return;
    }

    context.read<AuctionCubit>().createAuction(
      title:
          _titleCtrl.text.trim().isEmpty ? 'مزاد' : _titleCtrl.text.trim(),
      productId: _productId!,
      startingPrice: double.tryParse(_startPriceCtrl.text.trim()) ?? 0.0,
      minimumBidIncrement: double.tryParse(_minBidIncrCtrl.text.trim()) ?? 0.0,
      reservePrice: double.tryParse(_reservePriceCtrl.text.trim()) ?? 0.0,
      startDate: _startDate!,
      endDate: _endDate!,
    );
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
          title: Text(
            'إنشاء مزاد',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.help_outline,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () => _showInfoGuide(context),
          ),
        ],
      ),
      body: BlocListener<AuctionCubit, AuctionState>(
        listener: (context, state) {
          if (state is AuctionLoading) {
            QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', 
              context: context,
              type: QuickAlertType.loading,
              title: 'جاري التحميل',
              text: 'جاري إنشاء المزاد...',
              barrierDismissible: false,
            );
          } else if (state is AuctionError) {
            Navigator.pop(context); // Pop the loading alert
            QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', 
              context: context,
              type: QuickAlertType.error,
              title: 'عفواً...',
              text: state.message,
            );
          } else if (state is AuctionSuccess) {
            Navigator.pop(context); // Pop the loading alert
            QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', 
              context: context,
              type: QuickAlertType.success,
              title: 'نجاح!',
              text: 'تم إنشاء المزاد بنجاح!',
              barrierDismissible: false,
              onConfirmBtnTap: () {
                Navigator.pop(context); // Pop the QuickAlert
                Navigator.pop(
                  context,
                  true,
                ); // Pop the CreateAuctionScreen and return true to refresh
              },
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionHeader(Icons.title_rounded, 'عنوان المزاد'),
                const SizedBox(height: 12),
                CustomTextFormField(
                  controller: _titleCtrl,
                  label: 'العنوان',
                  icon: Icons.edit_note_rounded,
                  validator:
                      (val) =>
                          val == null || val.trim().isEmpty ? 'مطلوب' : null,
                  fillColor: Theme.of(context).colorScheme.surface,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),

                const SizedBox(height: 12),

                const SizedBox(height: 12),
                _buildSectionHeader(Icons.attach_money, 'التسعير'),
                const SizedBox(height: 12),
                CustomTextFormField(
                  controller: _startPriceCtrl,
                  label: 'السعر المبدئي (جنيه)',
                  icon: Icons.money,
                  validator: _priceValidator,
                  fillColor: Theme.of(context).colorScheme.surface,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                const SizedBox(height: 12),
                CustomTextFormField(
                  controller: _minBidIncrCtrl,
                  label: 'الحد الأدنى لزيادة المزايدة (جنيه)',
                  icon: Icons.trending_up,
                  validator: _priceValidator,
                  fillColor: Theme.of(context).colorScheme.surface,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                const SizedBox(height: 12),
                CustomTextFormField(
                  label: 'السعر الاحتياطي (جنيه)',
                  validator: _priceValidator,
                  icon: Icons.security,
                  fillColor: Theme.of(context).colorScheme.surface,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  controller: _reservePriceCtrl,
                ),

                const SizedBox(height: 24),
                _buildSectionHeader(Icons.calendar_today, 'الجدول الزمني'),
                const SizedBox(height: 12),
                _buildDateTimePicker(
                  label: 'تاريخ ووقت البدء',
                  selectedDate: _startDate,
                  onTap: () => _pickDateTime(isStart: true),
                ),
                const SizedBox(height: 12),
                _buildDateTimePicker(
                  label: 'تاريخ ووقت الانتهاء',
                  selectedDate: _endDate,
                  onTap: () => _pickDateTime(isStart: false),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submitAuction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'إنشاء مزاد',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  String? _priceValidator(String? val) {
    if (val == null || val.trim().isEmpty) return 'مطلوب';
    final parsed = double.tryParse(val.trim());
    if (parsed == null || parsed < 0) return 'مبلغ غير صالح';
    return null;
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedDate != null
                        ? _formatDateTime(selectedDate)
                        : 'اختر التاريخ والوقت',
                    style: TextStyle(
                      color:
                          selectedDate != null
                              ? Theme.of(context).textTheme.bodyLarge?.color
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 16,
                      fontWeight:
                          selectedDate != null
                              ? FontWeight.w500
                              : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
                'شرح شروط المزاد',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 20),
              _buildGuideRow(
                '💰',
                'السعر المبدئي',
                'السعر الأولي الذي تبدأ به المزايدة.',
              ),
              const SizedBox(height: 16),
              _buildGuideRow(
                '📈',
                'الحد الأدنى لزيادة المزايدة',
                'أصغر مبلغ يمكن للمشتري إضافته إلى أعلى مزايدة حالية (مثلاً: إذا تم تعيينه إلى 10، يجب أن تكون المزايدة التالية أعلى بـ 10 جنيهات على الأقل).',
              ),
              const SizedBox(height: 16),
              _buildGuideRow(
                '🛡️',
                'السعر الاحتياطي',
                'حد أدنى مخفي للسعر أنت مستعد لقبوله. إذا لم يصل العرض النهائي في نهاية المزاد إلى هذا المبلغ، فلن يتم بيع المنتج. اتركه فارغاً إذا لم تكن بحاجة إليه.',
              ),
              const SizedBox(height: 16),
              _buildGuideRow(
                '🗓️',
                'الجدول الزمني',
                'حدد تواريخ وأوقات البدء والانتهاء بدقة. بمجرد الوصول إلى وقت الانتهاء، يفوز صاحب أعلى مزايدة تلقائياً.',
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
                    elevation: 0,
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
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
