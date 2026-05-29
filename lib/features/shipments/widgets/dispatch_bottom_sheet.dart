import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:root2route/components/custom_text_form_field.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/features/shipments/cubit/dispatch_cubit.dart';

/// Shows a modal bottom sheet that collects dispatch details and calls
/// [DispatchCubit.dispatchShipment].
///
/// Pass the already-provided [dispatchCubit] from the parent's
/// `context.read<DispatchCubit>()` so the BlocListener on the parent screen
/// keeps receiving state updates.
void showDispatchBottomSheet(
  BuildContext context, {
  required String orderId,
  required DispatchCubit dispatchCubit,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (_) => _DispatchBottomSheet(
          orderId: orderId,
          dispatchCubit: dispatchCubit,
        ),
  );
}

// ── Private sheet widget ────────────────────────────────────────────────────

class _DispatchBottomSheet extends StatefulWidget {
  final String orderId;
  final DispatchCubit dispatchCubit;

  const _DispatchBottomSheet({
    required this.orderId,
    required this.dispatchCubit,
  });

  @override
  State<_DispatchBottomSheet> createState() => _DispatchBottomSheetState();
}

class _DispatchBottomSheetState extends State<_DispatchBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  final _carrierCtrl = TextEditingController();
  final _trackingCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _carrierCtrl.dispose();
    _trackingCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(); // close the sheet before dispatching

    widget.dispatchCubit.dispatchShipment(
      orderId: widget.orderId,
      trackingNumber: _trackingCtrl.text.trim(),
      carrierName: _carrierCtrl.text.trim(),
      driverPhone: _phoneCtrl.text.trim(),
      notes: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle bar ──────────────────────────────────────
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Header ─────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_shipping_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dispatch Shipment 📦',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  ),
                  Text(
                    'Enter shipping details',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Form ────────────────────────────────────────────
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Carrier name
                CustomTextFormField(
                  controller: _carrierCtrl,
                  icon: Icons.directions_car_outlined,
                  label: 'Carrier Name',
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2A2A2A)
                      : Colors.transparent,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Carrier name is required' : null,
                ),
                const SizedBox(height: 20),

                // Tracking number
                CustomTextFormField(
                  controller: _trackingCtrl,
                  icon: Icons.qr_code_scanner_outlined,
                  label: 'Tracking Number (Optional)',
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2A2A2A)
                      : Colors.transparent,
                  keyboardType: TextInputType.text,
                  validator: (v) {
                    if (v != null && v.isNotEmpty && v.trim().isEmpty) {
                      return 'Tracking number cannot be only spaces';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Contact phone
                CustomTextFormField(
                  controller: _phoneCtrl,
                  icon: Icons.phone_outlined,
                  label: "Driver's Phone (Optional)",
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2A2A2A)
                      : Colors.transparent,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (!RegExp(r'^[0-9]{7,15}$').hasMatch(v.trim())) {
                      return 'Enter a valid phone number (7-15 digits)';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Submit button ────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submit,
              icon: Text('📦', style: TextStyle(fontSize: 20.sp)),
              label: Text(
                'Confirm Dispatch',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // ── Cancel button ────────────────────────────────────
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
