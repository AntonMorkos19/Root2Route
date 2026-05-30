import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/components/custom_text_form_field.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/services/order_service.dart';
import 'package:root2route/services/storage_service.dart';
import 'package:root2route/services/cart_service.dart';
import 'package:root2route/features/shipments/ui/addresses_screen.dart';
import 'package:root2route/features/shipments/cubit/shipment_address_cubit.dart';
import 'package:root2route/features/shipments/cubit/shipment_state.dart';
import 'package:root2route/models/shipment_address_model.dart';
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: BlocProvider(
            create: (context) => ShipmentAddressCubit()..fetchAddresses(),
            child: BlocBuilder<ShipmentAddressCubit, ShipmentState>(
              builder: (context, state) {
                if (state is ShipmentLoading) {
                  return const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2ECC71),
                      ),
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
                          'لا توجد عناوين محفوظة',
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
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'إضافة عنوان جديد',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
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
                          'اختر عنوان التوصيل',
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
                                    : 'عنوان ${index + 1}',
                              ),
                              subtitle: Text(
                                '${address.city}, ${address.street}\nالهاتف: ${address.phone}',
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
        title: 'سلة فارغة',
        text: 'سلتك فارغة. يرجى إضافة عناصر قبل الدفع.',
      );
      return;
    }

    final buyerId = StorageService().userId;

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
        title: 'جاري إنشاء الطلب...',
        text: 'يرجى الانتظار',
        barrierDismissible: false,
      );

      final navigator = Navigator.of(context, rootNavigator: true);
      final result = await _orderService.createOrder(payload);

      navigator.pop();

      if (!mounted) return;

      bool isActuallySuccess =
          result['success'] == true ||
          (result['message']?.toString().toLowerCase().contains('success') ??
              false);

      if (isActuallySuccess) {
        context.read<CartCubit>().clearCart();
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          title: 'تم الطلب بنجاح!',
          text:
              'تم تأكيد طلبك بنجاح. يمكنك متابعة منتجاتنا من الشاشة الرئيسية.',
          onConfirmBtnTap: () {
            // 1. السطر ده بيقفل الـ QuickAlert نفسه
            Navigator.of(context, rootNavigator: true).pop();

            // 2. السطر السحري ده بيقفل أي شاشات (دفع، عناوين، سلة) ويرجعك للناف بار الرئيسي
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        );
      } else {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'فشل الدفع',
          text: result['message'] ?? 'حدث خطأ أثناء إنشاء الطلب.',
        );
      }
    }

    if (_receiverPhoneController.text.trim().isNotEmpty &&
        _shippingCityController.text.trim().isNotEmpty &&
        _shippingStreetController.text.trim().isNotEmpty) {
      if (_receiverNameController.text.trim().isEmpty) {
        _receiverNameController.text =
            StorageService().userFullName ?? 'غير معروف';
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
              StorageService().userFullName ?? 'غير معروف';
        }
      });

      if (!_formKey.currentState!.validate()) return;
      await executeApiCall();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'الدفع',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.sp),
          ),
          backgroundColor: AppColors.primary,
          elevation: 0,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
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
                            Icon(
                              Icons.local_shipping,
                              color: Color(0xFF2ECC71),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'تفاصيل الشحن',
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
                          label: 'اسم المستلم',
                          controller: _receiverNameController,
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color ??
                              Colors.black87,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.transparent,
                          validator:
                              (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'يرجى إدخال اسم المستلم'
                                      : null,
                        ),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                          icon: Icons.phone,
                          label: 'رقم هاتف المستلم',
                          controller: _receiverPhoneController,
                          keyboardType: TextInputType.phone,
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color ??
                              Colors.black87,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.transparent,
                          validator:
                              (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'يرجى إدخال رقم هاتف المستلم'
                                      : null,
                        ),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                          icon: Icons.location_city,
                          label: 'المدينة',
                          controller: _shippingCityController,
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color ??
                              Colors.black87,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.transparent,
                          validator:
                              (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'يرجى إدخال المدينة'
                                      : null,
                        ),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                          icon: Icons.streetview,
                          label: 'الشارع',
                          controller: _shippingStreetController,
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color ??
                              Colors.black87,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.transparent,
                          validator:
                              (value) =>
                                  value == null || value.trim().isEmpty
                                      ? 'يرجى إدخال الشارع'
                                      : null,
                        ),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                          icon: Icons.home,
                          label: 'رقم المبنى (اختياري)',
                          controller: _buildingNumberController,
                          keyboardType: TextInputType.number,
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color ??
                              Colors.black87,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.transparent,
                          validator: (value) => null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 5,
                    ),
                    child: Text(
                      'تأكيد الطلب',
                      style: TextStyle(
                        fontSize: 15.sp,
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
      ),
    );
  }
}
