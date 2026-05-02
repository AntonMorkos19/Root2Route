import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/models/auction_model.dart';
import 'package:root2route/services/auction_service.dart';
import 'package:root2route/services/api.dart';
import 'package:root2route/services/storage_service.dart';
import 'auction_state.dart';

/// Cubit handling all seller-side auction operations.
class AuctionCubit extends Cubit<AuctionState> {
  final ApiService _service;

  AuctionCubit({ApiService? service})
    : _service = service ?? ApiService(),
      super(const AuctionInitial());

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
    emit(const AuctionLoading());
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
      emit(AuctionSuccess<AuctionModel>(auction));
    } on AuctionException catch (e) {
      emit(AuctionError(e.message));
    } catch (e) {
      emit(AuctionError(e.toString()));
    }
  }

  // ──────────────────────────────────────────────────────
  // FETCH MY ORGANIZATION AUCTIONS (Dashboard)
  // ──────────────────────────────────────────────────────
  Future<void> fetchMyAuctions(String organizationId) async {
    emit(const AuctionLoading());
    try {
      final auctions = await _service.getMyOrganizationAuctions(organizationId);

      final upcoming =
          auctions.where((a) => a.status.toLowerCase() == 'upcoming').toList();
      final active = auctions.where((a) {
        final s = a.status.toLowerCase();
        return s == 'active' || s == 'ongoing';
      }).toList();
      final ended =
          auctions.where((a) => a.status.toLowerCase() == 'ended').toList();

      emit(AuctionDashboardLoaded(upcoming, active, ended));
    } on AuctionException catch (e) {
      emit(AuctionError(e.message));
    } catch (e) {
      emit(AuctionError(e.toString()));
    }
  }

  // ──────────────────────────────────────────────────────
  // FETCH AUCTIONS DYNAMICALLY (Auto-fetch Org ID)
  // ──────────────────────────────────────────────────────
  Future<void> fetchAuctionsDynamically() async {
    emit(const AuctionLoading());
    try {
      String orgId = StorageService().organizationId ?? '';

      if (orgId.isEmpty) {
        // Fetch organization data using ApiService
        final apiService = ApiService();
        final response = await apiService.getMyOrganizations();

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
        emit(const AuctionError('No Organization ID found for the user.'));
        return;
      }

      final auctions = await _service.getMyOrganizationAuctions(orgId);

      final upcoming =
          auctions.where((a) => a.status.toLowerCase() == 'upcoming').toList();
      final active =
          auctions.where((a) => a.status.toLowerCase() == 'active').toList();
      final ended =
          auctions.where((a) => a.status.toLowerCase() == 'ended').toList();

      emit(AuctionDashboardLoaded(upcoming, active, ended));
    } on AuctionException catch (e) {
      emit(AuctionError(e.message));
    } catch (e) {
      emit(AuctionError(e.toString()));
    }
  }

  // ──────────────────────────────────────────────────────
  // UPDATE AUCTION
  // ──────────────────────────────────────────────────────
  Future<void> updateAuction({
    required String auctionId,
    required double startingPrice,
    required double minimumBidIncrement,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    emit(const AuctionLoading());
    try {
      final updated = await _service.updateAuction(
        auctionId: auctionId,
        startingPrice: startingPrice,
        minimumBidIncrement: minimumBidIncrement,
        startDate: startDate,
        endDate: endDate,
      );
      emit(AuctionSuccess<AuctionModel>(updated));
    } on AuctionException catch (e) {
      emit(AuctionError(e.message));
    } catch (e) {
      emit(AuctionError(e.toString()));
    }
  }

  // ──────────────────────────────────────────────────────
  // CANCEL AUCTION
  // ──────────────────────────────────────────────────────
  Future<void> cancelAuction(String auctionId) async {
    emit(const AuctionLoading());
    try {
      await _service.cancelAuction(auctionId);
      emit(const AuctionSuccess<String>('Auction cancelled successfully'));
    } on AuctionException catch (e) {
      emit(AuctionError(e.message));
    } catch (e) {
      emit(AuctionError(e.toString()));
    }
  }

  // ──────────────────────────────────────────────────────
  // FETCH BID HISTORY
  // ──────────────────────────────────────────────────────
  Future<void> fetchBids({
    required String auctionId,
    required AuctionModel auction,
  }) async {
    emit(const AuctionLoading());
    try {
      final bids = await _service.getBidHistory(auctionId);
      // Sort descending by amount (highest first)
      bids.sort((a, b) => b.amount.compareTo(a.amount));
      emit(BidHistoryLoaded(bids: bids, auction: auction));
    } on AuctionException catch (e) {
      emit(AuctionError(e.message));
    } catch (e) {
      emit(AuctionError(e.toString()));
    }
  }

  // ──────────────────────────────────────────────────────
  // FETCH APPROVED PRODUCTS (for create-auction dropdown)
  // ──────────────────────────────────────────────────────
  Future<void> fetchApprovedProducts(String organizationId) async {
    emit(const AuctionLoading());
    try {
      final products = await _service.getApprovedProducts(organizationId);
      emit(AuctionSuccess<List<Map<String, dynamic>>>(products));
    } on AuctionException catch (e) {
      emit(AuctionError(e.message));
    } catch (e) {
      emit(AuctionError(e.toString()));
    }
  }
}
