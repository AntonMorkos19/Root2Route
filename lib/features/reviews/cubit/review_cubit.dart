import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/features/reviews/cubit/review_state.dart';
import 'package:root2route/features/reviews/services/review_service.dart';

/// Cubit that manages submitting and fetching reviews.
///
/// POST /api/v1/reviews
/// GET  /api/v1/reviews/organization/{orgId}
class ReviewCubit extends Cubit<ReviewState> {
  final ReviewService _service = ReviewService();

  ReviewCubit() : super(const ReviewInitial());

  void _emitSafe(ReviewState state) {
    if (!isClosed) emit(state);
  }

  // ── POST /api/v1/reviews ────────────────────────────────────

  /// Submits a new review for a product/order.
  Future<void> submitReview({
    required String targetOrganizationId,
    required String orderId,
    required String productId,
    required int rating,
    required String comment,
  }) async {
    _emitSafe(const ReviewLoading());
    
    final result = await _service.submitReview(
      targetOrganizationId: targetOrganizationId,
      orderId: orderId,
      productId: productId,
      rating: rating,
      comment: comment,
    );

    if (result['success'] == true) {
      _emitSafe(ReviewSubmitSuccess(result['message']));
    } else {
      _emitSafe(ReviewError(result['message']));
    }
  }

  // ── GET /api/v1/reviews/organization/{orgId} ────────────────

  /// Fetches all reviews for a given organization.
  Future<void> fetchOrganizationReviews(String orgId) async {
    _emitSafe(const ReviewLoading());
    
    final result = await _service.fetchOrganizationReviews(orgId);

    if (result['success'] == true) {
      final respBody = result['data'];
      List<Map<String, dynamic>> reviews = [];

      if (respBody is Map && respBody['data'] is List) {
        reviews = (respBody['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else if (respBody is List) {
        reviews = respBody
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      _emitSafe(ReviewsLoaded(reviews));
    } else {
      _emitSafe(ReviewError(result['message']));
    }
  }

  /// Resets to initial state (useful when reopening the dialog).
  void reset() => _emitSafe(const ReviewInitial());
}
