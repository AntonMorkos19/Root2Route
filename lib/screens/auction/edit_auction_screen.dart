import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/features/auctions/cubit/auction_cubit.dart';
import 'package:root2route/features/auctions/cubit/auction_state.dart';
import 'package:root2route/models/auction_model.dart';

 class EditAuctionScreen extends StatefulWidget {
  static const String id = '/editAuctionScreen';
  const EditAuctionScreen({super.key});

  @override
  State<EditAuctionScreen> createState() => _EditAuctionScreenState();
}

class _EditAuctionScreenState extends State<EditAuctionScreen> {
  final _formKey = GlobalKey<FormState>();

  late AuctionModel _auction;
  late TextEditingController _startingPriceCtrl;
  late TextEditingController _minBidIncrCtrl;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _auction =
          ModalRoute.of(context)!.settings.arguments as AuctionModel;
      _startingPriceCtrl = TextEditingController(
          text: _auction.startingPrice.toStringAsFixed(2));
      _minBidIncrCtrl = TextEditingController(
          text: _auction.minimumBidIncrement.toStringAsFixed(2));
      _startDate = _auction.startDate;
      _endDate = _auction.endDate;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _startingPriceCtrl.dispose();
    _minBidIncrCtrl.dispose();
    super.dispose();
  }

  bool get _canEdit => _auction.status == 'upcoming';

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final firstDate = isStart ? now : (_startDate ?? now);
    final date = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? firstDate.add(const Duration(hours: 1)))
          : (_endDate ?? firstDate.add(const Duration(hours: 2))),
      firstDate: firstDate,
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
          isStart ? (_startDate ?? now) : (_endDate ?? now)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    final picked =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  String _fmt(DateTime dt) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '${m[dt.month - 1]} ${dt.day}, ${dt.year}  $h:${dt.minute.toString().padLeft(2, '0')} $ap';
  }

  void _submit() {
    if (!_canEdit || !_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select both start and end dates'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    context.read<AuctionCubit>().updateAuction(
          auctionId: _auction.id,
          startingPrice: double.parse(_startingPriceCtrl.text.trim()),
          minimumBidIncrement: double.parse(_minBidIncrCtrl.text.trim()),
          startDate: _startDate!,
          endDate: _endDate!,
        );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const SizedBox();

    return BlocConsumer<AuctionCubit, AuctionState>(
      listener: (context, state) {
        if (state is AuctionSuccess<AuctionModel>) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Auction updated successfully!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
          Navigator.pop(context, true);
        } else if (state is AuctionError) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        } else if (state is AuctionLoading) {
          setState(() => _isSubmitting = true);
        }
      },
      builder: (context, state) {
        return Stack(
          children: [
            Scaffold(
              backgroundColor: const Color(0xFFF4F6F9),
              appBar: AppBar(
                title: const Text('Edit Auction',
                    style: TextStyle(
                        color: Colors.black87, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.black87),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_canEdit) _buildDisabledBanner(),
                      _buildProductInfo(),
                      const SizedBox(height: 24),
                      _sectionHeader(Icons.attach_money_rounded, 'Pricing'),
                      const SizedBox(height: 8),
                      _textField(
                        controller: _startingPriceCtrl,
                        label: 'Starting Price (EGP)',
                        icon: Icons.price_check_rounded,
                        enabled: _canEdit,
                        keyboard: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: _priceValidator,
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: _minBidIncrCtrl,
                        label: 'Minimum Bid Increment (EGP)',
                        icon: Icons.trending_up_rounded,
                        enabled: _canEdit,
                        helper: 'Minimum allowed raise per bid',
                        keyboard: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: _priceValidator,
                      ),
                      const SizedBox(height: 24),
                      _sectionHeader(Icons.schedule_rounded, 'Schedule'),
                      const SizedBox(height: 8),
                      _dateSelector('Start Date & Time', _startDate,
                          _canEdit ? () => _pickDateTime(isStart: true) : null),
                      const SizedBox(height: 12),
                      _dateSelector('End Date & Time', _endDate,
                          _canEdit ? () => _pickDateTime(isStart: false) : null),
                      const SizedBox(height: 32),
                      _canEdit
                          ? SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                  textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                child: const Text('Update Auction'),
                              ),
                            )
                          : Tooltip(
                              message:
                                  'Cannot edit an auction that has already started',
                              child: SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey.shade300,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                  child: const Text('Cannot Edit',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            if (_isSubmitting)
              Container(
                color: Colors.black.withOpacity(0.35),
                child: const Center(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16))),
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: 16),
                          Text('Updating auction...',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ── Sub-widgets ────────────────────────────────────────

  String? _priceValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final val = double.tryParse(v.trim());
    if (val == null || val <= 0) return 'Enter a valid amount';
    return null;
  }

  Widget _buildDisabledBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(children: [
        Icon(Icons.info_outline_rounded,
            color: Colors.orange.shade700, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'This auction is ${_auction.status}. Editing is only available for upcoming auctions.',
            style: TextStyle(
                fontSize: 13,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w500),
          ),
        ),
      ]),
    );
  }

  Widget _buildProductInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.inventory_2_rounded,
              color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _auction.productName ?? 'Product',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
        ),
      ]),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87)),
    ]);
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboard,
    String? helper,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: validator,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        helperStyle: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
            fontStyle: FontStyle.italic),
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _dateSelector(String label, DateTime? value, VoidCallback? onTap) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded,
              size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(
                    value != null ? _fmt(value) : 'Tap to select',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            value != null ? Colors.black87 : Colors.grey.shade400),
                  ),
                ]),
          ),
          if (enabled)
            Icon(Icons.arrow_drop_down_rounded, color: Colors.grey.shade400),
        ]),
      ),
    );
  }
}
