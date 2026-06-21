import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/features/cart/cubit/cart_cubit.dart';
import 'package:root2route/features/payment/logic/payment_cubit/payment_cubit.dart';
import 'package:root2route/features/payment/logic/payment_cubit/payment_state.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String orderId;

  const PaymentWebViewScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final PaymentCubit _cubit;
  InAppWebViewController? _webViewController;
  String? _transactionReference;
  bool _verificationTriggered = false;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<PaymentCubit>();
    _cubit.createPayment(widget.orderId);
  }

  /// Triggers verification exactly once, then lets BlocListener handle the rest.
  void _triggerVerification() {
    if (_verificationTriggered || _transactionReference == null) return;
    _verificationTriggered = true;
    print('=== TRIGGERING VERIFICATION for $_transactionReference ===');
    _cubit.verifyPayment(_transactionReference!);
  }

  Future<bool> _onWillPop() async {
    if (_verificationTriggered) return true;

    final shouldLeave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تنبيه'),
          content: const Text(
            'هل تريد الخروج؟ سيتم التحقق من حالة الدفع تلقائياً.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('البقاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('خروج والتحقق'),
            ),
          ],
        ),
      ),
    );

    if (shouldLeave == true && _transactionReference != null) {
      _triggerVerification();
      return false; // Let BlocListener handle pop after verify
    }

    return shouldLeave ?? false;
  }

  void _showOverlayLoading(BuildContext context, String text) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.pop(context, result);
        }
      },
      child: BlocListener<PaymentCubit, PaymentState>(
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
            // Close loading overlay if it was showing
            if (_verificationTriggered) {
              Navigator.pop(context);
            }
            QuickAlert.show(
              context: context,
              type: QuickAlertType.error,
              title: 'فشل الدفع',
              text: state.message,
              confirmBtnText: 'رجوع',
              confirmBtnColor: AppColors.primary,
              onConfirmBtnTap: () {
                Navigator.pop(context); // Close alert
                Navigator.pop(context); // Pop WebView
              },
            );
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
                    return InAppWebView(
                      initialUrlRequest: URLRequest(
                        url: WebUri(state.redirectUrl),
                      ),
                      initialSettings: InAppWebViewSettings(
                        javaScriptEnabled: true,
                        transparentBackground: true,
                        useShouldOverrideUrlLoading: true, // 👈 CRITICAL: must be true
                      ),
                      onWebViewCreated: (controller) {
                        _webViewController = controller;
                      },

                      // ─── PRIMARY INTERCEPTOR ───
                      shouldOverrideUrlLoading: (controller, navigationAction) async {
                        final url = navigationAction.request.url.toString();
                        print('=== WebView Navigation (shouldOverride): $url ===');

                        if (url.contains('/payment/result')) {
                          print('=== INTERCEPTED (shouldOverride): payment/result ===');
                          _triggerVerification();
                          return NavigationActionPolicy.CANCEL;
                        }
                        return NavigationActionPolicy.ALLOW;
                      },

                      // ─── BACKUP INTERCEPTOR 1 ───
                      onLoadStart: (controller, url) {
                        final urlString = url.toString();
                        print('=== onLoadStart: $urlString ===');

                        if (urlString.contains('/payment/result')) {
                          print('=== INTERCEPTED (onLoadStart): payment/result ===');
                          controller.stopLoading();
                          _triggerVerification();
                        }
                      },

                      // ─── BACKUP INTERCEPTOR 2 ───
                      onLoadStop: (controller, url) async {
                        final urlString = url.toString();
                        print('=== onLoadStop: $urlString ===');

                        if (urlString.contains('/payment/result')) {
                          print('=== INTERCEPTED (onLoadStop): payment/result ===');
                          _triggerVerification();
                        }
                      },

                      // ─── BACKUP INTERCEPTOR 3 (URL changes without navigation) ───
                      onUpdateVisitedHistory: (controller, url, androidIsReload) {
                        final urlString = url.toString();
                        print('=== onUpdateVisitedHistory: $urlString ===');

                        if (urlString.contains('/payment/result')) {
                          print('=== INTERCEPTED (onUpdateVisitedHistory): payment/result ===');
                          _triggerVerification();
                        }
                      },
                    );
                  }

                  // Fallback for Failed or Verifying states to just show empty while overlays take over
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
