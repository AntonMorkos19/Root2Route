import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/models/auction_model.dart';
import 'countdown_timer_widget.dart';

import 'package:root2route/services/storage_service.dart';
import 'package:root2route/services/api.dart';

/// A premium auction card for the seller dashboard.
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
          onTap: widget.onTap ?? widget.onViewBids,
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
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Starting: EGP ${auction.startingPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey.shade600,
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
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoItem(
                        Icons.gavel_rounded,
                        '${auction.bidsCount} bids',
                      ),
                      _buildInfoItem(
                        Icons.trending_up_rounded,
                        auction.currentHighestBid != null
                            ? 'EGP ${auction.currentHighestBid!.toStringAsFixed(2)}'
                            : 'No bids yet',
                      ),
                      _buildInfoItem(
                        Icons.attach_money_rounded,
                        '+${auction.minimumBidIncrement.toStringAsFixed(2)}',
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
    final displayUrl =
        (imageUrl != null && imageUrl.startsWith('/'))
            ? 'https://root2route.runasp.net$imageUrl'
            : imageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 52,
        height: 52,
        color: Colors.grey.shade100,
        child:
            displayUrl != null && displayUrl.isNotEmpty
                ? Image.network(
                  displayUrl,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.grey.shade400,
                        size: 24,
                      ),
                )
                : Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.grey.shade400,
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
        bgColor = const Color(0xFF22C55E).withOpacity(0.12);
        textColor = const Color(0xFF16A34A);
        label = 'Active';
        break;
      case 'ended':
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade600;
        label = 'Ended';
        break;
      case 'upcoming':
      default:
        bgColor = const Color(0xFFFBBF24).withOpacity(0.15);
        textColor = const Color(0xFFD97706);
        label = 'Upcoming';
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
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
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
          gradient: LinearGradient(
            colors: [Colors.grey.shade100, Colors.grey.shade50],
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.flag_rounded, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              auction.winnerName != null
                  ? 'Winner: ${auction.winnerName}'
                  : 'Auction ended',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }

    final targetDate = auction.isUpcoming ? auction.startDate : auction.endDate;
    final label = auction.isUpcoming ? 'Starts in: ' : 'Ends in: ';
    final color =
        auction.isUpcoming ? const Color(0xFFD97706) : const Color(0xFF16A34A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
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
        if (widget.onBid != null && (auction.isActive || auction.isUpcoming)) ...[
          if (_isMyAuction)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'Your Auction',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
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
                label: 'Bid Now',
                color: AppColors.primary,
                onTap: widget.onBid,
              ),
            ),
          const SizedBox(width: 8),
        ],

        // View Bids
        Expanded(
          child: _ActionButton(
            icon: Icons.bar_chart_rounded,
            label: 'Bids',
            color: widget.onBid != null ? Colors.blue.shade600 : AppColors.primary,
            onTap: widget.onViewBids,
          ),
        ),
        const SizedBox(width: 8),

        // Edit (only for upcoming)
        if (auction.isUpcoming) ...[
          Expanded(
            child: _ActionButton(
              icon: Icons.edit_outlined,
              label: 'Update',
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
              label: 'Cancel',
              color: Colors.red.shade600,
              onTap: widget.onCancel,
            ),
          ),

        // View Result (for ended auctions)
        if (auction.isEnded)
          Expanded(
            child: _ActionButton(
              icon: Icons.emoji_events_rounded,
              label: 'Result',
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
      color: color.withOpacity(0.08),
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
