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
    // 1. Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shopping_cart_checkout_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Confirm Checkout',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Checkout'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // 2. Show loading
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
      Navigator.pop(context); // dismiss loading

      if (res['success'] == true) {
        await QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          title: 'Checkout Complete!',
          text: res['message'] ?? 'Your order has been placed successfully.',
          confirmBtnText: 'Great',
          confirmBtnColor: AppColors.primary,
        );
        _fetchWon(); // refresh won list
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
      Navigator.pop(context); // dismiss loading
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, Color(0xFF1B5E20)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.receipt_long_rounded,
                                  color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'My Auctions',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Track your bids and claim your wins',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(
                    icon: Icon(Icons.how_to_vote_rounded, size: 18),
                    text: 'Participated'),
                Tab(
                    icon: Icon(Icons.emoji_events_rounded, size: 18),
                    text: 'Won'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // ── Participated Tab ──
            _buildListTab(
              data: _participated,
              isLoading: _loadingParticipated,
              error: _participatedError,
              onRefresh: _fetchParticipated,
              emptyIcon: Icons.how_to_vote_rounded,
              emptyTitle: 'No Participated Auctions',
              emptySubtitle:
                  'Auctions you bid on will appear here.',
              cardBuilder: (auction) =>
                  _ParticipatedAuctionCard(auction: auction),
            ),
            // ── Won Tab ──
            _buildListTab(
              data: _won,
              isLoading: _loadingWon,
              error: _wonError,
              onRefresh: _fetchWon,
              emptyIcon: Icons.emoji_events_rounded,
              emptyTitle: 'No Won Auctions',
              emptySubtitle: 'Your winning auctions will show up here.',
              cardBuilder: (auction) => _WonAuctionCard(
                auction: auction,
                onCheckout: _handleCheckout,
              ),
            ),
          ],
        ),
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

// ─── Helper: resolve image URL ────────────────────────────────────────────────

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
  return auction['title'] ??
      auction['Title'] ??
      auction['name'] ??
      auction['Name'] ??
      auction['productName'] ??
      auction['ProductName'] ??
      'Auction';
}

Widget _imagePlaceholder({double size = 48}) {
  return Container(
    color: const Color(0xFFF0F4F0),
    child: Center(
      child: Icon(Icons.image_outlined, size: size, color: Colors.grey),
    ),
  );
}

// ─── Participated Auction Card ────────────────────────────────────────────────

class _ParticipatedAuctionCard extends StatelessWidget {
  final dynamic auction;

  const _ParticipatedAuctionCard({required this.auction});

  @override
  Widget build(BuildContext context) {
    final title = _resolveTitle(auction);
    final displayUrl = _resolveImageUrl(auction);

    final rawBid = auction['currentBid'] ??
        auction['CurrentBid'] ??
        auction['highestBid'] ??
        auction['HighestBid'] ??
        auction['currentHighestBid'] ??
        auction['reservePrice'] ??
        auction['ReservePrice'] ??
        0;
    final currentBid = double.tryParse(rawBid.toString()) ?? 0.0;

    final status = auction['status'] ??
        auction['Status'] ??
        auction['auctionStatus'] ??
        '';
    final statusStr = status.toString().toLowerCase();

    Color statusColor;
    String statusLabel;
    if (statusStr.contains('active') || statusStr.contains('live')) {
      statusColor = Colors.green;
      statusLabel = 'LIVE';
    } else if (statusStr.contains('ended') || statusStr.contains('completed')) {
      statusColor = Colors.grey;
      statusLabel = 'ENDED';
    } else if (statusStr.contains('upcoming') ||
        statusStr.contains('pending')) {
      statusColor = Colors.orange;
      statusLabel = 'UPCOMING';
    } else {
      statusColor = Colors.blueGrey;
      statusLabel = status.toString().toUpperCase();
      if (statusLabel.isEmpty) statusLabel = 'UNKNOWN';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(20)),
            child: SizedBox(
              width: 110,
              height: 120,
              child: displayUrl != null && displayUrl.isNotEmpty
                  ? Image.network(displayUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(size: 32))
                  : _imagePlaceholder(size: 32),
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (statusLabel == 'LIVE')
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.circle,
                                size: 6, color: statusColor),
                          ),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Highest Bid',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                  Text(
                    currentBid > 0
                        ? 'EGP ${currentBid.toStringAsFixed(0)}'
                        : 'No bids yet',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: currentBid > 0
                          ? AppColors.primary
                          : Colors.grey.shade400,
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

// ─── Won Auction Card ─────────────────────────────────────────────────────────

class _WonAuctionCard extends StatelessWidget {
  final dynamic auction;
  final Future<void> Function(String auctionId, String title) onCheckout;

  const _WonAuctionCard({
    required this.auction,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final title = _resolveTitle(auction);
    final displayUrl = _resolveImageUrl(auction);

    final rawPrice = auction['finalPrice'] ??
        auction['FinalPrice'] ??
        auction['winningBid'] ??
        auction['WinningBid'] ??
        auction['winningPrice'] ??
        auction['currentBid'] ??
        auction['reservePrice'] ??
        0;
    final winningPrice = double.tryParse(rawPrice.toString()) ?? 0.0;

    final auctionId = (auction['id'] ?? auction['Id'] ?? auction['auctionId'] ?? '')
        .toString();

    final checkoutStatus =
        (auction['checkoutStatus'] ?? auction['CheckoutStatus'] ?? '')
            .toString()
            .toLowerCase();
    final isCheckedOut = checkoutStatus.contains('completed') ||
        checkoutStatus.contains('paid') ||
        checkoutStatus.contains('done');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + Winner badge
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: SizedBox(
                  width: double.infinity,
                  height: 160,
                  child: displayUrl != null && displayUrl.isNotEmpty
                      ? Image.network(displayUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder())
                      : _imagePlaceholder(),
                ),
              ),
              // Winner badge
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFC107).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events_rounded,
                          size: 14, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        'WON',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isCheckedOut)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'PAID',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          // Info + Checkout
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Winning Price',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            winningPrice > 0
                                ? 'EGP ${winningPrice.toStringAsFixed(0)}'
                                : '—',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isCheckedOut)
                      ElevatedButton.icon(
                        onPressed: () => onCheckout(auctionId, title),
                        icon: const Icon(
                            Icons.shopping_cart_checkout_rounded,
                            size: 16),
                        label: const Text(
                          'Checkout',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                          shadowColor: AppColors.primary.withOpacity(0.4),
                        ),
                      ),
                    if (isCheckedOut)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded,
                                size: 16, color: Colors.grey.shade500),
                            const SizedBox(width: 6),
                            Text(
                              'Completed',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Helper Widgets ────────────────────────────────────────────────────

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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 52, color: AppColors.primary.withOpacity(0.5)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 60, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
