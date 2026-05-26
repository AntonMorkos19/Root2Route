import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/features/orders/cubit/my_orders_cubit.dart';
import 'package:root2route/features/orders/cubit/order_state.dart';
import 'package:root2route/features/orders/cubit/received_orders_cubit.dart';
import 'package:root2route/features/shipments/cubit/dispatch_cubit.dart';
import 'package:root2route/features/shipments/cubit/shipment_state.dart';
import 'package:root2route/models/order_model.dart';
import 'package:root2route/services/order_service.dart';
import 'package:root2route/services/storage_service.dart';
import 'package:root2route/screens/order/order_details_screen.dart';
import 'package:root2route/features/shipments/widgets/dispatch_bottom_sheet.dart';
import 'package:root2route/features/reviews/ui/add_review_dialog.dart';

class MyOrdersScreen extends StatefulWidget {
  final bool isGuestMode;

  const MyOrdersScreen({super.key, this.isGuestMode = false});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  late final MyOrdersCubit _myOrdersCubit;
  late final ReceivedOrdersCubit _receivedOrdersCubit;
  late final DispatchCubit _dispatchCubit;
  final OrderService _orderService = OrderService();
  String? _organizationId;

  @override
  void initState() {
    super.initState();
    _organizationId = StorageService().currentUserOrgId;
    debugPrint('[MyOrdersScreen] organizationId = $_organizationId');

    _myOrdersCubit = MyOrdersCubit()..fetchMyOrders();
    _receivedOrdersCubit = ReceivedOrdersCubit();
    _dispatchCubit = DispatchCubit();

    if (!widget.isGuestMode &&
        _organizationId != null &&
        _organizationId!.isNotEmpty) {
      _receivedOrdersCubit.fetchReceivedOrders(_organizationId!);
    }
  }

  @override
  void dispose() {
    _myOrdersCubit.close();
    _receivedOrdersCubit.close();
    _dispatchCubit.close();
    super.dispose();
  }

  // ── Status mutation shared by both tabs ───────────────────────────────────

  Future<void> _updateOrderStatus(
    BuildContext ctx,
    String orderId,
    int newStatus,
  ) async {
    QuickAlert.show(
      context: ctx,
      type: QuickAlertType.loading,
      title: 'Updating...',
      text: 'Please wait',
    );

    final result = await _orderService.changeOrderStatus(
      orderId: orderId,
      newStatus: newStatus,
    );

    if (!mounted) return;
    Navigator.of(ctx, rootNavigator: true).pop();

    if (result['success'] == true) {
      QuickAlert.show(
        context: ctx,
        type: QuickAlertType.success,
        title: 'Success',
        text: result['message'] ?? 'Status updated successfully',
        onConfirmBtnTap: () {
          Navigator.of(ctx, rootNavigator: true).pop();
          _myOrdersCubit.fetchMyOrders();
          if (_organizationId != null && _organizationId!.isNotEmpty) {
            _receivedOrdersCubit.fetchReceivedOrders(_organizationId!);
          }
        },
      );
    } else {
      QuickAlert.show(
        context: ctx,
        type: QuickAlertType.error,
        title: 'Error',
        text: result['message'] ?? 'Failed to update status',
      );
    }
  }

  void _onOrderCardTap(BuildContext ctx, String orderId, bool isSellerView) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder:
            (_) => OrderDetailsScreen(
              orderId: orderId,
              isSellerView: isSellerView,
            ),
      ),
    ).then((_) {
      _myOrdersCubit.fetchMyOrders();
      if (_organizationId != null && _organizationId!.isNotEmpty) {
        _receivedOrdersCubit.fetchReceivedOrders(_organizationId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ── Guest mode: buyer-only order list, no tab toggle ──────────────────
    if (widget.isGuestMode) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        body: _MyOrdersTab(
          cubit: _myOrdersCubit,
          onUpdateStatus:
              (orderId, status) => _updateOrderStatus(context, orderId, status),
          onOrderTap: (orderId) => _onOrderCardTap(context, orderId, false),
        ),
      );
    }

    return BlocProvider<DispatchCubit>.value(
      value: _dispatchCubit,
      child: BlocListener<DispatchCubit, ShipmentState>(
        listener: (context, state) {
          if (state is ShipmentLoading) {
            QuickAlert.show(
              context: context,
              type: QuickAlertType.loading,
              title: 'Sending...',
              text: 'Please wait',
            );
          } else if (state is ShipmentActionSuccess) {
            Navigator.of(context, rootNavigator: true).pop();
            QuickAlert.show(
              context: context,
              type: QuickAlertType.success,
              title: 'Success',
              text: state.message,
              onConfirmBtnTap: () {
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).pop(); // Close the QuickAlert

                if (_organizationId != null) {
                  _receivedOrdersCubit.fetchReceivedOrders(_organizationId!);
                } else {
                  debugPrint(
                    "Warning: _organizationId is null. Cannot refresh orders automatically.",
                  );
                }
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
        child: DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: const Color(0xFFF4F6F9),
            appBar: AppBar(
              title: const Text(
                'Orders',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppColors.primary,
              elevation: 0,
              automaticallyImplyLeading: false,
              bottom: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16.sp,
                ),

                tabs: const [
                  Tab(text: 'My Orders'),
                  Tab(text: 'Received Orders'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _MyOrdersTab(
                  cubit: _myOrdersCubit,
                  onUpdateStatus:
                      (orderId, status) =>
                          _updateOrderStatus(context, orderId, status),
                  onOrderTap:
                      (orderId) => _onOrderCardTap(context, orderId, false),
                ),
                _ReceivedOrdersTab(
                  cubit: _receivedOrdersCubit,
                  organizationId: _organizationId,
                  onUpdateStatus:
                      (orderId, status) =>
                          _updateOrderStatus(context, orderId, status),
                  onOrderTap:
                      (orderId) => _onOrderCardTap(context, orderId, true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MyOrdersTab extends StatefulWidget {
  final MyOrdersCubit cubit;
  final void Function(String orderId, int status) onUpdateStatus;
  final void Function(String orderId) onOrderTap;

  const _MyOrdersTab({
    required this.cubit,
    required this.onUpdateStatus,
    required this.onOrderTap,
  });

  @override
  State<_MyOrdersTab> createState() => _MyOrdersTabState();
}

class _MyOrdersTabState extends State<_MyOrdersTab>
    with AutomaticKeepAliveClientMixin {
  String _filter = 'All';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<MyOrdersCubit, OrderState>(
      bloc: widget.cubit,
      buildWhen:
          (previous, current) =>
              current is OrderInitial ||
              current is OrderLoading ||
              current is OrderListLoaded ||
              current is OrderError,
      builder: (context, state) {
        if (state is OrderInitial || state is OrderLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is OrderError) {
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
                    onPressed: () => widget.cubit.fetchMyOrders(),
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

        final List<OrderModel> orders =
            state is OrderListLoaded ? state.orders : const [];

        final filteredOrders =
            orders.where((o) {
              if (_filter == 'Active')
                return o.status == 0 || o.status == 1 || o.status == 2;
              if (_filter == 'History') return o.status == 3 || o.status == 4;
              return true;
            }).toList();

        return Column(
          children: [
            _FilterChips(
              currentFilter: _filter,
              onChanged: (val) => setState(() => _filter = val),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => widget.cubit.fetchMyOrders(),
                color: AppColors.primary,
                child:
                    filteredOrders.isEmpty
                        ? _EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No orders found',
                          subtitle: 'Your placed orders will appear here',
                        )
                        : ListView.separated(
                          padding: EdgeInsets.all(16.w),
                          itemCount: filteredOrders.length,
                          separatorBuilder: (_, __) => SizedBox(height: 12.h),
                          itemBuilder:
                              (context, index) => _OrderCard(
                                order: filteredOrders[index],
                                isSeller: false,
                                onUpdateStatus: widget.onUpdateStatus,
                                onTap: widget.onOrderTap,
                              ),
                        ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReceivedOrdersTab extends StatefulWidget {
  final ReceivedOrdersCubit cubit;
  final String? organizationId;
  final void Function(String orderId, int status) onUpdateStatus;
  final void Function(String orderId) onOrderTap;

  const _ReceivedOrdersTab({
    required this.cubit,
    required this.organizationId,
    required this.onUpdateStatus,
    required this.onOrderTap,
  });

  @override
  State<_ReceivedOrdersTab> createState() => _ReceivedOrdersTabState();
}

class _ReceivedOrdersTabState extends State<_ReceivedOrdersTab>
    with AutomaticKeepAliveClientMixin {
  String _filter = 'All';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin

    // Guard: no organization — show static UI without touching any cubit.
    if (widget.organizationId == null || widget.organizationId!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Organization',
              style: TextStyle(fontSize: 20.sp, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'You need a store to receive orders',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    // ── Strictly bound to ReceivedOrdersCubit only ────────────────────────
    return BlocConsumer<ReceivedOrdersCubit, OrderState>(
      bloc: widget.cubit, // explicit binding — never resolves via context
      buildWhen:
          (previous, current) =>
              current is OrderInitial ||
              current is OrderLoading ||
              current is OrderListLoaded ||
              current is OrderError,
      listenWhen: (previous, current) => current is OrderError,
      listener: (context, state) {
        if (state is OrderError) {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.error,
            title: 'Error',
            text: state.message,
          );
        }
      },
      builder: (context, state) {
        if (state is OrderInitial || state is OrderLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (state is OrderError) {
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
                    onPressed:
                        () => widget.cubit.fetchReceivedOrders(
                          widget.organizationId!,
                        ),
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

        // Extract list strictly from this cubit's state — never shared.
        final List<OrderModel> orders =
            state is OrderListLoaded ? state.orders : const [];

        final filteredOrders =
            orders.where((o) {
              if (_filter == 'Active')
                return o.status == 0 || o.status == 1 || o.status == 2;
              if (_filter == 'History') return o.status == 3 || o.status == 4;
              return true;
            }).toList();

        return Column(
          children: [
            _FilterChips(
              currentFilter: _filter,
              onChanged: (val) => setState(() => _filter = val),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh:
                    () => widget.cubit.fetchReceivedOrders(
                      widget.organizationId!,
                    ),
                color: AppColors.primary,
                child:
                    filteredOrders.isEmpty
                        ? _EmptyState(
                          icon: Icons.inbox_outlined,
                          title: 'No received orders found',
                          subtitle: 'Customer orders will appear here',
                        )
                        : ListView.separated(
                          padding: EdgeInsets.all(16.w),
                          itemCount: filteredOrders.length,
                          separatorBuilder: (_, __) => SizedBox(height: 12.h),
                          itemBuilder:
                              (context, index) => _OrderCard(
                                order: filteredOrders[index],
                                isSeller: true,
                                onUpdateStatus: widget.onUpdateStatus,
                                onTap: widget.onOrderTap,
                              ),
                        ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared pure UI widgets (no cubit access)
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final String currentFilter;
  final void Function(String) onChanged;

  const _FilterChips({required this.currentFilter, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          _chip('All'),
          SizedBox(width: 8.w),
          _chip('Active'),
          SizedBox(width: 8.w),
          _chip('History'),
        ],
      ),
    );
  }

  Widget _chip(String label) {
    final isSelected = currentFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) onChanged(label);
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        fontSize: 14.sp,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        color: isSelected ? AppColors.primary : Colors.black87,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 20.sp, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Order card — pure UI, receives data and callbacks only, no cubit access.
// ─────────────────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final bool isSeller;
  final void Function(String orderId, int status) onUpdateStatus;
  final void Function(String orderId) onTap;

  const _OrderCard({
    required this.order,
    required this.isSeller,
    required this.onUpdateStatus,
    required this.onTap,
  });

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

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(order.status);
    final icon = _statusIcon(order.status);
    final dateStr =
        order.createdAt != null
            ? '${order.createdAt!.day}/${order.createdAt!.month}/${order.createdAt!.year}'
            : '';

    final double finalTotal =
        order.totalAmount > 0
            ? order.totalAmount
            : order.items.fold(0.0, (sum, item) => sum + item.totalPrice);

    final String formattedTotal = finalTotal
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );

    final List<Widget> actionButtons = _buildActionButtons(context);

    return GestureDetector(
      onTap: () => onTap(order.id),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
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
            // ── Header row ──────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.items.isNotEmpty
                        ? order.items.first.productName
                        : 'No product',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14.w, color: color),
                      SizedBox(width: 4.w),
                      Text(
                        order.statusText,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            const Divider(height: 1),
            SizedBox(height: 12.h),
            // ── Quantity + date row ──────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shopping_basket_outlined,
                      size: 16.w,
                      color: Colors.grey.shade600,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      order.items.isNotEmpty
                          ? 'Quantity: ${order.items.first.quantity} kg'
                          : '${order.items.length} item${order.items.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (dateStr.isNotEmpty)
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8.h),
            // ── Items count + total row ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.items.length} item${order.items.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '$formattedTotal EGP',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            // ── Action buttons ───────────────────────────────────────────
            if (actionButtons.isNotEmpty) ...[
              SizedBox(height: 16.h),
              ...actionButtons,
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(BuildContext context) {
    final buttons = <Widget>[];

    if (!isSeller) {
      // Buyer: confirm receipt when shipped
      if (order.status == 2) {
        buttons.add(
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => onUpdateStatus(order.id, 3),
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: Text(
                'Confirm Receipt',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
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
          ),
        );
      }
      // Buyer: rate & review when delivered
      if (order.status == 3) {
        buttons.add(
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                if (order.items.isEmpty) {
                  QuickAlert.show(
                    context: context,
                    type: QuickAlertType.warning,
                    title: 'Oops',
                    text: 'No products found in this order to review.',
                  );
                  return;
                }
                showDialog(
                  context: context,
                  builder:
                      (context) => AddReviewDialog(
                        targetOrganizationId: order.organizationId,
                        orderId: order.id,
                        productId: order.items.first.productId,
                      ),
                );
              },
              icon: const Icon(
                Icons.star_outline_rounded,
                color: AppColors.primary,
              ),
              label: Text(
                'Rate & Review',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  color: AppColors.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        );
      }
    } else {
      // Seller: accept/reject when pending
      if (order.status == 0) {
        buttons.add(
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onUpdateStatus(order.id, 1),
                  icon: const Icon(Icons.check, color: Colors.white, size: 18),
                  label: Text(
                    'Accept',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
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
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onUpdateStatus(order.id, 4),
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  label: Text(
                    'Reject',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      // Seller: mark as shipped when confirmed
      else if (order.status == 1) {
        buttons.add(
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  () => showDispatchBottomSheet(
                    context,
                    orderId: order.id,
                    dispatchCubit: context.read<DispatchCubit>(),
                  ),
              icon: const Icon(Icons.local_shipping, color: Colors.white),
              label: Text(
                'Mark as Shipped',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
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
          ),
        );
      }
    }

    return buttons;
  }
}
