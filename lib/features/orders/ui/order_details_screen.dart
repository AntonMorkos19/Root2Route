import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/features/orders/cubit/order_details_cubit.dart';
import 'package:root2route/features/orders/cubit/order_state.dart';
import 'package:root2route/features/shipments/cubit/confirm_delivery_cubit.dart';
import 'package:root2route/features/shipments/cubit/dispatch_cubit.dart';
import 'package:root2route/features/shipments/cubit/shipment_state.dart';
import 'package:root2route/features/shipments/widgets/dispatch_bottom_sheet.dart';
import 'package:root2route/features/orders/data/models/order_model.dart';
import 'package:root2route/features/orders/data/services/order_service.dart';
import 'package:root2route/features/reviews/ui/add_review_dialog.dart';
import 'package:root2route/core/utils/price_formatter.dart';
 class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  /// Pass [isSellerView] = true when the seller is opening this screen
  /// from the "Received Orders" tab so the correct action buttons appear.
  final bool isSellerView;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    this.isSellerView = false,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  // ── Cubits (created once) ─────────────────────────────────
  late final OrderDetailsCubit _detailsCubit;
  late final DispatchCubit _dispatchCubit;
  late final ConfirmDeliveryCubit _confirmDeliveryCubit;

  // ── OrderService: kept only for cancel action ─────────────
  final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    _detailsCubit = OrderDetailsCubit()..fetchOrderDetails(widget.orderId);
    _dispatchCubit = DispatchCubit();
    _confirmDeliveryCubit = ConfirmDeliveryCubit();
  }

  @override
  void dispose() {
    _detailsCubit.close();
    _dispatchCubit.close();
    _confirmDeliveryCubit.close();
    super.dispose();
  }

  // ── Status helpers (unchanged) ─────────────────────────────

  Color _statusColor(int status) {
    switch (status) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.teal;
      case 3:
        return Colors.green;
      case 4:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(int status) {
    switch (status) {
      case 0:
        return Icons.hourglass_empty;
      case 1:
        return Icons.check_circle_outline;
      case 2:
        return Icons.local_shipping_outlined;
      case 3:
        return Icons.done_all;
      case 4:
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  // ── Cancel order (unchanged logic, same QuickAlert flow) ──

  Future<void> _cancelOrder() async {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      title: 'إلغاء الطلب؟',
      text: 'هل أنت متأكد أنك تريد إلغاء هذا الطلب؟',
      barrierDismissible: false,
      confirmBtnText: 'نعم، إلغاء',
      cancelBtnText: 'لا',
      confirmBtnColor: Colors.red,
      onConfirmBtnTap: () async {
        Navigator.of(context, rootNavigator: true).pop();

        QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', 
          context: context,
          type: QuickAlertType.loading,
          title: 'جاري الإلغاء...',
          barrierDismissible: false,
        );

        final result = await _orderService.cancelOrder(widget.orderId);

        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();

        final bool cancelled =
            result['success'] == true ||
            (result['message']?.toString().contains('Cancelled') ?? false);

        if (cancelled) {
          QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', context: context, type: QuickAlertType.success, title: 'نجاح', text: result['success'] == true
                ? 'تم إلغاء طلبك بنجاح.'
                : 'هذا الطلب ملغى بالفعل.',);
          _detailsCubit.fetchOrderDetails(widget.orderId);
        } else {
          QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', 
            context: context,
            type: QuickAlertType.error,
            title: 'فشل الإلغاء',
            text: result['message'] ?? 'لا يمكن إلغاء الطلب.',
            barrierDismissible: false,
          );
        }
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<OrderDetailsCubit>.value(value: _detailsCubit),
        BlocProvider<DispatchCubit>.value(value: _dispatchCubit),
        BlocProvider<ConfirmDeliveryCubit>.value(value: _confirmDeliveryCubit),
      ],
      child: MultiBlocListener(
        listeners: [
          // ── DispatchCubit feedback ──────────────────────────
          BlocListener<DispatchCubit, ShipmentState>(
            listener: (context, state) {
              if (state is ShipmentLoading) {
                QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', 
                  context: context,
                  type: QuickAlertType.loading,
                  title: 'جاري الإرسال...',
                  barrierDismissible: false,
                );
              } else if (state is ShipmentActionSuccess) {
                Navigator.of(context, rootNavigator: true).pop();
                QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', context: context, type: QuickAlertType.success, title: 'نجاح', text: state.message);
                _detailsCubit.fetchOrderDetails(widget.orderId);
              } else if (state is ShipmentError) {
                Navigator.of(context, rootNavigator: true).pop();
                QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', 
                  context: context,
                  type: QuickAlertType.error,
                  title: 'خطأ',
                  text: state.message,
                  barrierDismissible: false,
                );
              }
            },
          ),

          // ── ConfirmDeliveryCubit feedback ───────────────────
          BlocListener<ConfirmDeliveryCubit, ShipmentState>(
            listener: (context, state) {
              if (state is ShipmentLoading) {
                QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', 
                  context: context,
                  type: QuickAlertType.loading,
                  title: 'جاري التأكيد...',
                  barrierDismissible: false,
                );
              } else if (state is ShipmentActionSuccess) {
                Navigator.of(context, rootNavigator: true).pop();
                QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', context: context, type: QuickAlertType.success, title: 'نجاح', text: state.message);
                _detailsCubit.fetchOrderDetails(widget.orderId);
              } else if (state is ShipmentError) {
                Navigator.of(context, rootNavigator: true).pop();
                QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', 
                  context: context,
                  type: QuickAlertType.error,
                  title: 'خطأ',
                  text: state.message,
                  barrierDismissible: false,
                );
              }
            },
          ),
        ],
        child: BlocBuilder<OrderDetailsCubit, OrderState>(
          builder: (context, state) {
            final OrderModel? order =
                state is OrderDetailLoaded ? state.order : null;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                appBar: AppBar(
                  title: Text(
                    'تفاصيل الطلب',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.sp,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: AppColors.primary,
                iconTheme: const IconThemeData(color: Colors.white),
                elevation: 0,
              ),
              body: _buildBody(state, order),
                bottomNavigationBar: _buildBottomAction(context, order),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────

  Widget _buildBody(OrderState state, OrderModel? order) {
    if (state is OrderInitial || state is OrderLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state is OrderError || order == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                state is OrderError ? state.message : 'الطلب غير موجود',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed:
                    () => _detailsCubit.fetchOrderDetails(widget.orderId),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final color = _statusColor(order.status);
    final icon = _statusIcon(order.status);
    final dateStr =
        order.createdAt != null
            ? '${order.createdAt!.day}/${order.createdAt!.month}/${order.createdAt!.year}'
                ' - ${order.createdAt!.hour}:${order.createdAt!.minute.toString().padLeft(2, '0')}'
            : 'N/A';

    return RefreshIndicator(
      onRefresh: () => _detailsCubit.fetchOrderDetails(widget.orderId),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Status Card ─────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(icon, size: 40, color: color),
                  const SizedBox(height: 8),
                  Text(
                    order.statusText,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (order.status == 2 || order.status == 3) ...[
              _buildInfoCard(
                title: 'تفاصيل الشحن',
                icon: Icons.assignment_turned_in_outlined,
                children: [
                  _buildDispatchRow(
                    Icons.local_shipping,
                    'اسم الناقل',
                    order.carrier?.isNotEmpty == true
                        ? order.carrier!
                        : 'غير محدد',
                  ),
                  _buildDispatchRow(
                    Icons.qr_code,
                    'رقم التتبع',
                    order.trackingNumber?.isNotEmpty == true
                        ? order.trackingNumber!
                        : 'غير محدد',
                  ),
                  _buildDispatchRow(
                    Icons.phone,
                    'هاتف السائق',
                    order.driverPhone?.isNotEmpty == true
                        ? order.driverPhone!
                        : 'غير محدد',
                    isClickable: order.driverPhone?.isNotEmpty == true,
                    context: context,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            _buildInfoCard(
              title: 'معلومات الشحن',
              icon: Icons.local_shipping_outlined,
              children: [
                _buildInfoRow('المستلم', order.receiverName),
                _buildInfoRow('رقم الهاتف', order.receiverPhone),
                _buildInfoRow('المدينة', order.shippingCity),
                _buildInfoRow('الشارع', order.shippingStreet),
                _buildInfoRow('المبنى', order.buildingNumber),
              ],
            ),
            const SizedBox(height: 16),

            _buildInfoCard(
              title: 'العناصر ',
              icon: Icons.inventory_2_outlined,
              children:
                  order.items.isEmpty
                      ? [
                        const Text(
                          'لا توجد بيانات للعناصر',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ]
                      : order.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.productName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              const SizedBox(width: 16),
                              Text(
                                item.quantityWithUnit,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (order.status == 3 && !widget.isSellerView)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: TextButton(
                                    onPressed: () {
                                      showAddReviewDialog(
                                        context,
                                        targetOrganizationId:
                                            item.organizationId.isNotEmpty
                                                ? item.organizationId
                                                : order.organizationId,
                                        orderId: order.id,
                                        productId: item.productId,
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(50, 30),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      foregroundColor: AppColors.primary,
                                    ),
                                    child: Text(
                                      'تقييم',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
            ),
            const SizedBox(height: 16),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'المبلغ الإجمالي',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${PriceFormatter.format(order.totalAmount)} EGP',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            if (order.note.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'ملاحظة',
                icon: Icons.note_outlined,
                children: [
                  Text(
                    order.note,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDispatchRow(
    IconData icon,
    String label,
    String value, {
    bool isClickable = false,
    BuildContext? context,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16.sp),
            ),
          ),
          isClickable
              ? InkWell(
                onTap: () {
                  if (context != null) {
                    QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', context: context, type: QuickAlertType.info, text: 'تم نسخ $value');
                  }
                },
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              )
              : Text(
                value,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp),
              ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16.sp),
          ),
          Text(
            value.isEmpty ? 'غير متوفر' : value,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp),
          ),
        ],
      ),
    );
  }

  // ── Dynamic bottom action bar ──────────────────────────────

  Widget? _buildBottomAction(BuildContext context, OrderModel? order) {
    if (order == null) return null;

    // ── 1. Seller: Confirmed → dispatch shipment ─────────────
    if (order.status == 1 && widget.isSellerView) {
      return _bottomBar(
        child: ElevatedButton.icon(
          onPressed:
              () => showDispatchBottomSheet(
                context,
                orderId: widget.orderId,
                dispatchCubit: context.read<DispatchCubit>(),
              ),
          label: Text(
            'شحن الطلب',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    // ── 2. Buyer: Shipped → confirm delivery ─────────────────
    if (order.status == 2 && !widget.isSellerView) {
      return _bottomBar(
        child: ElevatedButton.icon(
          onPressed: () async {
            QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', 
              context: context,
              type: QuickAlertType.loading,
              title: 'جاري التأكيد...',
              text: 'الرجاء الانتظار',
              barrierDismissible: false,
            );

            final result = await _orderService.changeOrderStatus(
              orderId: widget.orderId,
              newStatus: 3, // Delivered
            );

            if (!mounted) return;
            Navigator.of(context, rootNavigator: true).pop(); // dismiss loading

            if (result['success'] == true) {
              QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', context: context, type: QuickAlertType.success, title: 'نجاح', text: 'تم استلام الطلب بنجاح!');
              _detailsCubit.fetchOrderDetails(widget.orderId);
            } else {
              QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', 
                context: context,
                type: QuickAlertType.error,
                title: 'خطأ',
                text: result['message'] ?? 'فشل تأكيد الاستلام.',
                barrierDismissible: false,
              );
            }
          },
          label: Text(
            'تأكيد الاستلام',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    // ── 3. Buyer: Pending → cancel order ─────────────────────
    if (order.status == 0 && !widget.isSellerView) {
      return _bottomBar(
        child: OutlinedButton.icon(
          onPressed: _cancelOrder,
          icon: const Icon(Icons.cancel_outlined, color: Colors.red),
          label: Text(
            'إلغاء الطلب',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }

    return null; // No action for other statuses
  }

  /// Shared bottom-bar container wrapper.
  Widget _bottomBar({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(child: SizedBox(width: double.infinity, child: child)),
    );
  }
}
