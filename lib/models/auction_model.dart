class AuctionModel {
  final String id;
  final String title;
  final DateTime? startDate;
  final DateTime? endDate;
  final double startingBid;
  final double currentBid;

  AuctionModel({
    required this.id,
    required this.title,
    this.startDate,
    this.endDate,
    required this.startingBid,
    required this.currentBid,
  });

  factory AuctionModel.fromJson(Map<String, dynamic> json) {
    // Parse dates to local time as required
    DateTime? parsedStartDate;
    DateTime? parsedEndDate;

    final rawStart = json['startDate'] ?? json['StartDate'];
    if (rawStart != null && rawStart.toString().isNotEmpty) {
      try {
        parsedStartDate = DateTime.parse(rawStart.toString()).toLocal();
      } catch (_) {}
    }

    final rawEnd = json['endDate'] ?? json['EndDate'];
    if (rawEnd != null && rawEnd.toString().isNotEmpty) {
      try {
        parsedEndDate = DateTime.parse(rawEnd.toString()).toLocal();
      } catch (_) {}
    }

    final rawStartBid = json['startingBid'] ??
        json['StartingBid'] ??
        json['startBiddingPrice'] ??
        0;
        
    final rawCurrentBid = json['currentBid'] ??
        json['CurrentBid'] ??
        json['currentBiddingPrice'] ??
        0;

    return AuctionModel(
      id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
      title: json['title'] ?? json['Title'] ?? 'Auction',
      startDate: parsedStartDate,
      endDate: parsedEndDate,
      startingBid: double.tryParse(rawStartBid.toString()) ?? 0.0,
      currentBid: double.tryParse(rawCurrentBid.toString()) ?? 0.0,
    );
  }
}
