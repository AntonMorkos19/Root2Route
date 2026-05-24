import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/components/custom_text_form_field.dart';
import 'package:root2route/services/order_service.dart';
import 'package:root2route/services/storage_service.dart';
import 'package:root2route/services/cart_service.dart';
import 'package:root2route/screens/auth/login_screen.dart';
import 'package:root2route/features/shipments/ui/addresses_screen.dart';
import 'package:root2route/features/shipments/cubit/shipment_address_cubit.dart';
import 'package:root2route/features/shipments/cubit/shipment_state.dart';
import 'package:root2route/models/shipment_address_model.dart';
import 'package:root2route/screens/farmer/farmer_home_screen.dart';
import 'package:root2route/features/cart/cubit/cart_cubit.dart';

class CheckoutScreen extends StatefulWidget {
  static const String id = '/checkoutScreen';

  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _receiverNameController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  final _shippingCityController = TextEditingController();
  final _shippingStreetController = TextEditingController();
  final _buildingNumberController = TextEditingController();

  final OrderService _orderService = OrderService();
  final CartService _cartService = CartService();

  @override
  void dispose() {
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _shippingCityController.dispose();
    _shippingStreetController.dispose();
    _buildingNumberController.dispose();
    super.dispose();
  }

  void _showAddressSelectionSheet(
    Function(ShipmentAddressModel) onAddressSelected,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return BlocProvider(
          create: (context) => ShipmentAddressCubit()..fetchAddresses(),
          child: BlocBuilder<ShipmentAddressCubit, ShipmentState>(
            builder: (context, state) {
              if (state is ShipmentLoading) {
                return const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF2ECC71)),
                  ),
                );
              }

              if (state is ShipmentError) {
                return SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }

              final addresses =
                  state is ShipmentAddressesLoaded
                      ? state.addresses
                      : <ShipmentAddressModel>[];

              if (addresses.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'No Saved Addresses',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddressesScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ECC71),
                        ),
                        child: const Text(
                          'Add New Address',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'Select Delivery Address',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: addresses.length,
                        itemBuilder: (context, index) {
                          final address = addresses[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.location_on,
                              color: Color(0xFF2ECC71),
                            ),
                            title: Text(
                              address.fullName.isNotEmpty
                                  ? address.fullName
                                  : 'Address ${index + 1}',
                            ),
                            subtitle: Text(
                              '${address.city}, ${address.street}\nPhone: ${address.phone}',
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              onAddressSelected(address);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _submitOrder() async {
    if (_cartService.items.isEmpty) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Empty Cart',
        text: 'Your cart is empty. Please add items before checking out.',
      );
      return;
    }

    final buyerId = StorageService().userId;
    if (buyerId == null || buyerId.isEmpty) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Auth Error',
        text: 'You must be logged in to create an order.',
        confirmBtnText: 'Login',
        onConfirmBtnTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, LoginScreen.id);
        },
      );
      return;
    }

    Future<void> executeApiCall() async {
      final itemsPayload =
          _cartService.items.map((item) {
            return {
              "productId": item['productId'],
              "quantity": item['quantity'],
            };
          }).toList();

      final bNumber = _buildingNumberController.text.trim();
      final payload = {
        "buyerId": buyerId,
        "receiverName": _receiverNameController.text.trim(),
        "receiverPhone": _receiverPhoneController.text.trim(),
        "shippingCity": _shippingCityController.text.trim(),
        "shippingStreet": _shippingStreetController.text.trim(),
        "buildingNumber": bNumber.isEmpty ? "Not specified" : bNumber,
        "items": itemsPayload,
      };

      QuickAlert.show(
        context: context,
        type: QuickAlertType.loading,
        title: 'Creating Order...',
        text: 'Please wait',
        barrierDismissible: false,
      );

      final navigator = Navigator.of(context, rootNavigator: true);
      final result = await _orderService.createOrder(payload);

      navigator.pop();

      if (!mounted) return;

      bool isActuallySuccess = result['success'] == true ||
          (result['message']?.toString().toLowerCase().contains('success') ?? false);

      if (isActuallySuccess) {
        context.read<CartCubit>().clearCart();
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          title: 'Success!',
          text: 'Your order has been created successfully.',
          onConfirmBtnTap: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const FarmerHomeScreen()),
              (route) => false,
            );
          },
        );
      } else {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Checkout Failed',
          text:
              result['message'] ??
              'An error occurred while creating the order.',
        );
      }
    }

    if (_receiverPhoneController.text.trim().isNotEmpty &&
        _shippingCityController.text.trim().isNotEmpty &&
        _shippingStreetController.text.trim().isNotEmpty) {
      if (_receiverNameController.text.trim().isEmpty) {
        _receiverNameController.text =
            StorageService().userFullName ?? 'Unknown';
      }
      if (!_formKey.currentState!.validate()) return;
      await executeApiCall();
      return;
    }

    _showAddressSelectionSheet((selectedAddress) async {
      setState(() {
        _receiverPhoneController.text = selectedAddress.phone;
        _shippingCityController.text = selectedAddress.city;
        _shippingStreetController.text = selectedAddress.street;
        _buildingNumberController.text = selectedAddress.buildingNumber;
        if (_receiverNameController.text.trim().isEmpty) {
          _receiverNameController.text =
              StorageService().userFullName ?? 'Unknown';
        }
      });

      if (!_formKey.currentState!.validate()) return;
      await executeApiCall();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          'Checkout',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
        ),
        backgroundColor: const Color(0xFF2ECC71),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_shipping, color: Color(0xFF2ECC71)),
                          SizedBox(width: 8),
                          Text(
                            'Shipping Details',
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      CustomTextFormField(
                        icon: Icons.person,
                        label: 'Receiver Name',
                        controller: _receiverNameController,
                        color: Colors.black87,
                        validator:
                            (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Please enter receiver name'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextFormField(
                        icon: Icons.phone,
                        label: 'Receiver Phone',
                        controller: _receiverPhoneController,
                        keyboardType: TextInputType.phone,
                        color: Colors.black87,
                        validator:
                            (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Please enter receiver phone'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextFormField(
                        icon: Icons.location_city,
                        label: 'City',
                        controller: _shippingCityController,
                        color: Colors.black87,
                        validator:
                            (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Please enter city'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextFormField(
                        icon: Icons.streetview,
                        label: 'Street',
                        controller: _shippingStreetController,
                        color: Colors.black87,
                        validator:
                            (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Please enter street'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextFormField(
                        icon: Icons.home,
                        label: 'Building Number (Optional)',
                        controller: _buildingNumberController,
                        keyboardType: TextInputType.number,
                        color: Colors.black87,
                        validator: (value) => null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2ECC71),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    'Confirm Order',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
