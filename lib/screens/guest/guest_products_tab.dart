import 'package:flutter/material.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/screens/main_market_screen.dart';
import 'package:root2route/screens/auction/public_auctions_screen.dart';
import 'package:root2route/screens/order/my_orders_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/features/notifications/cubit/notification_cubit.dart';
import 'package:root2route/features/notifications/cubit/notification_state.dart';
import 'package:root2route/screens/notifications_screen.dart';
import 'package:root2route/screens/order/cart_screen.dart';
import 'package:root2route/features/cart/cubit/cart_cubit.dart';
import 'package:root2route/features/cart/cubit/cart_state.dart';

/// A Products tab used exclusively in the Guest navigation flow.
/// It provides 3 sub-tabs: Market, Auctions, and My Orders — all in
/// view-only / read mode (action buttons are hidden for guests).
class GuestProductsTab extends StatelessWidget {
  const GuestProductsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          centerTitle: true,
          title: const Text(
            'Products',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          actions: [
            BlocBuilder<CartCubit, CartState>(
              builder: (context, state) {
                final cartCount = state.cartItems.length;
                return IconButton(
                  onPressed: () => Navigator.pushNamed(context, CartScreen.id),
                  icon: Badge(
                    isLabelVisible: cartCount > 0,
                    label: Text(cartCount.toString()),
                    backgroundColor: AppColors.primary,
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.black87,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: Colors.black87),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('يرجى تسجيل الدخول أولاً لاستخدام المحادثات'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
            BlocBuilder<NotificationCubit, NotificationState>(
              builder: (context, state) {
                int unreadCount = 0;
                if (state is NotificationLoaded) {
                  unreadCount = state.unreadCount;
                }
                return IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                  icon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text(unreadCount.toString()),
                    backgroundColor: Colors.red,
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      color: Colors.black87,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'Market', icon: Icon(Icons.storefront_outlined, size: 20)),
              Tab(text: 'Auctions', icon: Icon(Icons.gavel_rounded, size: 20)),
              Tab(text: 'My Orders', icon: Icon(Icons.receipt_long_outlined, size: 20)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Market — FAB is hidden via isGuestMode flag
            MainMarketTab(isGuestMode: true),
            // Auctions — Bid button hidden via isGuestMode flag
            PublicAuctionsScreen(isGuestMode: true),
            // My Orders — guest mode skips the Received Orders tab entirely
            MyOrdersScreen(isGuestMode: true),
          ],
        ),
      ),
    );
  }
}
