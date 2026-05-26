import 'package:flutter/material.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/services/api.dart';

class BuyerAuctionsScreen extends StatefulWidget {
  static const String id = '/BuyerAuctionsScreen';

  const BuyerAuctionsScreen({super.key});

  @override
  State<BuyerAuctionsScreen> createState() => _BuyerAuctionsScreenState();
}

class _BuyerAuctionsScreenState extends State<BuyerAuctionsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;

  List<dynamic> _participated = [];
  List<dynamic> _won = [];

  bool _loadingParticipated = true;
  bool _loadingWon = true;

  String? _participatedError;
  String? _wonError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchParticipated();
    _fetchWon();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchParticipated() async {
    setState(() {
      _loadingParticipated = true;
      _participatedError = null;
    });
    try {
      final res = await _api.getMyParticipatedAuctions();
      if (!mounted) return;
      if (res['success'] == true) {
        final data = res['data'];
        setState(() {
          _participated = data is List ? data : [];
          _loadingParticipated = false;
        });
      } else {
        setState(() {
          _participatedError =
              res['message'] ?? 'Failed to load participated auctions.';
          _loadingParticipated = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _participatedError = e.toString();
        _loadingParticipated = false;
      });
    }
  }

  Future<void> _fetchWon() async {
    setState(() {
      _loadingWon = true;
      _wonError = null;
    });
    try {
      final res = await _api.getMyWonAuctions();
      if (!mounted) return;
      if (res['success'] == true) {
        final data = res['data'];
        setState(() {
          _won = data is List ? data : [];
          _loadingWon = false;
        });
      } else {
        setState(() {
          _wonError = res['message'] ?? 'Failed to load won auctions.';
          _loadingWon = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _wonError = e.toString();
        _loadingWon = false;
      });
    }
  }

  Future<void> _handleCheckout(String auctionId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_checkout_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Confirm Checkout',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to checkout "$title"?',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Checkout'),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: 'Processing',
      text: 'Completing checkout...',
      barrierDismissible: false,
    );

    try {
      final res = await _api.checkoutAuction(auctionId);
      if (!mounted) return;
      Navigator.pop(context);

      if (res['success'] == true) {
        await QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          title: 'Checkout Complete!',
          text: res['message'] ?? 'Your order has been placed successfully.',
          confirmBtnText: 'Great',
          confirmBtnColor: AppColors.primary,
        );
        _fetchWon();
      } else {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Checkout Failed',
          text: res['message'] ?? 'Something went wrong. Please try again.',
          confirmBtnText: 'OK',
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: 'An unexpected error occurred: $e',
        confirmBtnText: 'OK',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        toolbarHeight: 100, // زودنا الطول عشان يشيل العنوان والوصف
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
        // 💡 السهم بقى لوحده وواضح
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        // 💡 العنوان والوصف مترتبين تحت بعض
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Auctions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track your bids and claim your wins',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        // 💡 الـ Gradient الجميل بتاعك
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, Color(0xFF1B5E20)],
            ),
          ),
        ),
        // 💡 الـ Tabs ثابتة تحت
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [Tab(text: 'Participated'), Tab(text: 'Won')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListTab(
            data: _participated,
            isLoading: _loadingParticipated,
            error: _participatedError,
            onRefresh: _fetchParticipated,
            emptyIcon: Icons.how_to_vote_rounded,
            emptyTitle: 'No Participated Auctions',
            emptySubtitle: 'Auctions you bid on will appear here.',
            cardBuilder:
                (auction) => _ParticipatedAuctionCard(auction: auction),
          ),
          _buildListTab(
            data: _won,
            isLoading: _loadingWon,
            error: _wonError,
            onRefresh: _fetchWon,
            emptyIcon: Icons.emoji_events_rounded,
            emptyTitle: 'No Won Auctions',
            emptySubtitle: 'Your winning auctions will show up here.',
            cardBuilder:
                (auction) => _WonAuctionCard(
                  auction: auction,
                  onCheckout: _handleCheckout,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTab({
    required List<dynamic> data,
    required bool isLoading,
    required String? error,
    required Future<void> Function() onRefresh,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
    required Widget Function(dynamic) cardBuilder,
  }) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (error != null) {
      return _ErrorState(message: error, onRetry: onRefresh);
    }
    if (data.isEmpty) {
      return _EmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
        onRefresh: onRefresh,
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: data.length,
        itemBuilder: (context, index) => cardBuilder(data[index]),
      ),
    );
  }
}

// ─── الدوال المساعدة والـ Cards (زي ما هي) ──────────────────────────────────────────

String? _resolveImageUrl(dynamic auction) {
  final images =
      auction['images'] ?? auction['Images'] ?? auction['productImages'];
  String? imageUrl;
  if (images is List && images.isNotEmpty) {
    imageUrl = images.first?.toString();
  }
  if (imageUrl != null && imageUrl.startsWith('/')) {
    return 'https://root2route.runasp.net$imageUrl';
  }
  return imageUrl;
}

String _resolveTitle(dynamic auction) {
  return auction['title'] ?? auction['Title'] ?? auction['name'] ?? 'Auction';
}

Widget _imagePlaceholder({double size = 48}) {
  return Container(
    color: const Color(0xFFF0F4F0),
    child: Center(
      child: Icon(Icons.image_outlined, size: size, color: Colors.grey),
    ),
  );
}

class _ParticipatedAuctionCard extends StatelessWidget {
  final dynamic auction;
  const _ParticipatedAuctionCard({required this.auction});

  @override
  Widget build(BuildContext context) {
    final title = _resolveTitle(auction);
    final displayUrl = _resolveImageUrl(auction);
    final rawBid = auction['currentBid'] ?? 0;
    final currentBid = double.tryParse(rawBid.toString()) ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(20),
            ),
            child: SizedBox(
              width: 100,
              height: 100,
              child:
                  displayUrl != null
                      ? Image.network(displayUrl, fit: BoxFit.cover)
                      : _imagePlaceholder(size: 32),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current Bid',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  Text(
                    'EGP ${currentBid.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WonAuctionCard extends StatelessWidget {
  final dynamic auction;
  final Future<void> Function(String auctionId, String title) onCheckout;
  const _WonAuctionCard({required this.auction, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    final title = _resolveTitle(auction);
    final displayUrl = _resolveImageUrl(auction);
    final rawPrice = auction['finalPrice'] ?? 0;
    final winningPrice = double.tryParse(rawPrice.toString()) ?? 0.0;
    final auctionId = (auction['id'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              width: double.infinity,
              height: 140,
              child:
                  displayUrl != null
                      ? Image.network(displayUrl, fit: BoxFit.cover)
                      : _imagePlaceholder(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'EGP ${winningPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => onCheckout(auctionId, title),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Checkout'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Future<void> Function() onRefresh;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          const SizedBox(height: 20),
          OutlinedButton(onPressed: onRefresh, child: const Text('Refresh')),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.redAccent),
          Text(message),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
