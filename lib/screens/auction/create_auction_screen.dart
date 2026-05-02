import 'package:flutter/material.dart';
import 'package:root2route/components/custom_text_form_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/features/auctions/cubit/auction_cubit.dart';
import 'package:root2route/features/auctions/cubit/auction_state.dart';

class CreateAuctionScreen extends StatefulWidget {
  static const String id = '/createAuctionScreen';

  const CreateAuctionScreen({super.key});

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_productId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && args.isNotEmpty) {
        _productId = args;
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
              primary: Color(0xFF2ECC71),
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
              primary: Color(0xFF2ECC71),
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
          content: Text('Please select both start and end dates.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please ensure a product is selected.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<AuctionCubit>().createAuction(
      title: _titleCtrl.text.trim(),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Create Auction',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocListener<AuctionCubit, AuctionState>(
        listener: (context, state) {
          if (state is AuctionLoading) {
            QuickAlert.show(
              context: context,
              type: QuickAlertType.loading,
              title: 'Loading',
              text: 'Creating your auction...',
              barrierDismissible: false,
            );
          } else if (state is AuctionError) {
            Navigator.pop(context); // Pop the loading alert
            QuickAlert.show(
              context: context,
              type: QuickAlertType.error,
              title: 'Oops...',
              text: state.message,
            );
          } else if (state is AuctionSuccess) {
            Navigator.pop(context); // Pop the loading alert
            QuickAlert.show(
              context: context,
              type: QuickAlertType.success,
              title: 'Success!',
              text: 'Auction created successfully!',
              barrierDismissible: false,
              onConfirmBtnTap: () {
                Navigator.pop(context); // Pop the QuickAlert
                Navigator.pop(context, true); // Pop the CreateAuctionScreen and return true to refresh
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
              _buildSectionHeader(Icons.inventory_2_outlined, 'Product'),
              const SizedBox(height: 12),

              CustomTextFormField(
                controller: _titleCtrl,
                icon: Icons.title,
                validator:
                    (val) => val == null || val.isEmpty ? 'Required' : null,
                fillColor: Colors.white,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                color: Colors.black,
                label: 'Auction Title',
              ),

              const SizedBox(height: 12),
              _buildSectionHeader(Icons.attach_money, 'Pricing'),
              const SizedBox(height: 12),
              CustomTextFormField(
                controller: _startPriceCtrl,
                label: 'Starting Price (EGP)',
                icon: Icons.money,
                validator: _priceValidator,
                fillColor: Colors.white,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                color: Colors.black,
              ),
              const SizedBox(height: 12),
              CustomTextFormField(
                controller: _minBidIncrCtrl,
                label: 'Minimum Bid Increment (EGP)',
                icon: Icons.trending_up,
                validator: _priceValidator,
                fillColor: Colors.white,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                color: Colors.black,
              ),
              const SizedBox(height: 12),
              CustomTextFormField(
                label: 'Reserve Price (EGP)',
                validator: _priceValidator,
                icon: Icons.security,
                fillColor: Colors.white,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                color: Colors.black,
                controller: _reservePriceCtrl,
              ),

              const SizedBox(height: 24),
              _buildSectionHeader(Icons.calendar_today, 'Schedule'),
              const SizedBox(height: 12),
              _buildDateTimePicker(
                label: 'Start Date & Time',
                selectedDate: _startDate,
                onTap: () => _pickDateTime(isStart: true),
              ),
              const SizedBox(height: 12),
              _buildDateTimePicker(
                label: 'End Date & Time',
                selectedDate: _endDate,
                onTap: () => _pickDateTime(isStart: false),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitAuction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Create Auction',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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
    );
  }

  String? _priceValidator(String? val) {
    if (val == null || val.trim().isEmpty) return 'Required';
    final parsed = double.tryParse(val.trim());
    if (parsed == null || parsed < 0) return 'Invalid amount';
    return null;
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F8EE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF2ECC71), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month, color: Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedDate != null
                        ? _formatDateTime(selectedDate)
                        : 'Select Date & Time',
                    style: TextStyle(
                      color:
                          selectedDate != null
                              ? Colors.black87
                              : Colors.grey.shade500,
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
}
