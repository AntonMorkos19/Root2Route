import 'package:flutter/material.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/models/order_model.dart';
import 'package:root2route/services/order_service.dart';
import 'package:root2route/services/storage_service.dart';
import 'package:root2route/screens/order/order_details_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final OrderService _orderService = OrderService();

  bool _isLoadingMyOrders = true;
  String? _errorMessageMyOrders;
  List<OrderModel> _myOrders = [];

  bool _isLoadingReceivedOrders = true;
  String? _errorMessageReceivedOrders;
  List<OrderModel> _receivedOrders = [];

  String? _organizationId;

  @override
  void initState() {
    super.initState();
    _organizationId = StorageService().currentUserOrgId;
    _fetchMyOrders();
    if (_organizationId != null && _organizationId!.isNotEmpty) {
      _fetchReceivedOrders();
    } else {
      _isLoadingReceivedOrders = false;
    }
  }

  Future<void> _fetchMyOrders() async {
    setState(() {
      _isLoadingMyOrders = true;
      _errorMessageMyOrders = null;
    });

    final result = await _orderService.getMyOrders();

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _myOrders = result['data'] as List<OrderModel>? ?? [];
        _isLoadingMyOrders = false;
      });
    } else {
      setState(() {
        _errorMessageMyOrders = result['message'] ?? 'Failed to load orders';
        _isLoadingMyOrders = false;
      });
    }
  }

  Future<void> _fetchReceivedOrders() async {
    if (_organizationId == null || _organizationId!.isEmpty) return;

    setState(() {
      _isLoadingReceivedOrders = true;
      _errorMessageReceivedOrders = null;
    });

    final result = await _orderService.getReceivedOrders(_organizationId!);

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _receivedOrders = result['data'] as List<OrderModel>? ?? [];
        _isLoadingReceivedOrders = false;
      });
    } else {
      setState(() {
        _errorMessageReceivedOrders =
            result['message'] ?? 'Failed to load orders';
        _isLoadingReceivedOrders = false;
      });
    }
  }

  Color _statusColor(int status) {
    switch (status) {
      case 0:
        return Colors.orange; // Pending
      case 1:
        return Colors.blue; // Confirmed
      case 2:
        return Colors.indigo; // Shipped
      case 3:
        return Colors.green; // Delivered
      case 4:
        return Colors.red; // Cancelled
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
    final bool hasOrg = _organizationId != null && _organizationId!.isNotEmpty;

    if (!hasOrg) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          title: const Text(
            'My Orders',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.primary,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: _buildMyOrdersTab(),
      );
    }

    return DefaultTabController(
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
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [Tab(text: 'My Orders'), Tab(text: 'Received Orders')],
          ),
        ),
        body: TabBarView(
          children: [_buildMyOrdersTab(), _buildReceivedOrdersTab()],
        ),
      ),
    );
  }

  Widget _buildMyOrdersTab() {
    if (_isLoadingMyOrders) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessageMyOrders != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _errorMessageMyOrders!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchMyOrders,
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

    if (_myOrders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchMyOrders,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No orders yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your placed orders will appear here',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMyOrders,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _myOrders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder:
            (context, index) =>
                _buildOrderCard(_myOrders[index], isSeller: false),
      ),
    );
  }

  Widget _buildReceivedOrdersTab() {
    if (_organizationId == null || _organizationId!.isEmpty) {
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
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'You need a store to receive orders',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    if (_isLoadingReceivedOrders) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessageReceivedOrders != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _errorMessageReceivedOrders!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchReceivedOrders,
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

    if (_receivedOrders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchReceivedOrders,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No received orders',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Customer orders will appear here',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchReceivedOrders,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _receivedOrders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder:
            (context, index) =>
                _buildOrderCard(_receivedOrders[index], isSeller: true),
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, int newStatus) async {
    final result = await _orderService.changeOrderStatus(
      orderId: orderId,
      newStatus: newStatus,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Status updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchMyOrders();
      if (_organizationId != null && _organizationId!.isNotEmpty) {
        _fetchReceivedOrders();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to update status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildOrderCard(OrderModel order, {required bool isSeller}) {
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

    final String formattedTotal = finalTotal.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    List<Widget> actionButtons = [];

    if (!isSeller) {
      if (order.status == 2) {
        // Shipped -> Delivered
        actionButtons.add(
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatus(order.id, 3),
              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
              label: const Text(
                'Confirm Receipt',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
      }
    } else {
      if (order.status == 0) {
        // Pending -> Confirmed or Cancelled
        actionButtons.add(
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _updateOrderStatus(order.id, 1),
                  icon: const Icon(Icons.check, color: Colors.white, size: 18),
                  label: const Text(
                    'Accept',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _updateOrderStatus(order.id, 4),
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  label: const Text(
                    'Reject',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      } else if (order.status == 1) {
        // Confirmed -> Shipped
        actionButtons.add(
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _updateOrderStatus(order.id, 2),
              icon: const Icon(Icons.local_shipping, color: Colors.white),
              label: const Text(
                'Mark as Shipped',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        );
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailsScreen(orderId: order.id),
          ),
        ).then((_) {
          _fetchMyOrders();
          if (_organizationId != null && _organizationId!.isNotEmpty) {
            _fetchReceivedOrders();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.items.isNotEmpty
                        ? order.items.first.productName
                        : 'No product',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: color),
                      const SizedBox(width: 4),
                      Text(
                        order.statusText,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shopping_basket_outlined,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      order.items.isNotEmpty
                          ? 'Quantity: ${order.items.first.quantity}'
                          : '1 item',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                if (dateStr.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.items.length} item${order.items.length != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                Text(
                  '$formattedTotal EGP',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            if (actionButtons.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...actionButtons,
            ],
          ],
        ),
      ),
    );
  }
}
