import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/components/custom_text_form_field.dart';
import 'package:root2route/services/order_service.dart';
import 'package:root2route/services/storage_service.dart';
import 'package:root2route/services/cart_service.dart';
import 'package:root2route/screens/guest/guest_home_screen.dart';
import 'package:root2route/screens/auth/login_screen.dart';

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

  Future<void> _submitOrder() async {
    // 1. Validation
    if (!_formKey.currentState!.validate()) return;

    if (_cartService.items.isEmpty) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        title: 'Empty Cart',
        text: 'Your cart is empty. Please add items before checking out.',
      );
      return;
    }

    // 2. Auth Check
    final buyerId = StorageService().userId;
    if (buyerId == null || buyerId.isEmpty) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Auth Error',
        text: 'You must be logged in to create an order.',
        confirmBtnText: 'Login',
        onConfirmBtnTap: () {
          Navigator.pop(context); // Close alert
          Navigator.pushNamed(context, LoginScreen.id);
        },
      );
      return;
    }

    // 3. Data Mapping
    final itemsPayload = _cartService.items.map((item) {
      return {"productId": item['productId'], "quantity": item['quantity']};
    }).toList();

    final payload = {
      "buyerId": buyerId,
      "receiverName": _receiverNameController.text.trim(),
      "receiverPhone": _receiverPhoneController.text.trim(),
      "shippingCity": _shippingCityController.text.trim(),
      "shippingStreet": _shippingStreetController.text.trim(),
      "buildingNumber": _buildingNumberController.text.trim(),
      "items": itemsPayload,
    };

    // 4. API Call
    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: 'Creating Order...',
      text: 'Please wait',
      barrierDismissible: false,
    );

    final navigator = Navigator.of(context, rootNavigator: true);
    final result = await _orderService.createOrder(payload);

    navigator.pop(); // Close loading alert

    if (!mounted) return;

    // 5. Result Handling
    bool isActuallySuccess = result['success'] == true || 
                             (result['message']?.toString().contains('بنجاح') ?? false);

    if (isActuallySuccess) {
      _cartService.clearCart();
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: 'تم بنجاح!',
        text: 'تم إنشاء طلبك بنجاح.',
        onConfirmBtnTap: () {
          Navigator.of(context).pop(); // Close alert
          Navigator.of(context).pop(); // Close alert
          
        },
      );
    } else {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Checkout Failed',
        text: result['message'] ?? 'An error occurred while creating the order.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      const Row(
                        children: [
                          Icon(Icons.local_shipping, color: Color(0xFF2ECC71)),
                          SizedBox(width: 8),
                          Text(
                            'Shipping Details',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      CustomTextFormField(
                        icon: Icons.person,
                        label: 'Receiver Name',
                        controller: _receiverNameController,
                        color: Colors.black87,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Please enter receiver name' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextFormField(
                        icon: Icons.phone,
                        label: 'Receiver Phone',
                        controller: _receiverPhoneController,
                        keyboardType: TextInputType.phone,
                        color: Colors.black87,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Please enter receiver phone' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextFormField(
                        icon: Icons.location_city,
                        label: 'City',
                        controller: _shippingCityController,
                        color: Colors.black87,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Please enter city' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextFormField(
                        icon: Icons.streetview,
                        label: 'Street',
                        controller: _shippingStreetController,
                        color: Colors.black87,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Please enter street' : null,
                      ),
                      const SizedBox(height: 16),
                      CustomTextFormField(
                        icon: Icons.home,
                        label: 'Building Number',
                        controller: _buildingNumberController,
                        keyboardType: TextInputType.number,
                        color: Colors.black87,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Please enter building number' : null,
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                  ),
                  child: const Text(
                    'Confirm Order',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
