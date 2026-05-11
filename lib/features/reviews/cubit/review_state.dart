/// Base state for all review-related cubits.
abstract class ReviewState {
  const ReviewState();
}

/// Initial / idle state.
class ReviewInitial extends ReviewState {
  const ReviewInitial();
}

/// In-progress loading/submitting state.
class ReviewLoading extends ReviewState {
  const ReviewLoading();
}

/// Successfully submitted a review.
class ReviewSubmitSuccess extends ReviewState {
  final String message;
  const ReviewSubmitSuccess(this.message);
}

/// Successfully loaded a list of reviews for an organization.
class ReviewsLoaded extends ReviewState {
  final List<Map<String, dynamic>> reviews;
  const ReviewsLoaded(this.reviews);
}

/// Error state with a user-visible message.
class ReviewError extends ReviewState {
  final String message;
  const ReviewError(this.message);
}
