import 'package:flutter/material.dart';
import 'package:root2route/components/custom_text_form_field.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/features/shipments/cubit/dispatch_cubit.dart';

/// Shows a modal bottom sheet that collects dispatch details and calls
/// [DispatchCubit.dispatchShipment].
///
/// Pass the already-provided [dispatchCubit] from the parent's
/// `context.read<DispatchCubit>()` so the BlocListener on the parent screen
/// keeps receiving state updates.
void showDispatchBottomSheet({
  required BuildContext context,
  required String orderId,
  required DispatchCubit dispatchCubit,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DispatchBottomSheet(
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
      notes: _phoneCtrl.text.trim().isNotEmpty
          ? 'Carrier: ${_carrierCtrl.text.trim()} | Phone: ${_phoneCtrl.text.trim()}'
          : _carrierCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
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
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.local_shipping_outlined,
                  color: Colors.green.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إرسال الشحنة 📦',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'أدخل تفاصيل الشحن',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
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
                  label: 'اسم شركة الشحن',
                  color: Colors.black87,
                  borderColor: AppColors.primary,
                  cursorColor: AppColors.primary,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                ),
                const SizedBox(height: 16),

                // Tracking number
                CustomTextFormField(
                  controller: _trackingCtrl,
                  icon: Icons.qr_code_scanner_outlined,
                  label: 'رقم التتبع (اختياري)',
                  color: Colors.black87,
                  borderColor: AppColors.primary,
                  cursorColor: AppColors.primary,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),

                // Contact phone
                CustomTextFormField(
                  controller: _phoneCtrl,
                  icon: Icons.phone_outlined,
                  label: 'رقم هاتف المندوب (اختياري)',
                  color: Colors.black87,
                  borderColor: AppColors.primary,
                  cursorColor: AppColors.primary,
                  keyboardType: TextInputType.phone,
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
              icon: const Text('📦', style: TextStyle(fontSize: 18)),
              label: const Text(
                'تأكيد الإرسال',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
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
                'إلغاء',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
