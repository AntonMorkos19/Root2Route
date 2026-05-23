import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/models/auction_model.dart';
import 'package:root2route/services/api.dart';
import 'package:root2route/screens/auction/auction_details_screen.dart';
import 'package:root2route/components/auction_card.dart';
import 'package:root2route/screens/auction/buyer_auctions_screen.dart';

class AuctionsScreen extends StatefulWidget {
  static const String id = '/AuctionsScreen';
  final bool isGuestMode;

  const AuctionsScreen({super.key, this.isGuestMode = false});

  @override
  State<AuctionsScreen> createState() => _AuctionsScreenState();
}

class _AuctionsScreenState extends State<AuctionsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;

  List<dynamic> _liveAuctions = [];
  List<dynamic> _endedAuctions = [];
  Map<String, dynamic> _productDataMap = {};

  bool _loadingLive = true;
  bool _loadingEnded = true;

  String? _liveError;
  String? _endedError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchLive();
    _fetchEnded();
    _fetchAllProductsForImages();
  }

  Future<void> _fetchAllProductsForImages() async {
    try {
      final res = await _api.getAllProducts(pageSize: 1000);
      if (mounted && res['success'] == true) {
        final List<dynamic> products = res['data'] ?? [];
        final Map<String, dynamic> productMap = {};
        for (var p in products) {
          final id = (p['id'] ?? p['Id'])?.toString();
          if (id != null) productMap[id] = p;
        }
        if (mounted) {
          setState(() {
            _productDataMap = productMap;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchLive() async {
    setState(() {
      _loadingLive = true;
      _liveError = null;
    });
    try {
      final res = await _api.getActiveAuctions();
      if (!mounted) return;
      if (res['success'] == true) {
        final data = res['data'];
        final List<dynamic> allAuctions = data is List ? data : [];

        setState(() {
          _liveAuctions =
              allAuctions.where((a) {
                final status = a['status']?.toString().toLowerCase();
                return status == 'ongoing' ||
                    status == 'active' ||
                    status == '1';
              }).toList();

          _loadingLive = false;
        });
      } else {
        setState(() {
          _liveError = res['message'] ?? 'Failed to load live auctions.';
          _loadingLive = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _liveError = e.toString();
        _loadingLive = false;
      });
    }
  }

  Future<void> _fetchEnded() async {
    setState(() {
      _loadingEnded = true;
      _endedError = null;
    });
    try {
      final res = await _api.getCompletedAuctions();
      if (!mounted) return;
      if (res['success'] == true) {
        final data = res['data'];
        setState(() {
          _endedAuctions = data is List ? data : [];
          _loadingEnded = false;
        });
      } else {
        setState(() {
          _endedError = res['message'] ?? 'Failed to load ended auctions.';
          _loadingEnded = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _endedError = e.toString();
        _loadingEnded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isGuestMode) ...[
              GestureDetector(
                onTap:
                    () => Navigator.pushNamed(context, BuyerAuctionsScreen.id),
                child: Container(
                  margin: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.09),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: const Icon(
                          Icons.gavel_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'My Auctions',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Track your bids and active auctions',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.primary,
                        size: 14.w,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
            Padding(
              padding: EdgeInsets.only(
                left: 16.w,
                right: 16.w,
                top: widget.isGuestMode ? 16.h : 0,
              ),
              child: Text(
                'Current Activity',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, Color(0xFF1B5E20)],
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
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
                              child: const Icon(
                                Icons.gavel_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Auction Marketplace',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Discover and bid on fresh agricultural products',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.flash_on_rounded, size: 18),
                        text: 'Live Auctions',
                      ),
                      Tab(
                        icon: Icon(Icons.history_rounded, size: 18),
                        text: 'Ended',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _LiveAuctionsTab(
                    auctions: _liveAuctions,
                    productDataMap: _productDataMap,
                    isLoading: _loadingLive,
                    error: _liveError,
                    onRefresh: _fetchLive,
                    isGuestMode: widget.isGuestMode,
                  ),
                  _EndedAuctionsTab(
                    auctions: _endedAuctions,
                    productDataMap: _productDataMap,
                    isLoading: _loadingEnded,
                    error: _endedError,
                    onRefresh: _fetchEnded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveAuctionsTab extends StatelessWidget {
  final List<dynamic> auctions;
  final Map<String, dynamic> productDataMap;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onRefresh;

  final bool isGuestMode;

  const _LiveAuctionsTab({
    required this.auctions,
    required this.productDataMap,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
    this.isGuestMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (error != null) {
      return _ErrorState(message: error!, onRetry: onRefresh);
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child:
          auctions.isEmpty
              ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: _EmptyState(
                      icon: Icons.flash_on_rounded,
                      title: 'No Live Auctions',
                      subtitle:
                          'Check back soon — new auctions are added regularly.',
                      onRefresh: onRefresh,
                    ),
                  ),
                ],
              )
              : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                itemCount: auctions.length,
                itemBuilder: (context, index) {
                  final auctionData = auctions[index];
                  final auction = AuctionModel.fromJson(auctionData);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AuctionCard(
                      auction: auction,
                      productData: productDataMap[auction.productId],
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AuctionDetailsScreen.id,
                          arguments: auction,
                        );
                      },
                      onBid:
                          isGuestMode
                              ? null
                              : () {
                                Navigator.pushNamed(
                                  context,
                                  AuctionDetailsScreen.id,
                                  arguments: auction,
                                );
                              },
                      onViewBids: () {
                        Navigator.pushNamed(
                          context,
                          AuctionDetailsScreen.id,
                          arguments: auction,
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}

class _EndedAuctionsTab extends StatelessWidget {
  final List<dynamic> auctions;
  final Map<String, dynamic> productDataMap;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onRefresh;

  const _EndedAuctionsTab({
    required this.auctions,
    required this.productDataMap,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (error != null) {
      return _ErrorState(message: error!, onRetry: onRefresh);
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child:
          auctions.isEmpty
              ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: _EmptyState(
                      icon: Icons.history_rounded,
                      title: 'No Ended Auctions',
                      subtitle: 'Completed auctions will appear here.',
                      onRefresh: onRefresh,
                    ),
                  ),
                ],
              )
              : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                itemCount: auctions.length,
                itemBuilder: (context, index) {
                  final auctionData = auctions[index];
                  final auction = AuctionModel.fromJson(auctionData);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AuctionCard(
                      auction: auction,
                      productData: productDataMap[auction.productId],
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AuctionDetailsScreen.id,
                          arguments: auction,
                        );
                      },
                      onViewResult: () {
                        Navigator.pushNamed(
                          context,
                          AuctionDetailsScreen.id,
                          arguments: auction,
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onRefresh;

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
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
