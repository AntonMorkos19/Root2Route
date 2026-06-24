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

  const PaymentWebViewScreen({super.key, required this.orderId});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final PaymentCubit _cubit;
  InAppWebViewController? _webViewController;
  String? _transactionReference;
  bool _verificationTriggered = false;
  bool _isWebViewLoading = true;
  bool _userCancelled = false;

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
                  'هل أنت متأكد من رغبتك في الخروج؟ سيتم التحقق من حالة الدفع تلقائياً.',
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
                          'خروج ',
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

    if (shouldLeave == true) {
      // If we have a transaction reference, verify before leaving
      if (_transactionReference != null) {
        _userCancelled = true;
        _triggerVerification();
        return false; // Let BlocListener handle pop after verify
      }
      // No transaction yet — user cancelled before payment page loaded.
      // Just pop silently with a gentle snackbar.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إلغاء الدفع'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return true;
    }

    return false;
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

            // Graceful handling: if user intentionally cancelled (status is
            // 'Pending' or similar), show a gentle snackbar instead of a
            // scary red error alert.
            final msg = state.message.toLowerCase();
            final isUserCancellation =
                _userCancelled ||
                msg.contains('pending') ||
                msg.contains('cancelled') ||
                msg.contains('canceled');

            if (isUserCancellation) {
              // Gentle exit — just pop and show a snackbar
              Navigator.pop(context); // Pop WebView
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم إلغاء الدفع'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              // Real API / transaction failure — show red alert
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
                    return Stack(
                      children: [
                        InAppWebView(
                          initialUrlRequest: URLRequest(
                            url: WebUri(state.redirectUrl),
                          ),
                          initialSettings: InAppWebViewSettings(
                            javaScriptEnabled: true,
                            transparentBackground: true,
                            useShouldOverrideUrlLoading:
                                true, // 👈 CRITICAL: must be true
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

                            // Show loading overlay while page loads
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

                            // Hide loading overlay — page has finished rendering
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

                          // ─── BACKUP INTERCEPTOR 3 (URL changes without navigation) ───
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
                        // Shows a centered spinner on top of the WebView while
                        // the PayTabs page is loading, preventing the blank
                        // white-screen flash.
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
