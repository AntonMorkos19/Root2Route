import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/features/auctions/cubit/auction_cubit.dart';
import 'package:root2route/screens/auction/auction_details_screen.dart';
import 'package:root2route/services/api.dart';
import 'package:root2route/core/utils/price_formatter.dart';
import 'package:root2route/core/utils/image_utils.dart';
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
              res['message'] ?? 'فشل في تحميل المزادات المشارك بها.';
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
          _wonError = res['message'] ?? 'فشل في تحميل المزادات الفائزة.';
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
    QuickAlert.show(
      context: context,
      type: QuickAlertType.info,
      title: 'تأكيد الدفع',
      text: 'هل أنت متأكد أنك تريد الدفع لـ "$title"؟',
      showCancelBtn: true,
      cancelBtnText: 'إلغاء',
      confirmBtnText: 'دفع',
      confirmBtnColor: AppColors.primary,
      onConfirmBtnTap: () async {
        Navigator.pop(context); // Close confirmation dialog

        if (!mounted) return;

        QuickAlert.show(confirmBtnText: 'موافق', cancelBtnText: 'إلغاء', 
          context: context,
          type: QuickAlertType.loading,
          title: 'جاري المعالجة',
          text: 'جاري إكمال الدفع...',
          barrierDismissible: false,
        );

        try {
          final res = await _api.checkoutAuction(auctionId);
          if (!mounted) return;
          Navigator.pop(context); // Close loading dialog

          if (res['success'] == true) {
            await QuickAlert.show(cancelBtnText: 'إلغاء', 
              context: context,
              type: QuickAlertType.success,
              title: 'اكتمل الدفع!',
              text: res['message'] ?? 'تم تقديم طلبك بنجاح.',
              confirmBtnText: 'رائع',
              confirmBtnColor: AppColors.primary,
            );
            _fetchWon();
          } else {
            QuickAlert.show(cancelBtnText: 'إلغاء', 
              context: context,
              type: QuickAlertType.error,
              title: 'فشل الدفع',
              text: res['message'] ?? 'حدث خطأ ما. يرجى المحاولة مرة أخرى.',
              confirmBtnText: 'موافق',
            );
          }
        } catch (e) {
          if (!mounted) return;
          Navigator.pop(context); // Close loading dialog on error
          QuickAlert.show(cancelBtnText: 'إلغاء', 
            context: context,
            type: QuickAlertType.error,
            title: 'خطأ',
            text: 'حدث خطأ غير متوقع: $e',
            confirmBtnText: 'موافق',
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
              'مزاداتي',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'تتبع مزايداتك واستلم مزاداتك الفائزة',
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
          tabs: const [Tab(text: 'مشارك بها'), Tab(text: 'فائز بها')],
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
            emptyTitle: 'لا توجد مزادات مشارك بها',
            emptySubtitle: 'المزادات التي شاركت بها ستظهر هنا.',
            cardBuilder:
                (auction) => _ParticipatedAuctionCard(auction: auction),
          ),
          _buildListTab(
            data: _won,
            isLoading: _loadingWon,
            error: _wonError,
            onRefresh: _fetchWon,
            emptyIcon: Icons.emoji_events_rounded,
            emptyTitle: 'لا توجد مزادات فائزة',
            emptySubtitle: 'مزاداتك الفائزة ستظهر هنا.',
            cardBuilder:
                (auction) => _WonAuctionCard(
                  auction: auction,
                  onCheckout: _handleCheckout,
                ),
          ),
        ],
      ),
    )
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
  // 1. Check top-level image fields first (fastest path)
  String? imageUrl =
      auction['productImage']?.toString() ??
      auction['ProductImage']?.toString() ??
      auction['productImageUrl']?.toString() ??
      auction['ProductImageUrl']?.toString();

  // 2. Fall back to images array
  if (imageUrl == null || imageUrl.isEmpty) {
    final images =
        auction['images'] ?? auction['Images'] ?? auction['productImages'];
    if (images is List && images.isNotEmpty) {
      imageUrl = images.first?.toString();
    }
  }

  return imageUrl.fullImageUrl;
}

String _resolveTitle(dynamic auction) {
  return auction['title'] ?? auction['Title'] ?? auction['name'] ?? 'مزاد';
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
    final auctionId = (auction['id'] ?? auction['Id'] ?? auction['auctionId'] ?? '').toString();

    // Robust multi-key lookup — covers all known API response shapes
    final rawBid =
        auction['currentHighestBid'] ??
        auction['CurrentHighestBid'] ??
        auction['highestBid'] ??
        auction['HighestBid'] ??
        auction['currentBid'] ??
        auction['CurrentBid'] ??
        0;
    final currentBid = double.tryParse(rawBid.toString()) ?? 0.0;

    // Debug: print raw auction keys to console so you can verify the API response
    debugPrint('[BuyerAuctions] auction keys: ${(auction as Map).keys.toList()}  | currentHighestBid=${auction['currentHighestBid']}');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: auctionId.isEmpty
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) => AuctionCubit(),
                        child: AuctionDetailsScreen(auctionId: auctionId),
                      ),
                    ),
                  );
                },
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
                      displayUrl != null && displayUrl.isNotEmpty
                          ? Image.network(
                            displayUrl,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => _imagePlaceholder(size: 32),
                          )
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'أعلى مزايدة حالياً',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                      Text(
                        currentBid > 0
                            ? '${PriceFormatter.format(currentBid)} جنيه'
                            : 'لا توجد مزايدات بعد',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: currentBid > 0 ? AppColors.primary : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(Icons.chevron_right_rounded, color: AppColors.primary),
              ),
            ],
          ),
        ),
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
        color: Theme.of(context).cardColor,
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
                      ? Image.network(
                        displayUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(),
                      )
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
                      '${PriceFormatter.format(winningPrice)} جنيه',
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
                  child: const Text('دفع'),
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(onPressed: onRefresh, child: const Text('تحديث')),
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
          TextButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}
