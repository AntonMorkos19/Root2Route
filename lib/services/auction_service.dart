// import 'package:dio/dio.dart';
// import 'package:root2route/services/api.dart';
// import '../models/auction_model.dart';

// /// Dedicated service for all auction-related API calls.
// /// Reuses the existing ApiService's Dio instance — auth headers
// /// (Authorization + X-Organization-Id) are already injected by interceptors.
// class AuctionService {
//   final Dio _dio;

//   AuctionService() : _dio = ApiService().dio;

//   // ── CREATE AUCTION ─────────────────────────────────────
//   // POST /api/v1/auctions
//   Future<AuctionModel> createAuction({
//     required String title,
//     required String productId,
//     required double startingPrice,
//     required double minimumBidIncrement,
//     required double reservePrice,
//     required DateTime startDate,
//     required DateTime endDate,
//   }) async {
//     try {
//       final response = await _dio.post(
//         '/auctions',
//         data: {
//           'title': title,
//           'productId': productId,
//           'startPrice': startingPrice,
//           'minimumBidIncrement': minimumBidIncrement,
//           'reservePrice': reservePrice,
//           'startDate': startDate.toUtc().toIso8601String(),
//           'endDate': endDate.toUtc().toIso8601String(),
//         },
//       );
//       final data = _extractData(response.data);
//       if (data is Map<String, dynamic>) {
//         return AuctionModel.fromJson(data);
//       }
//       return AuctionModel(
//         id: data?.toString() ?? '',
//         title: title,
//         productId: productId,
//         startingPrice: startingPrice,
//         minimumBidIncrement: minimumBidIncrement,
//         reservePrice: reservePrice,
//         startDate: startDate,
//         endDate: endDate,
//         status: 'upcoming',
//       );
//     } on DioException catch (e) {
//       throw AuctionException(_extractApiError(e));
//     } catch (e) {
//       throw AuctionException('Failed to create auction: $e');
//     }
//   }

//   // ── GET MY ORGANIZATION AUCTIONS ───────────────────────
//   // GET /api/v1/auctions/my-organization/{organizationId}
//   Future<List<AuctionModel>> getMyOrganizationAuctions(
//       String organizationId) async {
//     try {
//       final response =
//           await _dio.get('/auctions/my-organization/$organizationId');
//       return _parseList(response.data)
//           .map((json) => AuctionModel.fromJson(json))
//           .toList();
//     } on DioException catch (e) {
//       throw AuctionException(_extractApiError(e));
//     } catch (e) {
//       throw AuctionException('Failed to fetch auctions: $e');
//     }
//   }

//   // ── UPDATE AUCTION ─────────────────────────────────────
//   // PUT /api/v1/auctions/{auctionId}/update
//   Future<AuctionModel> updateAuction({
//     required String auctionId,
//     required double startingPrice,
//     required double minimumBidIncrement,
//     required DateTime startDate,
//     required DateTime endDate,
//   }) async {
//     try {
//       final response = await _dio.put(
//         '/auctions/$auctionId/update',
//         data: {
//           'startingPrice': startingPrice,
//           'minimumBidIncrement': minimumBidIncrement,
//           'startDate': startDate.toUtc().toIso8601String(),
//           'endDate': endDate.toUtc().toIso8601String(),
//         },
//       );
//       final data = _extractData(response.data);
//       if (data is Map<String, dynamic>) {
//         return AuctionModel.fromJson(data);
//       }
//       return AuctionModel(
//         id: auctionId,
//         productId: '',
//         startingPrice: startingPrice,
//         minimumBidIncrement: minimumBidIncrement,
//         startDate: startDate,
//         endDate: endDate,
//         status: 'upcoming',
//       );
//     } on DioException catch (e) {
//       throw AuctionException(_extractApiError(e));
//     } catch (e) {
//       throw AuctionException('Failed to update auction: $e');
//     }
//   }

//   // ── CANCEL AUCTION ─────────────────────────────────────
//   // DELETE /api/v1/auctions/{auctionId}/cancel
//   Future<void> cancelAuction(String auctionId) async {
//     try {
//       await _dio.delete('/auctions/$auctionId/cancel');
//     } on DioException catch (e) {
//       throw AuctionException(_extractApiError(e));
//     } catch (e) {
//       throw AuctionException('Failed to cancel auction: $e');
//     }
//   }

//   // ── GET BID HISTORY ────────────────────────────────────
//   // GET /api/v1/auctions/{auctionId}/bids
//   Future<List<BidModel>> getBidHistory(String auctionId) async {
//     try {
//       final response = await _dio.get('/auctions/$auctionId/bids');
//       return _parseList(response.data)
//           .map((json) => BidModel.fromJson(json))
//           .toList();
//     } on DioException catch (e) {
//       throw AuctionException(_extractApiError(e));
//     } catch (e) {
//       throw AuctionException('Failed to fetch bid history: $e');
//     }
//   }

//   // ── GET APPROVED PRODUCTS (for create-auction dropdown) ─
//   Future<List<Map<String, dynamic>>> getApprovedProducts(
//       String organizationId) async {
//     try {
//       final response = await _dio.get(
//         '/product/Organization/$organizationId',
//         queryParameters: {'Status': 1},
//       );
//       return _parseList(response.data);
//     } on DioException catch (e) {
//       throw AuctionException(_extractApiError(e));
//     } catch (e) {
//       throw AuctionException('Failed to fetch products: $e');
//     }
//   }

//   // ── Helpers ────────────────────────────────────────────

//   dynamic _extractData(dynamic body) {
//     if (body is Map) return body['data'] ?? body;
//     return body;
//   }

//   /// Extracts a List<Map<String,dynamic>> from various backend wrappers.
//   List<Map<String, dynamic>> _parseList(dynamic body) {
//     List<dynamic> items = [];
//     if (body is Map) {
//       final dataField = body['data'] ?? body;
//       if (dataField is List) {
//         items = dataField;
//       } else if (dataField is Map && dataField.containsKey('items')) {
//         items = (dataField['items'] as List?) ?? [];
//       }
//     } else if (body is List) {
//       items = body;
//     }
//     return items.whereType<Map<String, dynamic>>().toList();
//   }

//   String _extractApiError(DioException e) {
//     if (e.response == null) {
//       return 'No Internet Connection — please check your network';
//     }
//     dynamic errorData = e.response?.data;
//     String message = 'Something went wrong';

//     if (errorData is Map) {
//       message = errorData['message'] ??
//           errorData['msg'] ??
//           errorData['error'] ??
//           errorData['title'] ??
//           message;
//       if (errorData['errors'] != null) {
//         final errors = errorData['errors'];
//         if (errors is Map && errors.isNotEmpty) {
//           final first = errors.values.first;
//           message = (first is List && first.isNotEmpty)
//               ? first[0].toString()
//               : first.toString();
//         } else if (errors is List && errors.isNotEmpty) {
//           message = errors[0].toString();
//         }
//       }
//     } else if (errorData is String && errorData.isNotEmpty) {
//       message = errorData;
//     } else if (e.response?.statusMessage != null) {
//       message =
//           'Server Error: ${e.response?.statusMessage} (${e.response?.statusCode})';
//     }
//     if (message == 'Something went wrong' && errorData != null) {
//       message = 'Error: ${errorData.toString()}';
//     }
//     return message;
//   }
// }

// /// Exception thrown by [AuctionService].
// class AuctionException implements Exception {
//   final String message;
//   const AuctionException(this.message);

//   @override
//   String toString() => message;
// }
