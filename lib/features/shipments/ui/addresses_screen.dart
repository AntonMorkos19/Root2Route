import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/components/custom_text_form_field.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/features/shipments/cubit/shipment_address_cubit.dart';
import 'package:root2route/features/shipments/cubit/shipment_state.dart';
import 'package:root2route/models/shipment_address_model.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  late final ShipmentAddressCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = ShipmentAddressCubit()..fetchAddresses();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ShipmentAddressCubit>.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: const Text(
            'My Addresses',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: BlocBuilder<ShipmentAddressCubit, ShipmentState>(
          bloc: _cubit,
          builder: (context, state) {
            // ── Loading ────────────────────────────────────────────────
            if (state is ShipmentInitial || state is ShipmentLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            // ── Error ──────────────────────────────────────────────────
            if (state is ShipmentError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18.sp),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _cubit.fetchAddresses(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // ── Loaded ─────────────────────────────────────────────────
            final List<ShipmentAddressModel> addresses =
                state is ShipmentAddressesLoaded ? state.addresses : const [];

            if (addresses.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () => _cubit.fetchAddresses(),
              color: AppColors.primary,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: addresses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _AddressCard(address: addresses[i]),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddAddressSheet(context),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_location_alt_outlined),
          label: Text(
            'Add New Address',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
          ),
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_off_outlined,
              size: 64,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No saved addresses found',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a new address to see it here',
            style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ── Bottom sheet ──────────────────────────────────────────────────────────

  void _showAddAddressSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddAddressSheet(cubit: _cubit),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Address Card
// ─────────────────────────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  final ShipmentAddressModel address;
  const _AddressCard({required this.address});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            address.isDefault
                ? Border.all(color: AppColors.primary, width: 1.5)
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: label + default badge ──────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  address.fullName.isNotEmpty ? address.fullName : 'Address',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Default',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ── Details ────────────────────────────────────────────────
          _detailRow(Icons.location_city_outlined, address.city),
          if (address.street.isNotEmpty) ...[
            const SizedBox(height: 6),
            _detailRow(Icons.map_outlined, address.street),
          ],
          if (address.buildingNumber.isNotEmpty) ...[
            const SizedBox(height: 6),
            _detailRow(
              Icons.apartment_outlined,
              'Building ${address.buildingNumber}',
            ),
          ],
          if (address.phone.isNotEmpty) ...[
            const SizedBox(height: 6),
            _detailRow(Icons.phone_outlined, address.phone),
          ],
          if (address.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            _detailRow(Icons.notes_outlined, address.notes),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Address Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddAddressSheet extends StatefulWidget {
  final ShipmentAddressCubit cubit;
  const _AddAddressSheet({required this.cubit});

  @override
  State<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<_AddAddressSheet> {
  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isDefault = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _cityCtrl.dispose();
    _streetCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final address = ShipmentAddressModel(
      fullName: _labelCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      street: _streetCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      isDefault: _isDefault,
    );

    widget.cubit.addAddress(address);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocConsumer<ShipmentAddressCubit, ShipmentState>(
      bloc: widget.cubit,
      listenWhen:
          (prev, curr) =>
              curr is ShipmentActionSuccess || curr is ShipmentError,
      listener: (context, state) {
        if (state is ShipmentActionSuccess) {
          Navigator.of(context).pop(); // close bottom sheet
          QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            title: 'Success',
            text: state.message,
          );
        } else if (state is ShipmentError) {
          setState(() => _isSubmitting = false);
          QuickAlert.show(
            context: context,
            type: QuickAlertType.error,
            title: 'Error',
            text: state.message,
          );
        }
      },
      builder: (context, state) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Handle bar ──────────────────────────────────────────
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

                // ── Header ──────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_location_alt_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Address 📍',
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'Enter address details',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Form ────────────────────────────────────────────────
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextFormField(
                        controller: _labelCtrl,
                        icon: Icons.label_outlined,
                        label: 'Label (e.g. Home, Work)',
                        color: Colors.black87,
                        borderColor: AppColors.primary,
                        cursorColor: AppColors.primary,
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextFormField(
                        controller: _cityCtrl,
                        icon: Icons.location_city_outlined,
                        label: 'City',
                        color: Colors.black87,
                        borderColor: AppColors.primary,
                        cursorColor: AppColors.primary,
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextFormField(
                        controller: _streetCtrl,
                        icon: Icons.map_outlined,
                        label: 'Street',
                        color: Colors.black87,
                        borderColor: AppColors.primary,
                        cursorColor: AppColors.primary,
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextFormField(
                        controller: _phoneCtrl,
                        icon: Icons.phone_outlined,
                        label: 'Phone Number',
                        color: Colors.black87,
                        borderColor: AppColors.primary,
                        cursorColor: AppColors.primary,
                        keyboardType: TextInputType.phone,
                        validator:
                            (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── isDefault switch ────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.star_outline,
                            size: 20,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Set as default address',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isDefault,
                        onChanged: (v) => setState(() => _isDefault = v),
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Submit button ───────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon:
                        _isSubmitting
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                            ),
                    label: Text(
                      _isSubmitting ? 'Saving...' : 'Save Address',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.primary.withOpacity(
                        0.6,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                // ── Cancel button ───────────────────────────────────────
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 18.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
