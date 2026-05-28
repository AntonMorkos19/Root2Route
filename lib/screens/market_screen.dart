import 'package:flutter/material.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/screens/main_market_screen.dart';
import 'package:root2route/screens/product/my_products_screen.dart';
import 'package:root2route/screens/auction/auctions_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/features/notifications/cubit/notification_cubit.dart';
import 'package:root2route/features/notifications/cubit/notification_state.dart';
import 'package:root2route/screens/notifications_screen.dart';
import 'package:root2route/screens/order/cart_screen.dart';
import 'package:root2route/screens/chat/chat_rooms_screen.dart';
import 'package:root2route/features/chat/cubit/chat_rooms_cubit.dart';
import 'package:root2route/services/chat_service.dart';
import 'package:root2route/features/cart/cubit/cart_cubit.dart';
import 'package:root2route/features/cart/cubit/cart_state.dart';

class MarketScreen extends StatefulWidget {
  final String? organizationId;

  const MarketScreen({super.key, this.organizationId});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  @override
  Widget build(BuildContext context) {
    const int tabLength = 3;

    return DefaultTabController(
      length: tabLength,
      child: Scaffold(
        appBar: AppBar(
          elevation: 1,
          title: const Text(
            'Marketplace',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
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
                    child: const Icon(Icons.shopping_cart_outlined),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => BlocProvider(
                          create: (_) => ChatRoomsCubit(ChatService()),
                          child: const ChatRoomsScreen(),
                        ),
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
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      ),
                  icon: Badge(
                    isLabelVisible: unreadCount > 0,
                    label: Text(unreadCount.toString()),
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.notifications_active_outlined),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.outline,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'My store', icon: Icon(Icons.inventory_2_outlined)),
              Tab(text: 'Auctions', icon: Icon(Icons.gavel)),
              Tab(text: 'Market', icon: Icon(Icons.storefront)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            MyProductsScreen(organizationId: widget.organizationId ?? ''),
            const AuctionsScreen(),
            MainMarketTab(organizationId: widget.organizationId),
          ],
        ),
      ),
    );
  }
}
