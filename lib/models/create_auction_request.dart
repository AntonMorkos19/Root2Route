class CreateAuctionRequest {
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final double startPrice;
  final double minimumBidIncrement;
  final double reservePrice;
  final String productId;

  CreateAuctionRequest({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.startPrice,
    required this.minimumBidIncrement,
    required this.reservePrice,
    required this.productId,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'startDate': startDate.toUtc().toIso8601String(),
      'endDate': endDate.toUtc().toIso8601String(),
      'startPrice': startPrice,
      'minimumBidIncrement': minimumBidIncrement,
      'reservePrice': reservePrice,
      'productId': productId,
    };
  }
}
