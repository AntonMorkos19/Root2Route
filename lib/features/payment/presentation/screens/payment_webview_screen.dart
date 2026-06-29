import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/features/cart/cubit/cart_cubit.dart';
import 'package:root2route/features/orders/ui/cart_screen.dart';
import 'package:root2route/features/orders/ui/checkout_screen.dart';
import 'package:root2route/features/payment/logic/payment_cubit/payment_cubit.dart';
import 'package:root2route/features/payment/logic/payment_cubit/payment_state.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:root2route/features/orders/data/services/order_service.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String orderId;

  const PaymentWebViewScreen({super.key, required this.orderId});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final PaymentCubit _cubit;
  final OrderService _orderService = OrderService();
  InAppWebViewController? _webViewController;
  String? _transactionReference;
  bool _verificationTriggered = false;
  bool _isWebViewLoading = true;
  bool _userCancelled = false;
  bool _isCancellingOrder = false;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<PaymentCubit>();
    _cubit.createPayment(widget.orderId);
    BackButtonInterceptor.add(_backButtonInterceptor);
  }

  /// Triggers verification exactly once, then lets BlocListener handle the rest.
  void _triggerVerification() {
    if (_verificationTriggered || _transactionReference == null) return;
    _verificationTriggered = true;
    print('=== TRIGGERING VERIFICATION for $_transactionReference ===');
    _cubit.verifyPayment(_transactionReference!);
  }

  /// Called by PopScope — non-async wrapper to avoid hardware back bypass.
  void _handleBackPress() async {
    await _onWillPop();
  }

  /// Intercepts Android hardware back button before InAppWebView consumes it.
  FutureOr<bool> _backButtonInterceptor(
      bool stopDefaultButtonEvent, RouteInfo info) {
    _handleBackPress();
    return true; // true = block default back behavior
  }

  Future<void> _onWillPop() async {
    if (_verificationTriggered) return;
    
    final shouldLeave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const Icon(
                  Icons.warning_rounded,
                  color: Colors.orangeAccent,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'إلغاء الدفع؟',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'هل أنت متأكد من رغبتك في الخروج؟',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          'البقاء',
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'خروج',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        );
      },
    );

    if (shouldLeave == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إلغاء الدفع'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const CartScreen(
            // If CheckoutScreen requires parameters, pass them here.
            // Example: auctionId: widget.auctionId, 
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(_backButtonInterceptor);
    super.dispose();
  }

  void _showOverlayLoading(BuildContext context, String text) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => PopScope(
            canPop: false,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 24),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentCubit, PaymentState>(
        listener: (context, state) {
          if (state is PaymentWebViewReady) {
            _transactionReference = state.transactionReference;
          } else if (state is PaymentVerifying) {
            _showOverlayLoading(context, 'جاري التحقق من حالة الدفع...');
          } else if (state is PaymentCaptured) {
            Navigator.pop(context); // Close loading overlay
            context.read<CartCubit>().clearCart();
            QuickAlert.show(
              context: context,
              type: QuickAlertType.success,
              title: 'نجاح',
              text: 'تم تأكيد الدفع بنجاح!',
              confirmBtnText: 'موافق',
              confirmBtnColor: AppColors.primary,
              onConfirmBtnTap: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            );
          } else if (state is PaymentFailed) {
            // Close loading overlay safely
            try {
              if (_verificationTriggered && Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            } catch (_) {}

            final msg = state.message.toLowerCase();
            final isUserCancellation =
                _userCancelled ||
                msg.contains('pending') ||
                msg.contains('cancelled') ||
                msg.contains('canceled');

            if (isUserCancellation) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم إلغاء الدفع'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const CheckoutScreen(
                    // If CheckoutScreen requires parameters, pass them here.
                    // Example: auctionId: widget.auctionId, 
                  ),
                ),
              );
            } else {
              if (!mounted) return;
              QuickAlert.show(
                context: context,
                type: QuickAlertType.error,
                title: 'فشل الدفع',
                text: state.message,
                confirmBtnText: 'رجوع للسوق',
                confirmBtnColor: AppColors.primary,
                onConfirmBtnTap: () {
                  Navigator.pop(context); // Close alert
                  Navigator.pop(context); // Close WebView
                },
              );
            }
          }
        },
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                'الدفع الأمن',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
              ),
              backgroundColor: AppColors.primary,
              iconTheme: const IconThemeData(color: Colors.white),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _handleBackPress,
              ),
            ),
            body: SafeArea(
              child: BlocBuilder<PaymentCubit, PaymentState>(
                builder: (context, state) {
                  if (state is PaymentInitial || state is PaymentLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'جاري تحضير صفحة الدفع...',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is PaymentWebViewReady) {
                    return Stack(
                      children: [
                        InAppWebView(
                          initialUrlRequest: URLRequest(
                            url: WebUri(state.redirectUrl),
                          ),
                          initialSettings: InAppWebViewSettings(
                            javaScriptEnabled: true,
                            transparentBackground: true,
                            useShouldOverrideUrlLoading: true,
                          ),
                          onWebViewCreated: (controller) {
                            _webViewController = controller;
                          },

                          // ─── PRIMARY INTERCEPTOR ───
                          shouldOverrideUrlLoading: (
                            controller,
                            navigationAction,
                          ) async {
                            final url = navigationAction.request.url.toString();
                            print(
                              '=== WebView Navigation (shouldOverride): $url ===',
                            );
                            if (url.contains('/payment/result') ||
                                url.contains('/payment/success')) {
                              print(
                                '=== INTERCEPTED (shouldOverride): payment completion ===',
                              );
                              _triggerVerification();
                              return NavigationActionPolicy.CANCEL;
                            }
                            return NavigationActionPolicy.ALLOW;
                          },

                          // ─── BACKUP INTERCEPTOR 1 ───
                          onLoadStart: (controller, url) {
                            final urlString = url.toString();
                            print('=== onLoadStart: $urlString ===');
                            if (mounted)
                              setState(() => _isWebViewLoading = true);
                            if (urlString.contains('/payment/result') ||
                                urlString.contains('/payment/success')) {
                              print(
                                '=== INTERCEPTED (onLoadStart): payment completion ===',
                              );
                              controller.stopLoading();
                              _triggerVerification();
                            }
                          },

                          // ─── BACKUP INTERCEPTOR 2 ───
                          onLoadStop: (controller, url) async {
                            final urlString = url.toString();
                            print('=== onLoadStop: $urlString ===');
                            if (mounted)
                              setState(() => _isWebViewLoading = false);
                            if (urlString.contains('/payment/result') ||
                                urlString.contains('/payment/success')) {
                              print(
                                '=== INTERCEPTED (onLoadStop): payment completion ===',
                              );
                              _triggerVerification();
                            }
                          },

                          // ─── BACKUP INTERCEPTOR 3 ───
                          onUpdateVisitedHistory: (
                            controller,
                            url,
                            androidIsReload,
                          ) {
                            final urlString = url.toString();
                            print('=== onUpdateVisitedHistory: $urlString ===');
                            if (urlString.contains('/payment/result') ||
                                urlString.contains('/payment/success')) {
                              print(
                                '=== INTERCEPTED (onUpdateVisitedHistory): payment completion ===',
                              );
                              _triggerVerification();
                            }
                          },
                        ),

                        // ─── LOADING OVERLAY ───
                        if (_isWebViewLoading)
                          Container(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'جاري تحميل صفحة الدفع...',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
    ));
  }
}
