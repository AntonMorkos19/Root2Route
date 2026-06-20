import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/features/auctions/cubit/auction_cubit.dart';
import 'package:root2route/features/auctions/cubit/auction_state.dart';
import 'package:root2route/features/auctions/data/models/auction_model.dart';
import 'package:root2route/features/auctions/ui/bid_history_screen.dart';
import 'package:root2route/components/auction_card.dart';
import 'package:root2route/features/auctions/ui/update_auction_screen.dart';
import 'package:root2route/features/auctions/ui/auction_details_screen.dart';
import 'package:root2route/core/services/storage_service.dart';
import 'package:root2route/features/auth/ui/login_screen.dart';

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
    QuickAlert.show(
      context: context,
      type: QuickAlertType.warning,
      title: 'إلغاء المزاد',
      text: 'هل أنت متأكد؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmBtnText: 'تأكيد',
      cancelBtnText: 'إلغاء',
      showCancelBtn: true,
      confirmBtnColor: Colors.red.shade600,
      onConfirmBtnTap: () {
        Navigator.pop(context);
        context.read<AuctionCubit>().cancelAuction(auction.id);
      },
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
    Navigator.pushNamed(
      context,
      BidHistoryScreen.id,
      arguments: auction,
    ).then((_) => _fetchAuctions());
  }

  @override
  Widget build(BuildContext context) {
    if (StorageService().isGuest) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'يرجى تسجيل الدخول وإنشاء شركة لعرض هذه الصفحة.',
                  textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  'تسجيل الدخول',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ));
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : Colors.grey.shade500,
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
              Tab(text: 'القادمة'),
              Tab(text: 'النشطة'),
              Tab(text: 'المنتهية'),
            ],
          ),
        ),

        // 3. Content (TabBarView) - Displays data from API
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
                        label: const Text('إعادة المحاولة'),
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

              // Loading State compatible with your design
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
                      'جاري تحميل مزاداتك...',
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
    ));
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
        title = 'لا توجد مزادات نشطة';
        subtitle = 'ستظهر المزادات هنا بمجرد بدئها.';
        break;
      case 'ended':
        icon = Icons.history_rounded;
        title = 'لا توجد مزادات منتهية';
        subtitle = 'ستظهر المزادات المكتملة هنا.';
        break;
      default:
        icon = Icons.schedule_rounded;
        title = 'لا توجد مزادات قادمة';
        subtitle = 'ستظهر مزاداتك القادمة هنا.';
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2A2A2A)
                      : Colors.grey.shade100,
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
              color:
                  Theme.of(context).textTheme.titleMedium?.color ??
                  Colors.grey.shade700,
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
