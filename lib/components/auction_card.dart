import 'package:flutter/material.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/models/auction_model.dart';
import 'countdown_timer_widget.dart';

/// A premium auction card for the seller dashboard.
class AuctionCard extends StatelessWidget {
  final AuctionModel auction;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final VoidCallback? onViewBids;
  final VoidCallback? onViewResult;

  const AuctionCard({
    super.key,
    required this.auction,
    this.onTap,
    this.onEdit,
    this.onCancel,
    this.onViewBids,
    this.onViewResult,
  });

  @override
  Widget build(BuildContext context) {
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
          onTap: onTap ?? onViewBids,
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
                            style: const TextStyle(
                              fontSize: 16,
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
                              fontSize: 13,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
    final imageUrl = auction.productImage;
    final displayUrl = (imageUrl != null && imageUrl.startsWith('/'))
        ? 'https://root2route.runasp.net$imageUrl'
        : imageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 52,
        height: 52,
        color: Colors.grey.shade100,
        child: displayUrl != null && displayUrl.isNotEmpty
            ? Image.network(
                displayUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
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

    switch (auction.status) {
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
          fontSize: 11,
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
              fontSize: 11,
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
    if (auction.isEnded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade100,
              Colors.grey.shade50,
            ],
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }

    final targetDate =
        auction.isUpcoming ? auction.startDate : auction.endDate;
    final label = auction.isUpcoming ? 'Starts in: ' : 'Ends in: ';
    final color = auction.isUpcoming
        ? const Color(0xFFD97706)
        : const Color(0xFF16A34A);

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
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        // View Bids
        Expanded(
          child: _ActionButton(
            icon: Icons.bar_chart_rounded,
            label: 'Bids',
            color: AppColors.primary,
            onTap: onViewBids,
          ),
        ),
        const SizedBox(width: 8),

        // Edit (only for upcoming)
        if (auction.isUpcoming) ...[
          Expanded(
            child: _ActionButton(
              icon: Icons.edit_outlined,
              label: 'Edit',
              color: Colors.blue.shade600,
              onTap: onEdit,
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
              onTap: onCancel,
            ),
          ),

        // View Result (for ended auctions)
        if (auction.isEnded)
          Expanded(
            child: _ActionButton(
              icon: Icons.emoji_events_rounded,
              label: 'Result',
              color: const Color(0xFFD97706),
              onTap: onViewResult ?? onViewBids,
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
                  fontSize: 12,
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
