import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/features/auctions/cubit/auction_state.dart';
import 'package:root2route/models/auction_model.dart';
import 'package:root2route/services/api.dart';
import 'package:root2route/services/storage_service.dart';

/// Cubit handling all seller-side auction operations.
class AuctionCubit extends Cubit<AuctionState> {
  final ApiService _service;

  AuctionCubit({ApiService? service})
      : _service = service ?? ApiService(),
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
}

