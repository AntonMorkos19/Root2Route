import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/features/auctions/data/models/auction_model.dart';
import 'countdown_timer_widget.dart';
import 'package:root2route/features/auctions/ui/auction_details_screen.dart';

import 'package:root2route/core/services/storage_service.dart';
import 'package:root2route/core/services/api.dart';
import 'package:root2route/core/utils/price_formatter.dart';
import 'package:root2route/core/utils/image_utils.dart';

 class AuctionCard extends StatefulWidget {
  final AuctionModel auction;
  final Map<String, dynamic>? productData; // Pre-fetched product data
  final VoidCallback? onTap;
  final VoidCallback? onBid;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final VoidCallback? onViewBids;
  final VoidCallback? onViewResult;

  const AuctionCard({
    super.key,
    required this.auction,
    this.productData,
    this.onTap,
    this.onBid,
    this.onEdit,
    this.onCancel,
    this.onViewBids,
    this.onViewResult,
  });

  @override
  State<AuctionCard> createState() => _AuctionCardState();
}

class _AuctionCardState extends State<AuctionCard> {
  String? _imageUrl;
  bool _isMyAuction = false; 
  
  @override
  void initState() {
    super.initState();
    _imageUrl = widget.auction.productImage;
    if (widget.productData != null) {
      _applyProductData(widget.productData!);
    } else {
      _checkProductAndOwnership();
    }
  }

  void _applyProductData(Map<String, dynamic> data) {
    final currentUserOrgId = StorageService().currentUserOrgId;
    
    // Resolve Image
    String? img = data['imageUrl'] ?? data['ImageUrl'] ?? data['image'] ?? data['Image'];
    if (img == null) {
      final imgs = data['images'] ?? data['Images'];
      if (imgs is List && imgs.isNotEmpty) img = imgs.first?.toString();
    }

    // Resolve Ownership
    final pOrgId = (data['organizationId'] ?? data['OrganizationId'])?.toString();
    final bool isOwner = currentUserOrgId != null && currentUserOrgId == pOrgId;

    if (mounted) {
      setState(() {
        if (_imageUrl == null || _imageUrl!.isEmpty) _imageUrl = img;
        _isMyAuction = isOwner;
      });
    }
  }

  Future<void> _checkProductAndOwnership() async {
    final currentUserOrgId = StorageService().currentUserOrgId;
    if (currentUserOrgId == null || currentUserOrgId.isEmpty) {
      if (mounted) setState(() => _isMyAuction = false);
    }
    
    // Fallback image fetch and accurate org check
    try {
      final res = await ApiService().getProductById(widget.auction.productId);
      if (res['success'] == true && res['data'] != null) {
        _applyProductData(res['data']);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auction = widget.auction;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap ?? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AuctionDetailsScreen(auctionId: auction.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: Product + Status Chip ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image
                    _buildProductImage(),
                    const SizedBox(width: 12),
                    // Product info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auction.productName ?? 'Auction',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.titleMedium?.color,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'السعر المبدئي: ${PriceFormatter.format(auction.startingPrice)} جنيه',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusChip(),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Info Row ──
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (auction.bidsCount > 0 || auction.currentHighestBid == null || auction.currentHighestBid! <= auction.startingPrice)
                        _buildInfoItem(
                          Icons.gavel_rounded,
                          '${auction.bidsCount} مزايدات',
                        ),
                      _buildInfoItem(
                        Icons.trending_up_rounded,
                        auction.currentHighestBid != null
                            ? '${PriceFormatter.format(auction.currentHighestBid!)} جنيه'
                            : 'لا توجد مزايدات',
                      ),
                      _buildInfoItem(
                        Icons.attach_money_rounded,
                        '+${PriceFormatter.format(auction.minimumBidIncrement)}',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Countdown / Result ──
                _buildCountdownOrResult(),

                const SizedBox(height: 12),

                // ── Action Buttons ──
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    final imageUrl = _imageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 52,
        height: 52,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child:
            imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                  imageUrl.fullImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Icon(
                        Icons.inventory_2_outlined,
                        color: Theme.of(context).colorScheme.outline,
                        size: 24,
                      ),
                )
                : Icon(
                  Icons.inventory_2_outlined,
                  color: Theme.of(context).colorScheme.outline,
                  size: 24,
                ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color bgColor;
    Color textColor;
    String label;

    switch (widget.auction.status) {
      case 'active':
        bgColor = const Color(0xFF22C55E).withValues(alpha: 0.12);
        textColor = const Color(0xFF16A34A);
        label = 'نشط';
        break;
      case 'ended':
        bgColor = Theme.of(context).colorScheme.surfaceContainerHighest;
        textColor = Theme.of(context).colorScheme.onSurfaceVariant;
        label = 'منتهي';
        break;
      case 'upcoming':
      default:
        bgColor = const Color(0xFFFBBF24).withValues(alpha: 0.15);
        textColor = const Color(0xFFD97706);
        label = 'قادم';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownOrResult() {
    final auction = widget.auction;
    if (auction.isEnded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.flag_rounded,
                size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              auction.winnerName != null
                  ? 'الفائز: ${auction.winnerName}'
                  : 'انتهى المزاد',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final targetDate = auction.isUpcoming ? auction.startDate : auction.endDate;
    final label = auction.isUpcoming ? 'يبدأ خلال: ' : 'ينتهي خلال: ';
    final color =
        auction.isUpcoming ? const Color(0xFFD97706) : const Color(0xFF16A34A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 16, color: color),
          const SizedBox(width: 8),
          CountdownTimerWidget(
            targetDate: targetDate,
            prefix: label,
            textStyle: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final auction = widget.auction;
    return Row(
      children: [
        // Bid Now button (for marketplace) or "Your Auction" badge
        if (auction.isActive || auction.isUpcoming) ...[
          if (_isMyAuction)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_outline,
                        size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      'مزادك',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: _ActionButton(
                icon: Icons.gavel_rounded,
                label: 'زايد الآن',
                color: AppColors.primary,
                onTap: widget.onBid ?? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AuctionDetailsScreen(auctionId: auction.id),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(width: 8),
        ],

        // View Bids
        Expanded(
          child: _ActionButton(
            icon: Icons.bar_chart_rounded,
            label: 'المزايدات',
            color: (auction.isActive || auction.isUpcoming) && !_isMyAuction ? Colors.blue.shade600 : AppColors.primary,
            onTap: widget.onViewBids ?? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AuctionDetailsScreen(auctionId: auction.id),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),

        // Edit (only for upcoming)
        if (auction.isUpcoming) ...[
          Expanded(
            child: _ActionButton(
              icon: Icons.edit_outlined,
              label: 'تحديث',
              color: Colors.blue.shade600,
              onTap: widget.onEdit,
            ),
          ),
          const SizedBox(width: 8),
        ],

        // Cancel (only if upcoming and no bids)
        if (auction.canCancel)
          Expanded(
            child: _ActionButton(
              icon: Icons.cancel_outlined,
              label: 'إلغاء',
              color: Colors.red.shade600,
              onTap: widget.onCancel,
            ),
          ),

        // View Result (for ended auctions)
        if (auction.isEnded)
          Expanded(
            child: _ActionButton(
              icon: Icons.emoji_events_rounded,
              label: 'النتيجة',
              color: const Color(0xFFD97706),
              onTap: widget.onViewResult ?? widget.onViewBids,
            ),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
