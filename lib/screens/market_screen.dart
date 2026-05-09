 
import 'package:flutter/material.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/screens/main_market_screen.dart';
import 'package:root2route/screens/product/my_products_screen.dart';
import 'package:root2route/screens/auction/public_auctions_screen.dart';

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
        backgroundColor: const Color(0xFFF4F6F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          centerTitle: true,
          title: const Text(
            'Marketplace',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Market', icon: Icon(Icons.storefront)),
              Tab(text: 'My store', icon: Icon(Icons.inventory_2_outlined)),
              Tab(text: 'Auctions', icon: Icon(Icons.gavel)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
             MainMarketTab(organizationId: widget.organizationId),
            MyProductsScreen(organizationId: widget.organizationId ?? ''),
            const PublicAuctionsScreen(),
          ],
        ),
      ),
    );
  }
}
