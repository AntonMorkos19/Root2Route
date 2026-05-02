import 'package:root2route/models/auction_model.dart';

/// Base state for auction Cubits.
abstract class AuctionState {
  const AuctionState();
}

/// Initial idle state.
class AuctionInitial extends AuctionState {
  const AuctionInitial();
}

/// Loading / in-progress state.
class AuctionLoading extends AuctionState {
  const AuctionLoading();
}

/// Generic success state carrying typed data.
class AuctionSuccess<T> extends AuctionState {
  final T data;
  const AuctionSuccess(this.data);
}

/// Error state carrying a user-visible message.
class AuctionError extends AuctionState {
  final String message;
  const AuctionError(this.message);
}

// ─── Dashboard-specific states ───────────────────────────

/// Holds the filtered auction tabs.
class AuctionDashboardLoaded extends AuctionState {
  final List<AuctionModel> upcoming;
  final List<AuctionModel> active;
  final List<AuctionModel> ended;

  const AuctionDashboardLoaded(this.upcoming, this.active, this.ended);
}

// ─── Bid-history-specific states ─────────────────────────

/// Successfully loaded bid list for a given auction.
class BidHistoryLoaded extends AuctionState {
  final List<BidModel> bids;
  final AuctionModel auction;

  const BidHistoryLoaded({required this.bids, required this.auction});
}
