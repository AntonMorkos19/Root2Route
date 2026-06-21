// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/features/auctions/cubit/auction_cubit.dart';
import 'package:root2route/features/auctions/cubit/auction_state.dart';
 import 'package:root2route/features/auctions/data/models/auction_model.dart';
import 'package:root2route/features/auth/ui/login_screen.dart';
 import 'package:root2route/core/services/api.dart';
 import 'package:root2route/core/services/storage_service.dart';
 import 'package:root2route/core/utils/image_utils.dart';
import 'package:root2route/core/utils/price_formatter.dart';

class AuctionDetailsScreen extends StatefulWidget {
  static const String id = '/auctionDetailsScreen';

  final String? auctionId;

  const AuctionDetailsScreen({super.key, this.auctionId});

  @override
  State<AuctionDetailsScreen> createState() => _AuctionDetailsScreenState();
}

class _AuctionDetailsScreenState extends State<AuctionDetailsScreen> {
  late String _auctionId;
  bool _isInit = false;

  final ApiService _api = ApiService();
  bool _isLoadingBids = true;
  List<BidModel> _bidsList = [];
  final TextEditingController _bidController = TextEditingController();

  AuctionModel? _lastAuction;

  Map<String, dynamic>? _productData;
  bool _isLoadingProduct = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      if (widget.auctionId != null && widget.auctionId!.isNotEmpty) {
        _auctionId = widget.auctionId!;
      } else {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is String) {
          _auctionId = args;
        } else if (args is Map && args['id'] != null) {
          _auctionId = args['id'];
        } else if (args is AuctionModel) {
          _auctionId = args.id;
        } else {
          _auctionId = '';
        }
      }

      if (_auctionId.isNotEmpty) {
        context.read<AuctionCubit>().fetchAuctionDetails(_auctionId);
        _fetchBids(_auctionId);
      }
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────
  // Data helpers
  // ──────────────────────────────────────────────────────────────

  Future<void> _fetchProductData(String productId) async {
    if (_isLoadingProduct || _productData != null) return;
    if (mounted) setState(() => _isLoadingProduct = true);
    try {
      final res = await _api.getProductById(productId);
      if (mounted && res['success'] == true) {
        setState(() {
          _productData = res['data'];
          _isLoadingProduct = false;
        });
      } else {
        if (mounted) setState(() => _isLoadingProduct = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProduct = false);
    }
  }

  Future<void> _fetchBids(String id) async {
    if (mounted) setState(() => _isLoadingBids = true);
    try {
      final bids = await _api.getAuctionBidsAsBidModels(id);
      if (mounted) {
        setState(() {
          _bidsList = bids;
          _isLoadingBids = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBids = false);
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Bidding Logic
  // ──────────────────────────────────────────────────────────────

  /// Arabic-friendly error translator for bid failures.
  String _arabicBidError(String rawMessage) {
    final lower = rawMessage.toLowerCase();
    if (lower.contains('concurren') ||
        lower.contains('high bidding') ||
        lower.contains('volume') ||
        lower.contains('conflict') ||
        lower.contains('try again')) {
      return 'عذراً، يوجد ضغط كبير على المزاد حالياً. يرجى المحاولة مرة أخرى.';
    }
    if (lower.contains('bid') && lower.contains('high')) {
      return 'توجد مزايدة أعلى من قيمتك، يرجى زيادة المبلغ.';
    }
    if (lower.contains('ended') || lower.contains('closed')) {
      return 'انتهى وقت المزاد ولا يمكن إضافة مزايدة.';
    }
    if (lower.contains('network') || lower.contains('timeout') || lower.contains('connection')) {
      return 'تعذّر الاتصال بالشبكة، يرجى التحقق من الاتصال والمحاولة مجدداً.';
    }
    return 'حدث خطأ أثناء إرسال المزايدة. يرجى المحاولة مرة أخرى.';
  }

  void _submitBid(AuctionModel auction) {
    final double currentHighest = auction.currentHighestBid ?? auction.startingPrice;
    final double minRequired = currentHighest + auction.minimumBidIncrement;

    // ── Parse strictly as double (not string) ──
    final String raw = _bidController.text.trim();
    final double? entered = double.tryParse(raw);

    if (entered == null || entered < minRequired) {
      QuickAlert.show(cancelBtnText: 'إلغاء', 
        context: context,
        type: QuickAlertType.warning,
        title: 'مبلغ غير كافٍ',
        text: 'يجب أن تكون المزايدة أكبر من أو تساوي ${_fmt(minRequired)} ج.م',
        confirmBtnText: 'حسناً',
        confirmBtnColor: AppColors.primary,
      );
      return;
    }

    debugPrint('[🎯 SUBMIT BID via Cubit] auctionId=$_auctionId  amount=$entered');
    context.read<AuctionCubit>().placeBid(auctionId: _auctionId, amount: entered);
  }


  void _showBidBottomSheet(AuctionModel auction) {
    _bidController.clear();
    final double currentHighest = auction.currentHighestBid ?? auction.startingPrice;
    final double minRequired = currentHighest + auction.minimumBidIncrement;

    final cubit = context.read<AuctionCubit>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: BlocBuilder<AuctionCubit, AuctionState>(
            builder: (sheetCtx, state) {
              final bool isBidding = state is BidLoading;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: EdgeInsets.fromLTRB(
                  24, 24, 24,
                  24 + MediaQuery.of(sheetCtx).viewInsets.bottom,
                ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'أضف مزايدتك',
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'الحد الأدنى المقبول: ${_fmt(minRequired)} ج.م',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13.sp,
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _bidController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: !isBidding,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: 'مثال: ${_fmt(minRequired)}',
                      hintTextDirection: TextDirection.rtl,
                      suffixText: 'ج.م',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isBidding ? null : () => _submitBid(auction),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isBidding
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'تأكيد المزايدة',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'إلغاء',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 15.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
    );
  }

 
  String _fmt(double v) => PriceFormatter.format(v);

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'نشط';
      case 'upcoming':
        return 'قادم';
      case 'ended':
        return 'منتهٍ';
      default:
        return status;
    }
  }

  Color _statusColor(AuctionModel a) {
    if (a.isUpcoming) return Colors.orange;
    if (a.isActive) return Colors.green;
    return Colors.grey;
  }

  // ──────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'تفاصيل المزاد',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
          ),
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        body: BlocConsumer<AuctionCubit, AuctionState>(
          listener: (context, state) {
            if (state is AuctionSuccess<AuctionModel>) {
              if (_productData == null && !_isLoadingProduct) {
                _fetchProductData(state.data.productId);
              }
            }
            if (state is BidPlaced) {
              if (Navigator.canPop(context)) {
                Navigator.pop(context); // Close bottom sheet
              }
              QuickAlert.show(cancelBtnText: 'إلغاء', 
                context: context,
                type: QuickAlertType.success,
                title: 'نجاح',
                text: 'تمت المزايدة بنجاح!',
                confirmBtnText: 'حسناً',
              );
              if (_auctionId.isNotEmpty) {
                context.read<AuctionCubit>().fetchAuctionDetails(_auctionId);
                _fetchBids(_auctionId);
              }
            }
            if (state is AuctionBidConcurrencyConflict) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('مستخدم آخر قام بالمزايدة! السعر تغير. حاول مرة أخرى.', style: TextStyle(color: Colors.white)),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            if (state is AuctionLiveBidReceived) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم المزايدة بمبلغ ${_fmt(state.newAmount)} ج.م', style: const TextStyle(color: Colors.white)),
                  backgroundColor: Colors.blue,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
              if (_auctionId.isNotEmpty) {
                context.read<AuctionCubit>().fetchAuctionDetails(_auctionId);
                _fetchBids(_auctionId);
              }
            }
            if (state is AuctionError && _lastAuction != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _arabicBidError(state.message),
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is AuctionSuccess<AuctionModel>) {
              _lastAuction = state.data;
            }

            if ((state is AuctionLoading || state is AuctionInitial) && _lastAuction == null) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              );
            }

            if (state is AuctionError && _lastAuction == null) {
              return _buildErrorWidget(state.message);
            }

            if (_lastAuction != null) {
              return _buildDetailsWidget(_lastAuction!);
            }

            return const Center(child: Text('لا توجد تفاصيل متاحة.'));
          },
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Error widget
  // ──────────────────────────────────────────────────────────────

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (_auctionId.isNotEmpty) {
                  context.read<AuctionCubit>().fetchAuctionDetails(_auctionId);
                  _fetchBids(_auctionId);
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Details widget
  // ──────────────────────────────────────────────────────────────

  Widget _buildDetailsWidget(AuctionModel auction) {
    final currentHighest = auction.currentHighestBid ?? auction.startingPrice;
    final bool isGuest = StorageService().isGuest;
    final String? currentOrgId = StorageService().currentUserOrgId;

    final String? pOrgId =
        _productData != null
            ? (_productData!['organizationId'] ?? _productData!['OrganizationId'])?.toString()
            : (auction.organizationId?.isNotEmpty == true ? auction.organizationId : null);

    final bool isOwner =
        !isGuest &&
        currentOrgId != null &&
        currentOrgId.isNotEmpty &&
        pOrgId != null &&
        currentOrgId.toLowerCase() == pOrgId.toLowerCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderCard(auction),
          const SizedBox(height: 16),
          _buildInfoCard(auction),
          const SizedBox(height: 16),
          _buildCountdownCard(auction),
          const SizedBox(height: 24),

          // Bid history title
          Row(
            children: [
              const Icon(Icons.history, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'سجل المزايدات',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBidHistoryCard(),
          const SizedBox(height: 24),

          // Action buttons
          if (isOwner) ...[
            if (auction.isActive)
              _buildDisabledOwnerButton(),
          ] else ...[
            _buildActionButtons(auction, isGuest),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDisabledOwnerButton() {
    return ElevatedButton.icon(
      onPressed: null,
      icon: const Icon(Icons.storefront_outlined, color: Colors.white70),
      label: const Text(
        'أنت صاحب هذا المزاد',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
      ),
      style: ElevatedButton.styleFrom(
        disabledBackgroundColor: Colors.grey.shade400,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildActionButtons(
    AuctionModel auction,
    bool isGuest,
  ) {
    if (!auction.isActive) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          if (isGuest) {
            Navigator.pushNamed(context, LoginScreen.id);
            return;
          }
          _showBidBottomSheet(auction);
        },
        icon: const Icon(Icons.gavel_rounded, color: Colors.white, size: 20),
        label: Text(
          isGuest ? 'سجّل الدخول للمزايدة' : 'أضف مزايدتك',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Card builders
  // ──────────────────────────────────────────────────────────────

  Widget _buildHeaderCard(AuctionModel auction) {
    final statusColor = _statusColor(auction);

    String? imageUrl = auction.productImage;
    if ((imageUrl == null || imageUrl.isEmpty) && _productData != null) {
      imageUrl = _productData!['imageUrl'] ??
          _productData!['ImageUrl'] ??
          _productData!['image'] ??
          _productData!['Image'];
      if (imageUrl == null) {
        final pImages = _productData!['images'] ?? _productData!['Images'];
        if (pImages is List && pImages.isNotEmpty) {
          imageUrl = pImages.first?.toString();
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl.fullImageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  auction.title ?? auction.productName ?? 'مزاد',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Text(
                  _translateStatus(auction.status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.grey.shade300),
    );
  }

  Widget _buildInfoCard(AuctionModel auction) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoRow(
            label: 'السعر المبدئي',
            value: '${_fmt(auction.startingPrice)} ج.م',
            icon: Icons.monetization_on_outlined,
          ),
          const Divider(height: 24),
          _infoRow(
            label: 'أعلى مزايدة حالياً',
            value: auction.currentHighestBid != null
                ? '${_fmt(auction.currentHighestBid!)} ج.م'
                : 'لا توجد مزايدات بعد',
            icon: Icons.trending_up_rounded,
            valueColor: auction.currentHighestBid != null ? AppColors.primary : null,
          ),
          const Divider(height: 24),
          _infoRow(
            label: 'الحد الأدنى للزيادة',
            value: '${_fmt(auction.minimumBidIncrement)} ج.م',
            icon: Icons.add_circle_outline_rounded,
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade500, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownCard(AuctionModel auction) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                auction.isUpcoming ? 'يبدأ خلال' : 'الوقت المتبقي',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AuctionTimer(auction: auction),
        ],
      ),
    );
  }

  Widget _buildBidHistoryCard() {
    if (_isLoadingBids) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_bidsList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.gavel_rounded, size: 40, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Text(
                'لا توجد مزايدات حتى الآن. كن الأول!',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14.sp),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _bidsList.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, index) {
          final bid = _bidsList[index];
          final isTop = index == 0;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: isTop
                  ? AppColors.primary.withOpacity(0.15)
                  : Colors.grey.withOpacity(0.1),
              child: Icon(
                isTop ? Icons.emoji_events_rounded : Icons.person_outline_rounded,
                color: isTop ? AppColors.primary : Colors.grey,
              ),
            ),
            title: Text(
              bid.bidderName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
            ),
            trailing: Text(
              '${_fmt(bid.amount)} ج.م',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isTop ? AppColors.primary : Theme.of(context).textTheme.bodyLarge?.color,
                fontSize: 15.sp,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Countdown Timer Widget
// ──────────────────────────────────────────────────────────────

class _AuctionTimer extends StatefulWidget {
  final AuctionModel auction;

  const _AuctionTimer({required this.auction});

  @override
  State<_AuctionTimer> createState() => _AuctionTimerState();
}

class _AuctionTimerState extends State<_AuctionTimer> {
  late Timer _timer;
  late Duration _timeRemaining;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateTime();
    });
  }

  void _updateTime() {
    setState(() => _timeRemaining = widget.auction.timeRemaining);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.auction.isEnded) {
      return _statusPill('انتهى المزاد', Colors.red);
    }
    if (_timeRemaining.inSeconds <= 0) {
      return _statusPill(
        widget.auction.isUpcoming ? 'يبدأ قريباً...' : 'انتهى المزاد',
        widget.auction.isUpcoming ? Colors.green : Colors.red,
      );
    }

    final days = _timeRemaining.inDays;
    final hours = _timeRemaining.inHours.remainder(24);
    final minutes = _timeRemaining.inMinutes.remainder(60);
    final seconds = _timeRemaining.inSeconds.remainder(60);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (days > 0) _timeBox(days.toString().padLeft(2, '0'), 'أيام'),
        _timeBox(hours.toString().padLeft(2, '0'), 'ساعة'),
        _timeBox(minutes.toString().padLeft(2, '0'), 'دقيقة'),
        _timeBox(seconds.toString().padLeft(2, '0'), 'ثانية'),
      ],
    );
  }

  Widget _statusPill(String msg, Color color) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          msg,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _timeBox(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
