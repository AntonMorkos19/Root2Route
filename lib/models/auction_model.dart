class AuctionModel {
  final String id;
  final String productId;
  final String? productName;
  final String? productImage;
  final double startingPrice;
  final double minimumBidIncrement;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // 'upcoming', 'active', 'ended'
  final int bidsCount;
  final double? currentHighestBid;
  final String? winnerId;
  final String? winnerName;
  final String? organizationId;
  final String? title;
  final double? reservePrice;

  const AuctionModel({
    required this.id,
    required this.productId,
    this.productName,
    this.productImage,
    required this.startingPrice,
    required this.minimumBidIncrement,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.bidsCount = 0,
    this.currentHighestBid,
    this.winnerId,
    this.winnerName,
    this.organizationId,
    this.title,
    this.reservePrice,
  });

  factory AuctionModel.fromJson(Map<String, dynamic> json) {
    return AuctionModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      productId: (json['productId'] ?? json['ProductId'] ?? '').toString(),
      productName: json['productName'] ?? json['ProductName'],
      productImage: json['productImage'] ??
          json['ProductImage'] ??
          json['productImageUrl'] ??
          json['ProductImageUrl'],
      // Logic for price keys (handling both startPrice and startingPrice)
      startingPrice: _parseDouble(
        json['startPrice'] ?? json['startingPrice'] ?? json['StartingPrice'],
      ),
      minimumBidIncrement: _parseDouble(
        json['minimumBidIncrement'] ?? json['MinimumBidIncrement'],
      ),
      startDate: _parseDate(json['startDate'] ?? json['StartDate']) ?? DateTime.now(),
      endDate: _parseDate(json['endDate'] ?? json['EndDate']) ?? DateTime.now(),
      status: _normalizeStatus(json['status'] ?? json['Status'] ?? ''),
      bidsCount: int.tryParse((json['bidsCount'] ?? json['BidsCount'] ?? 0).toString()) ?? 0,
      currentHighestBid: _parseNullableDouble(json['currentHighestBid'] ?? json['CurrentHighestBid']),
      winnerId: json['winnerId'] ?? json['WinnerId'],
      winnerName: json['winnerName'] ?? json['WinnerName'],
      organizationId: (json['organizationId'] ?? json['OrganizationId'] ?? '').toString(),
      title: json['title'] ?? json['Title'],
      reservePrice: _parseNullableDouble(json['reservePrice'] ?? json['ReservePrice']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'startPrice': startingPrice, // Matching server expectation
      'minimumBidIncrement': minimumBidIncrement,
      'startDate': startDate.toUtc().toIso8601String(),
      'endDate': endDate.toUtc().toIso8601String(),
      'title': title,
      'reservePrice': reservePrice,
    };
  }

  AuctionModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productImage,
    double? startingPrice,
    double? minimumBidIncrement,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int? bidsCount,
    double? currentHighestBid,
    String? winnerId,
    String? winnerName,
    String? organizationId,
    String? title,
    double? reservePrice,
  }) {
    return AuctionModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      startingPrice: startingPrice ?? this.startingPrice,
      minimumBidIncrement: minimumBidIncrement ?? this.minimumBidIncrement,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      bidsCount: bidsCount ?? this.bidsCount,
      currentHighestBid: currentHighestBid ?? this.currentHighestBid,
      winnerId: winnerId ?? this.winnerId,
      winnerName: winnerName ?? this.winnerName,
      organizationId: organizationId ?? this.organizationId,
      title: title ?? this.title,
      reservePrice: reservePrice ?? this.reservePrice,
    );
  }

  bool get isUpcoming => status == 'upcoming';
  bool get isActive => status == 'active';
  bool get isEnded => status == 'ended';
  bool get canEdit => isUpcoming;
  bool get canCancel => isUpcoming && bidsCount == 0;

  Duration get timeRemaining {
    final now = DateTime.now();
    if (isUpcoming) return startDate.isAfter(now) ? startDate.difference(now) : Duration.zero;
    if (isActive) return endDate.isAfter(now) ? endDate.difference(now) : Duration.zero;
    return Duration.zero;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static double? _parseNullableDouble(dynamic value) {
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  // Robust date parsing handling UTC strings (with or without 'Z' suffix)
  static DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    try {
      String dateStr = value.toString();
      
      if (!dateStr.endsWith('Z') && !dateStr.contains('+')) {
        dateStr += 'Z';
      }
      
      return DateTime.parse(dateStr).toLocal();
    } catch (_) {
      return null;
    }
  }

  // Robust status normalization mapping various API strings to internal states
  static String _normalizeStatus(dynamic raw) {
    final s = raw.toString().toLowerCase().trim();
    if (s.contains('upcoming') || s == '0') return 'upcoming';
    if (s.contains('active') || s.contains('live') || s.contains('ongoing') || s == '1') return 'active';
    if (s.contains('ended') || s.contains('closed') || s.contains('completed') || s == '2') return 'ended';
    return s.isEmpty ? 'upcoming' : s;
  }
}

class BidModel {
  final String id;
  final String auctionId;
  final String bidderId;
  final String bidderName;
  final double amount;
  final DateTime timestamp;

  const BidModel({
    required this.id,
    required this.auctionId,
    required this.bidderId,
    required this.bidderName,
    required this.amount,
    required this.timestamp,
  });

  factory BidModel.fromJson(Map<String, dynamic> json) {
    return BidModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      auctionId: (json['auctionId'] ?? json['AuctionId'] ?? '').toString(),
      bidderId: (json['bidderId'] ?? json['BidderId'] ?? json['userId'] ?? json['UserId'] ?? '').toString(),
      bidderName: (json['bidderName'] ?? json['BidderName'] ?? json['userName'] ?? json['UserName'] ?? 'Anonymous').toString(),
      amount: double.tryParse((json['amount'] ?? json['Amount'] ?? json['bidAmount'] ?? json['BidAmount'] ?? 0).toString()) ?? 0.0,
      timestamp: AuctionModel._parseDate(json['timestamp'] ?? json['Timestamp'] ?? json['createdAt'] ?? json['CreatedAt']) ?? DateTime.now(),
    );
  }
}

