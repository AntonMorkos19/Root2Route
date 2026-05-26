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
import 'package:root2route/models/order_model.dart';
import 'package:root2route/services/order_service.dart';
import 'package:root2route/features/reviews/ui/add_review_dialog.dart';

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
        return Colors.indigo;
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
      title: 'Cancel Order?',
      text: 'Are you sure you want to cancel this order?',
      confirmBtnText: 'Yes, Cancel',
      cancelBtnText: 'No',
      confirmBtnColor: Colors.red,
      onConfirmBtnTap: () async {
        Navigator.pop(context);

        QuickAlert.show(
          context: context,
          type: QuickAlertType.loading,
          title: 'Cancelling...',
          barrierDismissible: false,
        );

        final result = await _orderService.cancelOrder(widget.orderId);

        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();

        final bool cancelled =
            result['success'] == true ||
            (result['message']?.toString().contains('Cancelled') ?? false);

        if (cancelled) {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            title: result['success'] == true ? 'Cancelled' : 'Note',
            text:
                result['success'] == true
                    ? 'Your order has been cancelled successfully.'
                    : 'This order is already cancelled.',
            onConfirmBtnTap: () {
              Navigator.pop(context);
              _detailsCubit.fetchOrderDetails(widget.orderId);
            },
          );
        } else {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.error,
            title: 'Cancellation Failed',
            text: result['message'] ?? 'Could not cancel the order.',
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
                QuickAlert.show(
                  context: context,
                  type: QuickAlertType.loading,
                  title: 'Sending...',
                  barrierDismissible: false,
                );
              } else if (state is ShipmentActionSuccess) {
                Navigator.of(context, rootNavigator: true).pop();
                QuickAlert.show(
                  context: context,
                  type: QuickAlertType.success,
                  title: 'Sent',
                  text: state.message,
                  onConfirmBtnTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    _detailsCubit.fetchOrderDetails(widget.orderId);
                  },
                );
              } else if (state is ShipmentError) {
                Navigator.of(context, rootNavigator: true).pop();
                QuickAlert.show(
                  context: context,
                  type: QuickAlertType.error,
                  title: 'Error',
                  text: state.message,
                );
              }
            },
          ),

          // ── ConfirmDeliveryCubit feedback ───────────────────
          BlocListener<ConfirmDeliveryCubit, ShipmentState>(
            listener: (context, state) {
              if (state is ShipmentLoading) {
                QuickAlert.show(
                  context: context,
                  type: QuickAlertType.loading,
                  title: 'Confirming...',
                  barrierDismissible: false,
                );
              } else if (state is ShipmentActionSuccess) {
                Navigator.of(context, rootNavigator: true).pop();
                QuickAlert.show(
                  context: context,
                  type: QuickAlertType.success,
                  title: 'Received',
                  text: state.message,
                  onConfirmBtnTap: () {
                    Navigator.of(context, rootNavigator: true).pop();
                    _detailsCubit.fetchOrderDetails(widget.orderId);
                  },
                );
              } else if (state is ShipmentError) {
                Navigator.of(context, rootNavigator: true).pop();
                QuickAlert.show(
                  context: context,
                  type: QuickAlertType.error,
                  title: 'Error',
                  text: state.message,
                );
              }
            },
          ),
        ],
        child: BlocBuilder<OrderDetailsCubit, OrderState>(
          builder: (context, state) {
            final OrderModel? order =
                state is OrderDetailLoaded ? state.order : null;

            return Scaffold(
              backgroundColor: const Color(0xFFF4F6F9),
              appBar: AppBar(
                title: Text(
                  'Order Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.sp,
                  ),
                ),
                backgroundColor: AppColors.primary,
                elevation: 0,
              ),
              body: _buildBody(state, order),
              bottomNavigationBar: _buildBottomAction(context, order),
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
                state is OrderError ? state.message : 'Order not found',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed:
                    () => _detailsCubit.fetchOrderDetails(widget.orderId),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
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
                title: 'Dispatch Details',
                icon: Icons.assignment_turned_in_outlined,
                children: [
                  _buildDispatchRow(
                    Icons.local_shipping,
                    'Carrier Name',
                    order.carrier?.isNotEmpty == true
                        ? order.carrier!
                        : 'Not specified',
                  ),
                  _buildDispatchRow(
                    Icons.qr_code,
                    'Tracking Number',
                    order.trackingNumber?.isNotEmpty == true
                        ? order.trackingNumber!
                        : 'Not specified',
                  ),
                  _buildDispatchRow(
                    Icons.phone,
                    'Driver\'s Phone',
                    order.driverPhone?.isNotEmpty == true
                        ? order.driverPhone!
                        : 'Not specified',
                    isClickable: order.driverPhone?.isNotEmpty == true,
                    context: context,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            _buildInfoCard(
              title: 'Shipping Information',
              icon: Icons.local_shipping_outlined,
              children: [
                _buildInfoRow('Receiver', order.receiverName),
                _buildInfoRow('Phone', order.receiverPhone),
                _buildInfoRow('City', order.shippingCity),
                _buildInfoRow('Street', order.shippingStreet),
                _buildInfoRow('Building', order.buildingNumber),
              ],
            ),
            const SizedBox(height: 16),

            _buildInfoCard(
              title: 'Items ',
              icon: Icons.inventory_2_outlined,
              children:
                  order.items.isEmpty
                      ? [
                        const Text(
                          'No items data',
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
                                      'Review',
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${order.totalAmount.toStringAsFixed(0)} EGP',
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
                title: 'Note',
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
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Copied $value')));
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
            value.isEmpty ? 'N/A' : value,
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
            'Dispatch Shipment',
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
            QuickAlert.show(
              context: context,
              type: QuickAlertType.loading,
              title: 'Confirming...',
              text: 'Please wait',
              barrierDismissible: false,
            );

            final result = await _orderService.changeOrderStatus(
              orderId: widget.orderId,
              newStatus: 3, // Delivered
            );

            if (!mounted) return;
            Navigator.of(context, rootNavigator: true).pop(); // dismiss loading

            if (result['success'] == true) {
              QuickAlert.show(
                context: context,
                type: QuickAlertType.success,
                title: 'Received',
                text: 'Order received successfully!',
                onConfirmBtnTap: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  _detailsCubit.fetchOrderDetails(widget.orderId);
                },
              );
            } else {
              QuickAlert.show(
                context: context,
                type: QuickAlertType.error,
                title: 'Error',
                text: result['message'] ?? 'Failed to confirm receipt.',
              );
            }
          },
          label: Text(
            'Confirm Receipt',
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
            'Cancel Order',
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
        color: Colors.white,
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
