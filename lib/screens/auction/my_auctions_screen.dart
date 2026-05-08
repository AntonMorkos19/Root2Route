import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/features/auctions/cubit/auction_cubit.dart';
import 'package:root2route/features/auctions/cubit/auction_state.dart';
import 'package:root2route/models/auction_model.dart';
import 'package:root2route/screens/auction/bid_history_screen.dart';
 import 'package:root2route/components/auction_card.dart';
import 'package:root2route/screens/auction/update_auction_screen.dart';
import 'package:root2route/screens/auction/auction_details_screen.dart';
import 'package:root2route/services/storage_service.dart';
import 'package:root2route/screens/auth/login_screen.dart';

class MyAuctionsScreen extends StatefulWidget {
  static const String id = '/MyAuctionsScreen';
  const MyAuctionsScreen({super.key});

  @override
  State<MyAuctionsScreen> createState() => _MyAuctionsScreenState();
}

class _MyAuctionsScreenState extends State<MyAuctionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAuctions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _fetchAuctions() {
    context.read<AuctionCubit>().fetchAuctionsDynamically();
  }

  void _showCancelDialog(AuctionModel auction) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.cancel_outlined,
                    color: Colors.red.shade600,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Cancel Auction',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: const Text(
              'Are you sure? This action cannot be undone.',
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.read<AuctionCubit>().cancelAuction(auction.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );
  }

  void _navigateToDetails(AuctionModel auction) {
    Navigator.pushNamed(
      context,
      AuctionDetailsScreen.id,
      arguments: auction.id,
    ).then((_) => _fetchAuctions());
  }

  void _navigateToEdit(AuctionModel auction) async {
    final result = await Navigator.pushNamed(
      context,
      UpdateAuctionScreen.id,
      arguments: auction,
    );
    if (result == true) _fetchAuctions();
  }

  void _navigateToBids(AuctionModel auction) {
    Navigator.pushNamed(context, BidHistoryScreen.id, arguments: auction).then((_) => _fetchAuctions());
  }

  @override
  Widget build(BuildContext context) {
    if (StorageService().isGuest) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Please log in and create an organization to view this page.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Login', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // 1. الهيدر (Header) - للعرض فقط وتم إزالة زر الإضافة
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            children: [
              const Text(
                'My Auctions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              // زرار الـ Refresh عشان لو حب يدوياً يكلم الـ API تاني
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                color: Colors.grey.shade700,
                onPressed: _fetchAuctions,
                tooltip: 'Refresh',
              ),
            ],
          ),
        ),

        // 2. التابات الفرعية (Nested TabBar)
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey.shade500,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Active'),
            Tab(text: 'Ended'),
          ],
        ),

        // 3. المحتوى (TabBarView) - بيعرض الداتا اللي راجعة من الـ API
        Expanded(
          child: BlocConsumer<AuctionCubit, AuctionState>(
            listener: (context, state) {
              if (state is AuctionError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
              if (state is AuctionSuccess<String>) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.data),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                _fetchAuctions();
              }
            },
            builder: (context, state) {
              if (state is AuctionLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (state is AuctionDashboardLoaded) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _AuctionListPage(
                      auctions: state.upcoming,
                      tab: 'upcoming',
                      onRefresh: _fetchAuctions,
                      onDetails: _navigateToDetails,
                      onBids: _navigateToBids,
                      onEdit: _navigateToEdit,
                      onCancel: _showCancelDialog,
                    ),
                    _AuctionListPage(
                      auctions: state.active,
                      tab: 'active',
                      onRefresh: _fetchAuctions,
                      onDetails: _navigateToDetails,
                      onBids: _navigateToBids,
                      onEdit: _navigateToEdit,
                      onCancel: _showCancelDialog,
                    ),
                    _AuctionListPage(
                      auctions: state.ended,
                      tab: 'ended',
                      onRefresh: _fetchAuctions,
                      onDetails: _navigateToDetails,
                      onBids: _navigateToBids,
                      onEdit: _navigateToEdit,
                      onCancel: _showCancelDialog,
                    ),
                  ],
                );
              }

              if (state is AuctionError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _fetchAuctions,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Loading State المتوافق مع التصميم بتاعك
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Transform.rotate(
                      angle: -0.2,
                      child: Icon(
                        Icons.gavel_rounded,
                        size: 72,
                        color: Colors.grey.shade300,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading your auctions...',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

}

class _AuctionListPage extends StatefulWidget {
  final List<AuctionModel> auctions;
  final String tab;
  final VoidCallback onRefresh;
  final Function(AuctionModel) onDetails;
  final Function(AuctionModel) onBids;
  final Function(AuctionModel) onEdit;
  final Function(AuctionModel) onCancel;

  const _AuctionListPage({
    required this.auctions,
    required this.tab,
    required this.onRefresh,
    required this.onDetails,
    required this.onBids,
    required this.onEdit,
    required this.onCancel,
  });

  @override
  State<_AuctionListPage> createState() => _AuctionListPageState();
}

class _AuctionListPageState extends State<_AuctionListPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.auctions.isEmpty) {
      return _buildEmptyState(widget.tab);
    }

    return RefreshIndicator(
      onRefresh: () async => widget.onRefresh(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 20),
        itemCount: widget.auctions.length,
        itemBuilder: (context, index) {
          final auction = widget.auctions[index];
          return AuctionCard(
            auction: auction,
            onTap: () => widget.onDetails(auction),
            onViewBids: () => widget.onBids(auction),
            onEdit: auction.canEdit ? () => widget.onEdit(auction) : null,
            onCancel: auction.canCancel ? () => widget.onCancel(auction) : null,
            onViewResult: () => widget.onBids(auction),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String tab) {
    IconData icon;
    String title;
    String subtitle;
    switch (tab) {
      case 'active':
        icon = Icons.flash_on_rounded;
        title = 'No active auctions';
        subtitle = 'Auctions will appear here once they start.';
        break;
      case 'ended':
        icon = Icons.history_rounded;
        title = 'No ended auctions';
        subtitle = 'Completed auctions will be shown here.';
        break;
      default:
        icon = Icons.schedule_rounded;
        title = 'No upcoming auctions';
        subtitle = 'Your upcoming auctions will appear here.';
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
