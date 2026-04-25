import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/models/create_auction_request.dart';
import 'package:root2route/services/api.dart';

class CreateAuctionScreen extends StatefulWidget {
  final String productId;

  const CreateAuctionScreen({super.key, required this.productId});

  @override
  State<CreateAuctionScreen> createState() => _CreateAuctionScreenState();
}

class _CreateAuctionScreenState extends State<CreateAuctionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  final _titleController = TextEditingController();
  final _startPriceController = TextEditingController();
  final _minIncrementController = TextEditingController();
  final _reservePriceController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  // ─────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _startPriceController.dispose();
    _minIncrementController.dispose();
    _reservePriceController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  // Date + Time Picker (chained)
  // ─────────────────────────────────────────
  Future<DateTime?> _pickDateTime({
    required DateTime? initial,
    DateTime? firstDate,
    String label = 'date',
  }) async {
    final now = DateTime.now();
    final first = firstDate ?? now;
    final initDate = (initial != null && initial.isAfter(first))
        ? initial
        : first.add(const Duration(hours: 1));

    // 1. Pick date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initDate,
      firstDate: first,
      lastDate: DateTime(2035),
      helpText: 'SELECT $label DATE',
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );
    if (pickedDate == null || !mounted) return null;

    // 2. Pick time immediately after
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initDate),
      helpText: 'SELECT $label TIME',
      builder: (ctx, child) => _datePickerTheme(ctx, child),
    );
    if (pickedTime == null || !mounted) return null;

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  Widget _datePickerTheme(BuildContext ctx, Widget? child) {
    return Theme(
      data: Theme.of(ctx).copyWith(
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black87,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        ),
      ),
      child: child!,
    );
  }

  // ─────────────────────────────────────────
  // Submit
  // ─────────────────────────────────────────
  Future<void> _submit() async {
    // Validate form fields
    if (!_formKey.currentState!.validate()) return;

    // Validate dates selected
    if (_startDate == null || _endDate == null) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Dates Required',
        text: 'Please select both a Start Date and an End Date.',
      );
      return;
    }

    // Validate end > start
    if (!_endDate!.isAfter(_startDate!)) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Invalid Date Range',
        text: 'End Date & Time must be after Start Date & Time.',
      );
      return;
    }

    // Show loading
    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: 'Launching Auction...',
      text: 'Please wait while we set up your auction.',
      barrierDismissible: false,
    );

    final request = CreateAuctionRequest(
      title: _titleController.text.trim(),
      startDate: _startDate!,
      endDate: _endDate!,
      startPrice: double.parse(_startPriceController.text.trim()),
      minimumBidIncrement: double.parse(_minIncrementController.text.trim()),
      reservePrice: double.parse(_reservePriceController.text.trim()),
      productId: widget.productId,
    );

    try {
      final result = await _api.createAuction(request);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (result['success'] == true) {
        await QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          title: 'Auction Created!',
          text: 'Your auction has been successfully launched.',
          confirmBtnText: 'Great!',
          confirmBtnColor: AppColors.primary,
          onConfirmBtnTap: () {
            Navigator.pop(context); // Close success dialog
            Navigator.pop(context, true); // Return to MyProducts
          },
        );
      } else {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Failed',
          text: result['message'] ?? 'Could not create auction. Please try again.',
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

  // ─────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Create Auction',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
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
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: [
                _buildHeaderBanner(),
                const SizedBox(height: 20),
                _buildDetailsCard(),
                const SizedBox(height: 20),
                _buildDatesCard(),
                const SizedBox(height: 20),
                _buildPricingCard(),
                const SizedBox(height: 28),
                _buildSubmitButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Header Banner
  // ─────────────────────────────────────────
  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            const Color(0xFF27AE60),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start a Live Auction',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Set dates, pricing, and launch your auction.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Details Card (Title)
  // ─────────────────────────────────────────
  Widget _buildDetailsCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: Icons.title_rounded, label: 'Auction Details'),
          const SizedBox(height: 16),
          _Label('Auction Title'),
          const SizedBox(height: 8),
          _buildField(
            controller: _titleController,
            hint: 'e.g. Fresh Harvest Tomatoes Auction',
            icon: Icons.sell_outlined,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Title is required' : null,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Dates Card
  // ─────────────────────────────────────────
  Widget _buildDatesCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: Icons.calendar_month_rounded, label: 'Auction Schedule'),
          const SizedBox(height: 16),
          _DateCard(
            label: 'Start Date & Time',
            icon: Icons.play_circle_outline_rounded,
            color: const Color(0xFF3498DB),
            dateTime: _startDate,
            onTap: () async {
              final picked = await _pickDateTime(
                initial: _startDate,
                label: 'START',
              );
              if (picked != null) setState(() => _startDate = picked);
            },
          ),
          const SizedBox(height: 12),
          _DateCard(
            label: 'End Date & Time',
            icon: Icons.stop_circle_outlined,
            color: const Color(0xFFE74C3C),
            dateTime: _endDate,
            onTap: () async {
              final picked = await _pickDateTime(
                initial: _endDate,
                firstDate: _startDate ?? DateTime.now(),
                label: 'END',
              );
              if (picked != null) setState(() => _endDate = picked);
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Pricing Card
  // ─────────────────────────────────────────
  Widget _buildPricingCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: Icons.attach_money_rounded, label: 'Pricing'),
          const SizedBox(height: 16),
          _Label('Start Price (EGP)'),
          const SizedBox(height: 8),
          _buildField(
            controller: _startPriceController,
            hint: 'e.g. 500.00',
            icon: Icons.price_change_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _priceValidator('Start price'),
          ),
          const SizedBox(height: 16),
          _Label('Minimum Bid Increment (EGP)'),
          const SizedBox(height: 8),
          _buildField(
            controller: _minIncrementController,
            hint: 'e.g. 50.00',
            icon: Icons.trending_up_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _priceValidator('Minimum bid increment'),
          ),
          const SizedBox(height: 16),
          _Label('Reserve Price (EGP)'),
          const SizedBox(height: 8),
          _buildField(
            controller: _reservePriceController,
            hint: 'e.g. 800.00',
            icon: Icons.lock_outline_rounded,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _priceValidator('Reserve price'),
          ),
          const SizedBox(height: 10),
          _buildHintRow(
            'Reserve price is the minimum acceptable winning bid.',
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Submit Button
  // ─────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: _submit,
        icon: const Icon(Icons.gavel_rounded, size: 22),
        label: const Text(
          'Start Auction',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 6,
          shadowColor: AppColors.primary.withOpacity(0.5),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────
  String? Function(String?) _priceValidator(String fieldName) {
    return (v) {
      if (v == null || v.trim().isEmpty) return '$fieldName is required';
      final parsed = double.tryParse(v.trim());
      if (parsed == null) return 'Enter a valid number';
      if (parsed < 0) return '$fieldName cannot be negative';
      return null;
    };
  }

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
      style: const TextStyle(fontSize: 14.5, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
        filled: true,
        fillColor: const Color(0xFFF8F9FB),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildHintRow(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11.5, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _Label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            color: Colors.black87,
          ),
        ),
      );
}

// ─────────────────────────────────────────
// Reusable sub-widgets
// ─────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _DateCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final DateTime? dateTime;
  final VoidCallback onTap;

  const _DateCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.dateTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValue = dateTime != null;
    final String dateText = hasValue
        ? DateFormat('EEE, MMM d, yyyy').format(dateTime!)
        : 'Tap to select date';
    final String timeText = hasValue
        ? DateFormat('hh:mm a').format(dateTime!)
        : '';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasValue ? color.withOpacity(0.05) : const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasValue ? color.withOpacity(0.35) : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(hasValue ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dateText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: hasValue ? Colors.black87 : Colors.grey.shade400,
                    ),
                  ),
                  if (hasValue) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 13, color: color),
                        const SizedBox(width: 4),
                        Text(
                          timeText,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              hasValue
                  ? Icons.edit_calendar_rounded
                  : Icons.chevron_right_rounded,
              color: hasValue ? color : Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
