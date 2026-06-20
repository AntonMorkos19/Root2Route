import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/features/auctions/cubit/auction_state.dart';
import 'package:root2route/features/auctions/data/models/auction_model.dart';
import 'package:root2route/core/services/api.dart';
import 'package:root2route/features/auctions/data/services/auction_hub_service.dart';
import 'package:root2route/core/services/storage_service.dart';

/// Cubit handling all seller-side auction operations.
class AuctionCubit extends Cubit<AuctionState> {
  final ApiService _service;
  final AuctionHubService _hubService;

  StreamSubscription<LiveBidUpdate>? _bidSubscription;

  AuctionCubit({ApiService? service, AuctionHubService? hubService})
      : _service = service ?? ApiService(),
        _hubService = hubService ?? AuctionHubService(),
        super(const AuctionInitial());

  // ──────────────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────────────

  /// Safety wrapper to prevent emitting state after the cubit is closed.
  void _emitSafe(AuctionState state) {
    if (!isClosed) emit(state);
  }

  /// Unified logic for separating auctions into dashboard tabs.
  void _emitDashboard(List<AuctionModel> auctions) {
    final upcoming = auctions.where((a) => a.isUpcoming).toList();
    final active = auctions.where((a) {
      final s = a.status.toLowerCase();
      return s == 'active' || s == 'ongoing';
    }).toList();
    final ended = auctions.where((a) => a.isEnded).toList();

    _emitSafe(AuctionDashboardLoaded(upcoming, active, ended));
  }

  // ──────────────────────────────────────────────────────
  // SIGNALR HUB MANAGEMENT
  // ──────────────────────────────────────────────────────

  /// Connects to the Auction SignalR hub and starts listening for bid updates.
  ///
  /// Call this once when entering a live auction context (e.g., auction details).
  Future<void> connectToHub() async {
    final token = StorageService().token;
    if (token == null || token.isEmpty) {
      debugPrint('[AuctionCubit] No token available — skipping hub connection.');
      return;
    }

    try {
      await _hubService.connect(token);

      // Subscribe to the real-time bid stream
      _bidSubscription?.cancel();
      _bidSubscription = _hubService.onNewBid.listen((update) {
        _emitSafe(AuctionLiveBidReceived(
          newAmount: update.newAmount,
          bidderId: update.bidderId,
        ));
      });
    } catch (e) {
      debugPrint('[AuctionCubit] Hub connection failed: $e');
    }
  }

  /// Joins the SignalR group for a specific auction.
  Future<void> joinAuctionGroup(String auctionId) async {
    await _hubService.joinAuctionGroup(auctionId);
  }

  /// Leaves the SignalR group for a specific auction.
  Future<void> leaveAuctionGroup(String auctionId) async {
    await _hubService.leaveAuctionGroup(auctionId);
  }

  /// Fetches the live auction state directly from the hub (no HTTP call).
  Future<Map<String, dynamic>?> getAuctionState(String auctionId) async {
    return _hubService.getAuctionState(auctionId);
  }

  /// Disconnects from the hub. Call when leaving the auction context.
  Future<void> disconnectFromHub() async {
    _bidSubscription?.cancel();
    _bidSubscription = null;
    await _hubService.disconnect();
  }

  // ──────────────────────────────────────────────────────
  // CREATE AUCTION
  // ──────────────────────────────────────────────────────
  Future<void> createAuction({
    required String title,
    required String productId,
    required double startingPrice,
    required double minimumBidIncrement,
    required double reservePrice,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _emitSafe(const AuctionLoading());
    try {
      final auction = await _service.createAuction(
        title: title,
        productId: productId,
        startingPrice: startingPrice,
        minimumBidIncrement: minimumBidIncrement,
        reservePrice: reservePrice,
        startDate: startDate,
        endDate: endDate,
      );
      _emitSafe(AuctionSuccess<AuctionModel>(auction));
    } on AuctionException catch (e) {
      _emitSafe(AuctionError(e.message));
    } catch (e) {
      _emitSafe(AuctionError(e.toString()));
    }
  }

  // ──────────────────────────────────────────────────────
  // FETCH MY ORGANIZATION AUCTIONS (Dashboard)
  // ──────────────────────────────────────────────────────
  Future<void> fetchMyAuctions(String organizationId) async {
    _emitSafe(const AuctionLoading());
    try {
      final auctions = await _service.getMyOrganizationAuctions(organizationId);
      _emitDashboard(auctions);
    } on AuctionException catch (e) {
      _emitSafe(AuctionError(e.message));
    } catch (e) {
      _emitSafe(AuctionError(e.toString()));
    }
  }

  // ──────────────────────────────────────────────────────
  // FETCH AUCTIONS DYNAMICALLY (Auto-fetch Org ID)
  // ──────────────────────────────────────────────────────
  Future<void> fetchAuctionsDynamically() async {
    _emitSafe(const AuctionLoading());
    try {
      String orgId = StorageService().organizationId ?? '';

      if (orgId.isEmpty) {
        final response = await _service.getMyOrganizations();
        if (response['success'] == true && response['data'] != null) {
          final List<dynamic> orgs = response['data'];
          if (orgs.isNotEmpty) {
            orgId = orgs.first['id']?.toString() ?? '';
            if (orgId.isNotEmpty) {
              await StorageService().saveOrganizationId(orgId);
              await StorageService().saveHasOrganization(true);

              final orgType = orgs.first['type'] ?? orgs.first['Type'];
              if (orgType != null) {
                int typeVal;
                if (orgType is int) {
                  typeVal = orgType;
                } else {
                  typeVal = int.tryParse(orgType.toString()) ?? 0;
                }
                await StorageService().saveOrganizationType(typeVal);
              }
            }
          }
        }
      }

      if (orgId.isEmpty) {
        _emitSafe(const AuctionError('No Organization ID found.'));
        return;
      }

      final auctions = await _service.getMyOrganizationAuctions(orgId);
      _emitDashboard(auctions);
    } on AuctionException catch (e) {
      _emitSafe(AuctionError(e.message));
    } catch (e) {
      _emitSafe(AuctionError(e.toString()));
    }
  }

  // ──────────────────────────────────────────────────────
  // UPDATE AUCTION
  // ──────────────────────────────────────────────────────
  Future<void> updateAuction({
    required String auctionId,
    required String title,
    required double startingPrice,
    required double minimumBidIncrement,
    required double reservePrice,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _emitSafe(const AuctionLoading());
    try {
      final updated = await _service.updateAuction(
        auctionId: auctionId,
        title: title,
        startingPrice: startingPrice,
        minimumBidIncrement: minimumBidIncrement,
        reservePrice: reservePrice,
        startDate: startDate,
        endDate: endDate,
      );
      _emitSafe(AuctionSuccess<AuctionModel>(updated));
    } on AuctionException catch (e) {
      _emitSafe(AuctionError(e.message));
    } catch (e) {
      _emitSafe(AuctionError(e.toString()));
    }
  }
  // CANCEL AUCTION
  // ──────────────────────────────────────────────────────
  Future<void> cancelAuction(String auctionId) async {
    _emitSafe(const AuctionLoading());
    try {
      await _service.cancelAuction(auctionId);
      _emitSafe(const AuctionSuccess<String>('Auction cancelled successfully'));
    } on AuctionException catch (e) {
      _emitSafe(AuctionError(e.message));
    } catch (e) {
      _emitSafe(AuctionError(e.toString()));
    }
  }

  // ──────────────────────────────────────────────────────
  // FETCH BID HISTORY
  // ──────────────────────────────────────────────────────
  Future<void> fetchBids({
    required String auctionId,
    required AuctionModel auction,
  }) async {
    _emitSafe(const AuctionLoading());
    try {
      final bids = await _service.getBidHistory(auctionId);
      bids.sort((a, b) => b.amount.compareTo(a.amount));
      _emitSafe(BidHistoryLoaded(bids: bids, auction: auction));
    } on AuctionException catch (e) {
      _emitSafe(AuctionError(e.message));
    } catch (e) {
      _emitSafe(AuctionError(e.toString()));
    }
  }

  // ──────────────────────────────────────────────────────
  // FETCH AUCTION DETAILS
  // ──────────────────────────────────────────────────────
  Future<void> fetchAuctionDetails(String auctionId) async {
    _emitSafe(const AuctionLoading());
    try {
      final auction = await _service.getAuctionById(auctionId);
      _emitSafe(AuctionSuccess<AuctionModel>(auction));
    } on AuctionException catch (e) {
      _emitSafe(AuctionError(e.message));
    } catch (e) {
      _emitSafe(AuctionError(e.toString()));
    }
  }

  // ──────────────────────────────────────────────────────
  // PLACE BID (with Concurrency Conflict Handling)
  // ──────────────────────────────────────────────────────
  /// Submits a bid for [auctionId] with the given [amount].
  ///
  /// State flow:
  ///  1. [BidLoading]  – disables the submit button in the UI.
  ///  2. [BidPlaced]   – on success; the UI clears the field & shows a SnackBar.
  ///     The cubit then automatically re-fetches details + bid history.
  ///  3. [AuctionBidConcurrencyConflict] – on optimistic concurrency error;
  ///     the UI shows a friendly SnackBar while SignalR updates the price.
  ///  4. [AuctionError] – on any other failure; carries a user-facing message.
  Future<void> placeBid({
    required String auctionId,
    required double amount,
  }) async {
    _emitSafe(const BidLoading());
    try {
      final result = await _service.placeBid(
        auctionId: auctionId,
        amount: amount,
      );

      if (result['success'] == true) {
        _emitSafe(BidPlaced(auctionId));
        // Re-fetch details and bids so the UI refreshes immediately.
        await fetchAuctionDetails(auctionId);
      } else {
        final message = result['message'] ?? 'Failed to place bid.';
        // Check for the specific concurrency error from the backend
        if (_isConcurrencyError(message)) {
          _emitSafe(AuctionBidConcurrencyConflict(message));
        } else if (_isOwnAuctionError(message)) {
          _emitSafe(const AuctionError('لا يمكنك المزايدة على مزاد تابع لشركتك.'));
        } else {
          _emitSafe(AuctionError(message));
        }
      }
    } on DioException catch (e) {
      final msg = _extractDioMessage(e);
      // Check if this is the concurrency conflict from the backend
      if (_isConcurrencyError(msg)) {
        _emitSafe(AuctionBidConcurrencyConflict(msg));
      } else if (_isOwnAuctionError(msg)) {
        _emitSafe(const AuctionError('لا يمكنك المزايدة على مزاد تابع لشركتك.'));
      } else {
        _emitSafe(AuctionError(msg));
      }
    } catch (e) {
      _emitSafe(AuctionError(e.toString()));
    }
  }

  /// Returns `true` if [message] matches the backend's optimistic concurrency error.
  bool _isConcurrencyError(String message) {
    return message.toLowerCase().contains('high bidding volume') ||
        message.toLowerCase().contains('bid could not be processed');
  }

  /// Returns `true` if [message] matches the backend's own auction error.
  bool _isOwnAuctionError(String message) {
    return message.toLowerCase().contains("cannot bid on your own") ||
        message.toLowerCase().contains("own organization");
  }

  /// Extracts a user-facing message from a [DioException], checking both
  /// the `message` field and the nested `errors` map.
  String _extractDioMessage(DioException e) {
    if (e.response == null) return 'No Internet Connection';
    final d = e.response?.data;
    if (d is Map) {
      // Check the top-level message first
      final msg = d['message'] ?? d['msg'] ?? d['error'] ?? d['title'];
      if (msg != null) return msg.toString();

      // Check nested errors map (ASP.NET validation style)
      if (d['errors'] is Map) {
        final errors = d['errors'] as Map;
        if (errors.isNotEmpty) {
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            return firstError[0].toString();
          }
          return firstError.toString();
        }
      }
      return 'Server error';
    }
    return e.message ?? 'Unexpected error';
  }

  // ──────────────────────────────────────────────────────
  // FETCH APPROVED PRODUCTS
  // ──────────────────────────────────────────────────────
  Future<void> fetchApprovedProducts(String organizationId) async {
    _emitSafe(const AuctionLoading());
    try {
      final products = await _service.getApprovedProducts(organizationId);
      _emitSafe(AuctionSuccess<List<Map<String, dynamic>>>(products));
    } on AuctionException catch (e) {
      _emitSafe(AuctionError(e.message));
    } catch (e) {
      _emitSafe(AuctionError(e.toString()));
    }
  }

  // ──────────────────────────────────────────────────────
  // LIFECYCLE
  // ──────────────────────────────────────────────────────
  @override
  Future<void> close() {
    _bidSubscription?.cancel();
    _hubService.dispose();
    return super.close();
  }
}
