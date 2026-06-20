import 'package:root2route/features/auctions/data/models/auction_model.dart';

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

/// Dedicated loading state while a bid is being submitted.
/// Unlike [AuctionLoading], this does NOT replace the details screen UI.
class BidLoading extends AuctionState {
  const BidLoading();
}

/// Emitted after a bid is placed successfully.
/// The Cubit will immediately re-fetch details & bids after emitting this.
class BidPlaced extends AuctionState {
  final String auctionId;
  const BidPlaced(this.auctionId);
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

// ─── Concurrency & Real-time states ──────────────────────

/// Emitted when a bid fails due to optimistic concurrency (another user
/// bid at the exact same moment). The UI should show a friendly SnackBar
/// instead of a generic error screen. The SignalR `ReceiveNewBid` event
/// will simultaneously update the displayed price.
class AuctionBidConcurrencyConflict extends AuctionState {
  final String message;
  const AuctionBidConcurrencyConflict(this.message);
}

/// Emitted when a real-time bid update arrives via SignalR.
/// The UI can use this to update the displayed price without a full reload.
class AuctionLiveBidReceived extends AuctionState {
  final double newAmount;
  final String bidderId;
  const AuctionLiveBidReceived({required this.newAmount, required this.bidderId});
}
