import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/features/shipments/cubit/shipment_address_cubit.dart';
import 'package:root2route/features/shipments/cubit/shipment_state.dart';
import 'package:root2route/features/shipments/data/models/shipment_address_model.dart';
import 'package:root2route/features/shipments/ui/addresses_screen.dart';

import 'package:root2route/features/payment/data/repositories/payment_repository.dart';
import 'package:root2route/features/payment/logic/payment_cubit/payment_cubit.dart';
import 'package:root2route/features/payment/presentation/screens/payment_webview_screen.dart';
import 'package:root2route/features/payment/presentation/widgets/payment_method_sheet.dart';
import 'package:dio/dio.dart';
import 'package:root2route/core/constants.dart';
import 'package:root2route/core/services/storage_service.dart';

/// Auction checkout screen — collects address + payment method
/// for an order that was already created by POST /auctions/{id}/checkout.
class AuctionCheckoutScreen extends StatefulWidget {
  final String auctionId;
  final String title;

  const AuctionCheckoutScreen({
    super.key,
    required this.auctionId,
    required this.title,
  });

  @override
  State<AuctionCheckoutScreen> createState() => _AuctionCheckoutScreenState();
}

class _AuctionCheckoutScreenState extends State<AuctionCheckoutScreen> {
  late final ShipmentAddressCubit _addressCubit;

  ShipmentAddressModel? _selectedAddress;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _addressCubit = ShipmentAddressCubit()..fetchAddresses();
  }

  @override
  void dispose() {
    _addressCubit.close();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────
  // Address selection
  // ──────────────────────────────────────────────────────────────

  void _onAddressSelected(ShipmentAddressModel address) {
    setState(() => _selectedAddress = address);
  }

  // ──────────────────────────────────────────────────────────────
  // Confirm → show payment method sheet
  // ──────────────────────────────────────────────────────────────

  void _onConfirmTapped() {
    if (_selectedAddress == null) {
      QuickAlert.show(
        confirmBtnText: 'موافق',
        context: context,
        type: QuickAlertType.warning,
        title: 'اختر عنوان',
        text: 'يرجى اختيار عنوان التوصيل قبل المتابعة.',
        barrierDismissible: false,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentMethodSheet(
        onCashSelected: () {
          Navigator.pop(context); // close sheet
          _handlePayment(0); // 0 = Cash
        },
        onCardSelected: () {
          Navigator.pop(context); // close sheet
          _handlePayment(1); // 1 = Card / Visa
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Payment handling — reuses the same OrderService.updateOrderPayment
  // ──────────────────────────────────────────────────────────────

  Future<void> _handlePayment(int paymentMethodId) async {
    if (_isProcessing) return;
    _isProcessing = true;

    // Show loading
    QuickAlert.show(
      confirmBtnText: 'موافق',
      context: context,
      type: QuickAlertType.loading,
      title: 'جاري تنفيذ الطلب...',
      text: 'يرجى الانتظار',
      barrierDismissible: false,
    );

    try {
      final dio = Dio(BaseOptions(baseUrl: baseUrl));
      final token = StorageService().token;
      if (token != null && token.isNotEmpty) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }

      // We use POST /auctions/{auctionId}/checkout with the shipping and payment details
      final payload = {
        'receiverName': _selectedAddress?.fullName ?? '',
        'receiverPhone': _selectedAddress?.phone ?? '',
        'shippingCity': _selectedAddress?.city ?? '',
        'shippingAddress': _selectedAddress?.street ?? '',
        'paymentMethod': paymentMethodId == 0 ? 'CashOnDelivery' : 'Card',
      };

      final endpoint = '/auctions/${widget.auctionId}/checkout';
      
      debugPrint('=== [AUCTION CHECKOUT API CALL] ===');
      debugPrint('FULL URL: ${dio.options.baseUrl}$endpoint');
      debugPrint('METHOD: POST');
      debugPrint('PAYLOAD: $payload');
      debugPrint('===========================');

      final response = await dio.post(
        endpoint,
        data: payload,
        options: Options(validateStatus: (status) => status != null && status <= 400),
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loading

      final body = response.data;
      final succeeded = (body is Map && body['succeeded'] == true) || 
                        response.statusCode == 200 || 
                        (body is Map && body['statusCode'] == 200);

      if (succeeded) {
        String? extractedOrderId;
        if (body is Map && body['data'] != null) {
          final data = body['data'];
          if (data is Map) {
             extractedOrderId = (data['orderId'] ?? data['OrderId'] ?? data['id'] ?? data['Id'])?.toString();
          } else {
             extractedOrderId = data.toString().replaceAll('"', '').trim();
          }
        }

        if (paymentMethodId == 1) {
          if (extractedOrderId == null || extractedOrderId.isEmpty) {
             _showErrorAlert('لم يتم العثور على رقم الطلب للتوجه للدفع.');
             return;
          }
          // Card → go to payment web view
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) => PaymentCubit(PaymentRepository()),
                  child: PaymentWebViewScreen(orderId: extractedOrderId!),
                ),
              ),
            );
          }
        } else {
          // Cash on delivery → success
          if (context.mounted) {
            QuickAlert.show(
              context: context,
              type: QuickAlertType.success,
              title: 'تم الطلب بنجاح',
              text: 'سيتم التواصل معك قريباً لتأكيد موعد التسليم.',
              confirmBtnText: 'حسناً',
              confirmBtnColor: AppColors.primary,
              onConfirmBtnTap: () {
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            );
          }
        }
      } else {
        final msg = (body is Map) 
            ? (body['message'] ?? body['Message'] ?? 'حدث خطأ أثناء تأكيد الطلب')
            : 'حدث خطأ أثناء تأكيد الطلب';
        _showErrorAlert(msg.toString());
      }
    } on DioException catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
      final body = e.response?.data;
      final msg = (body is Map)
          ? (body['message'] ?? body['Message'] ?? 'حدث خطأ')
          : 'حدث خطأ في الاتصال';
      debugPrint('[CONFIRM ERROR] ${e.response?.statusCode}: $body');
      _showErrorAlert(msg.toString());
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop(); // dismiss loading
      debugPrint('[CONFIRM UNEXPECTED ERROR] $e');
      _showErrorAlert('حدث خطأ غير متوقع');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showErrorAlert(String message) {
    if (!mounted) return;
    QuickAlert.show(
      context: context,
      type: QuickAlertType.error,
      title: 'خطأ',
      text: message,
      confirmBtnText: 'موافق',
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider<ShipmentAddressCubit>.value(
      value: _addressCubit,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              'إتمام الطلب',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20.sp,
              ),
            ),
            backgroundColor: AppColors.primary,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Column(
            children: [
              // ── Order info banner ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.08),
                      AppColors.primary.withValues(alpha: 0.02),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.gavel_rounded, color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Address list ──
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section title
                      Row(
                        children: [
                          Icon(Icons.location_on, color: AppColors.primary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'عنوان التوصيل',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddressesScreen(),
                                ),
                              );
                              // Refresh addresses after coming back
                              _addressCubit.fetchAddresses();
                            },
                            icon: const Icon(Icons.add, size: 18, color: AppColors.primary),
                            label: Text(
                              'إضافة عنوان',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Address cards
                      BlocBuilder<ShipmentAddressCubit, ShipmentState>(
                        bloc: _addressCubit,
                        builder: (context, state) {
                          if (state is ShipmentLoading || state is ShipmentInitial) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          }

                          if (state is ShipmentError) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red.shade300, size: 40),
                                    const SizedBox(height: 8),
                                    Text(
                                      state.message,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.red.shade400),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () => _addressCubit.fetchAddresses(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('إعادة المحاولة'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final addresses = state is ShipmentAddressesLoaded
                              ? state.addresses
                              : <ShipmentAddressModel>[];

                          if (addresses.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.location_off_outlined,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'لا توجد عناوين محفوظة',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'أضف عنوان توصيل جديد للمتابعة',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: addresses.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final addr = addresses[i];
                              final isSelected = _selectedAddress?.id == addr.id;

                              return GestureDetector(
                                onTap: () => _onAddressSelected(addr),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withValues(alpha: 0.06)
                                        : isDark
                                            ? const Color(0xFF2A2A2A)
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.grey.shade300,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary.withValues(alpha: 0.12),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      // Radio-style indicator
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primary
                                                : Colors.grey.shade400,
                                            width: 2,
                                          ),
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.transparent,
                                        ),
                                        child: isSelected
                                            ? const Icon(
                                                Icons.check,
                                                size: 14,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),

                                      // Address info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    addr.fullName.isNotEmpty
                                                        ? addr.fullName
                                                        : 'عنوان ${i + 1}',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14.sp,
                                                      color: isSelected
                                                          ? AppColors.primary
                                                          : null,
                                                    ),
                                                  ),
                                                ),
                                                if (addr.isDefault)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary.withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      'افتراضي',
                                                      style: TextStyle(
                                                        fontSize: 10.sp,
                                                        color: AppColors.primary,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${addr.city}${addr.street.isNotEmpty ? '، ${addr.street}' : ''}',
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: Colors.grey.shade600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (addr.phone.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                addr.phone,
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // ── Bottom confirm button ──
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _onConfirmTapped,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        'اختر طريقة الدفع',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
