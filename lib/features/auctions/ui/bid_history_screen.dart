import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/features/auctions/cubit/auction_cubit.dart';
import 'package:root2route/features/auctions/cubit/auction_state.dart';
import 'package:root2route/features/auctions/data/models/auction_model.dart';
import 'package:root2route/core/utils/price_formatter.dart';
/// Screen 5 — Bid History
/// GET /api/v1/auctions/{auctionId}/bids
/// Receives [AuctionModel] via ModalRoute.settings.arguments.
class BidHistoryScreen extends StatefulWidget {
  static const String id = '/bidHistoryScreen';
  const BidHistoryScreen({super.key});

  @override
  State<BidHistoryScreen> createState() => _BidHistoryScreenState();
}

class _BidHistoryScreenState extends State<BidHistoryScreen> {
  late AuctionModel _auction;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _auction = ModalRoute.of(context)!.settings.arguments as AuctionModel;
      _initialized = true;
      context.read<AuctionCubit>().fetchBids(
        auctionId: _auction.id,
        auction: _auction,
      );
    }
  }

  void _refresh() {
    context.read<AuctionCubit>().fetchBids(
      auctionId: _auction.id,
      auction: _auction,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
        title: Text(
          _initialized
              ? (_auction.productName ?? 'سجل المزايدات')
              : 'سجل المزايدات',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0.5,
        iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: BlocConsumer<AuctionCubit, AuctionState>(
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
        },
        builder: (context, state) {
          if (state is AuctionLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (state is BidHistoryLoaded) {
            return _buildBidList(state);
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _refresh,
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
          return const SizedBox();
        },
      ),
    ));
  }

  Widget _buildBidList(BidHistoryLoaded state) {
    final bids = state.bids;
    final auction = state.auction;
    if (bids.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.gavel_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'لا توجد مزايدات حتى الآن',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ستظهر المزايدات هنا بمجرد أن يبدأ المستخدمون بالمزايدة.',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final highestBid = bids.first; // already sorted descending by amount
    final pinWinner = auction.isEnded;

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: bids.length + (pinWinner ? 1 : 0),
      itemBuilder: (context, index) {
        if (pinWinner && index == 0) {
          return _winnerCard(highestBid, auction);
        }
        final bidIndex = pinWinner ? index - 1 : index;
        final bid = bids[bidIndex];
        return _bidTile(bid, bidIndex + 1, bid.id == highestBid.id);
      },
    );
  }

  Widget _winnerCard(BidModel highestBid, AuctionModel auction) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🏆 الفائز بالمزاد',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auction.winnerName ?? highestBid.bidderName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'المزايدة الفائزة',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${PriceFormatter.format(highestBid.amount)} جنيه',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bidTile(BidModel bid, int rank, bool isHighest) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color:
            isHighest
                ? const Color(0xFF22C55E).withValues(alpha: 0.06)
                : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border:
            isHighest
                ? Border.all(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                )
                : Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                isHighest
                    ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child:
                isHighest
                    ? const Icon(
                      Icons.star_rounded,
                      color: Color(0xFF22C55E),
                      size: 22,
                    )
                    : Text(
                      '#$rank',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
          ),
        ),
        title: Text(
          bid.bidderName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color:
                isHighest
                    ? const Color(0xFF16A34A)
                    : Theme.of(context).textTheme.titleSmall?.color,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${PriceFormatter.format(bid.amount)} جنيه',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color:
                    isHighest
                        ? const Color(0xFF16A34A)
                        : Theme.of(context).textTheme.titleSmall?.color,
              ),
            ),
            if (isHighest)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'الأعلى',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF16A34A),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
