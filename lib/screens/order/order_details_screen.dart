import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/models/order_model.dart';
import 'package:root2route/services/order_service.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final OrderService _orderService = OrderService();
  bool _isLoading = true;
  String? _errorMessage;
  OrderModel? _order;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _orderService.getOrderDetails(widget.orderId);

    if (!mounted) return;

    if (result['success'] == true && result['data'] != null) {
      setState(() {
        _order = result['data'] as OrderModel;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Failed to load order details';
        _isLoading = false;
      });
    }
  }

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
        Navigator.pop(context); // Close confirm dialog

        QuickAlert.show(
          context: context,
          type: QuickAlertType.loading,
          title: 'Cancelling...',
          barrierDismissible: false,
        );

        final result = await _orderService.cancelOrder(widget.orderId);

        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop(); // Close loading

        if (result['success'] == true || (result['message']?.toString().contains('Cancelled') ?? false)) {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            title: result['success'] == true ? 'Order Cancelled' : 'Note',
            text: result['success'] == true 
                ? 'Your order has been cancelled successfully.'
                : 'This order was already cancelled.',
            onConfirmBtnTap: () {
              Navigator.pop(context); // Close alert
              _fetchOrderDetails(); // Refresh UI
            },
          );
        } else {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.error,
            title: 'Failed',
            text: result['message'] ?? 'Could not cancel the order.',
          );
        }
      },
    );
  }

  Color _statusColor(int status) {
    switch (status) {
      case 0: return Colors.orange;
      case 1: return Colors.blue;
      case 2: return Colors.indigo;
      case 3: return Colors.green;
      case 4: return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(int status) {
    switch (status) {
      case 0: return Icons.hourglass_empty;
      case 1: return Icons.check_circle_outline;
      case 2: return Icons.local_shipping_outlined;
      case 3: return Icons.done_all;
      case 4: return Icons.cancel_outlined;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Order Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_errorMessage != null || _order == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'Order not found', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchOrderDetails,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
        ),
      );
    }

    final order = _order!;
    final color = _statusColor(order.status);
    final icon = _statusIcon(order.status);
    final dateStr = order.createdAt != null
        ? '${order.createdAt!.day}/${order.createdAt!.month}/${order.createdAt!.year} - ${order.createdAt!.hour}:${order.createdAt!.minute.toString().padLeft(2, '0')}'
        : 'N/A';

    return RefreshIndicator(
      onRefresh: _fetchOrderDetails,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Card
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
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color),
                  ),
                  const SizedBox(height: 4),
                  Text(dateStr, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Shipping Info
            _buildInfoCard(
              title: 'Shipping Information',
              icon: Icons.local_shipping_outlined,
              children: [
                _buildInfoRow('Receiver', order.receiverName ?? 'N/A'),
                _buildInfoRow('Phone', order.receiverPhone ?? 'N/A'),
                _buildInfoRow('City', order.shippingCity ?? 'N/A'),
                _buildInfoRow('Street', order.shippingStreet ?? 'N/A'),
                _buildInfoRow('Building', order.buildingNumber ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 16),

            // Order Items
            _buildInfoCard(
              title: 'Items (${order.items.length})',
              icon: Icons.inventory_2_outlined,
              children: order.items.isEmpty
                  ? [const Text('No items data', style: TextStyle(color: Colors.grey))]
                  : order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item.productName ?? 'Product',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'x${item.quantity}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${item.unitPrice.toStringAsFixed(0)} EGP',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
            ),
            const SizedBox(height: 16),

            // Total
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
                  const Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(
                    '${order.totalAmount.toStringAsFixed(0)} EGP',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Note if exists
            if (order.note != null && order.note!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard(
                title: 'Note',
                icon: Icons.note_outlined,
                children: [Text(order.note!, style: TextStyle(color: Colors.grey.shade700))],
              ),
            ],

            const SizedBox(height: 100), // Space for bottom bar
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
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget? _buildBottomAction() {
    if (_order == null) return null;

    // Only show Cancel button if order is Pending (0) or Confirmed (1)
    if (_order!.status > 1) return null;

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
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _cancelOrder,
            icon: const Icon(Icons.cancel_outlined, color: Colors.white),
            label: const Text(
              'Cancel Order',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }
}
