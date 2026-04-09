/// Mirrors ProductResponse.cs from the backend exactly.
///
/// Backend fields:
///   Id, OrganizationId, Name, Description, Images (List<string>),
///   MainImageUrl, StockQuantity, IsAvailableForDirectSale, DirectSalePrice,
///   IsAvailableForAuction, StartBiddingPrice, Barcode, ExpiryDate,
///   WeightUnit, ProductType
class ProductModel {
  final String id;
  final String organizationId;
  final String name;
  final String? description;
  final List<String> images;
  final String? mainImageUrl;
  final int stockQuantity;
  final bool isAvailableForDirectSale;
  final double directSalePrice;
  final bool isAvailableForAuction;
  final double startBiddingPrice;
  final String? barcode;
  final DateTime? expiryDate;
  final String? weightUnit;
  final String? productType;

  const ProductModel({
    required this.id,
    required this.organizationId,
    required this.name,
    this.description,
    this.images = const [],
    this.mainImageUrl,
    required this.stockQuantity,
    required this.isAvailableForDirectSale,
    required this.directSalePrice,
    required this.isAvailableForAuction,
    required this.startBiddingPrice,
    this.barcode,
    this.expiryDate,
    this.weightUnit,
    this.productType,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      organizationId:
          (json['organizationId'] ?? json['OrganizationId'] ?? '').toString(),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      description: json['description'] ?? json['Description'],
      images: _parseImages(json['images'] ?? json['Images']),
      mainImageUrl: json['mainImageUrl'] ?? json['MainImageUrl'],
      stockQuantity:
          int.tryParse((json['stockQuantity'] ?? json['StockQuantity'] ?? 0)
                  .toString()) ??
              0,
      isAvailableForDirectSale:
          json['isAvailableForDirectSale'] ??
          json['IsAvailableForDirectSale'] ??
          false,
      directSalePrice:
          double.tryParse(
                  (json['directSalePrice'] ?? json['DirectSalePrice'] ?? 0)
                      .toString()) ??
              0.0,
      isAvailableForAuction:
          json['isAvailableForAuction'] ??
          json['IsAvailableForAuction'] ??
          false,
      startBiddingPrice:
          double.tryParse(
                  (json['startBiddingPrice'] ?? json['StartBiddingPrice'] ?? 0)
                      .toString()) ??
              0.0,
      barcode: json['barcode'] ?? json['Barcode'],
      expiryDate: _parseDate(json['expiryDate'] ?? json['ExpiryDate']),
      weightUnit: json['weightUnit'] ?? json['WeightUnit'],
      productType: json['productType'] ?? json['ProductType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organizationId': organizationId,
      'name': name,
      'description': description,
      'images': images,
      'mainImageUrl': mainImageUrl,
      'stockQuantity': stockQuantity,
      'isAvailableForDirectSale': isAvailableForDirectSale,
      'directSalePrice': directSalePrice,
      'isAvailableForAuction': isAvailableForAuction,
      'startBiddingPrice': startBiddingPrice,
      'barcode': barcode,
      'expiryDate': expiryDate?.toIso8601String(),
      'weightUnit': weightUnit,
      'productType': productType,
    };
  }

  static List<String> _parseImages(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return [];
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null || raw.toString().isEmpty) return null;
    try {
      return DateTime.parse(raw.toString());
    } catch (_) {
      return null;
    }
  }

  /// Display price: prefers direct sale, falls back to starting bid.
  String get displayPrice {
    if (isAvailableForDirectSale && directSalePrice > 0) {
      return '\$${directSalePrice.toStringAsFixed(2)}';
    }
    if (isAvailableForAuction && startBiddingPrice > 0) {
      return 'Bid from \$${startBiddingPrice.toStringAsFixed(2)}';
    }
    return 'Price on request';
  }

  /// Availability badge label.
  String get badgeText =>
      isAvailableForDirectSale ? 'For Sale' : 'Auction Only';
}

/// Thrown by [ApiService] when a product request fails.
class ProductException implements Exception {
  final String message;
  const ProductException(this.message);

  @override
  String toString() => 'ProductException: $message';
}
