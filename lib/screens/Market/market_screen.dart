import 'package:flutter/material.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/screens/Market/auctions_screen.dart';
import 'package:root2route/screens/Market/direct_market_screen.dart';
import 'package:root2route/screens/my_products_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 62,
        title: const Text(
          'Marketplace',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey.shade500,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              indicatorSize: TabBarIndicatorSize.label,
              indicator: _RoundedTabIndicator(color: AppColors.primary),
              tabs: const [
                Tab(text: 'Market'),
                Tab(text: 'Auctions'),
                Tab(text: 'My Store'),
              ],
            ),
          ),
        ),
      ),
      // Use KeepAlive wrapper so each tab preserves its scroll & state
      body: TabBarView(
        controller: _tabController,
        children: const [
          _KeepAliveTab(child: DirectMarketScreen()),
          _KeepAliveTab(child: AuctionsScreen()),
          _KeepAliveTab(child: MyProductsScreen(organizationId: '')),
        ],
      ),
    );
  }
}

// ─── Keep-Alive Wrapper ─────────────────────────────────────────────────────

class _KeepAliveTab extends StatefulWidget {
  final Widget child;
  const _KeepAliveTab({required this.child});

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// ─── Custom Rounded Tab Indicator ──────────────────────────────────────────

class _RoundedTabIndicator extends Decoration {
  final Color color;
  const _RoundedTabIndicator({required this.color});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _RoundedIndicatorPainter(color: color, onChange: onChanged);
  }
}

class _RoundedIndicatorPainter extends BoxPainter {
  final Color color;
  _RoundedIndicatorPainter({required this.color, VoidCallback? onChange})
    : super(onChange);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Paint paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    const double indicatorHeight = 3.0;
    const double radius = 3.0;

    final Rect rect = Rect.fromLTWH(
      offset.dx,
      offset.dy + (configuration.size?.height ?? 0) - indicatorHeight,
      configuration.size?.width ?? 0,
      indicatorHeight,
    );

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(radius),
        topRight: const Radius.circular(radius),
      ),
      paint,
    );
  }
}
