class ProductModel {
  final String? id;
  final String name;
  final String? description;
  final int stockQuantity;
  final bool isAvailableForDirectSale;
  final double directSalePrice;
  final bool isAvailableForAuction;
  final double startBiddingPrice;
  final String? expiryDate;
  final String? barcode;
  final int weightUnit;
  final int productType;
  final List<dynamic>? images;

  ProductModel({
    this.id,
    required this.name,
    this.description,
    required this.stockQuantity,
    this.isAvailableForDirectSale = false,
    this.directSalePrice = 0.0,
    this.isAvailableForAuction = false,
    this.startBiddingPrice = 0.0,
    this.expiryDate,
    this.barcode,
    this.weightUnit = 0,
    this.productType = 0,
    this.images,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? json['Id']?.toString(),
      name: json['name']?.toString() ?? json['Name']?.toString() ?? '',
      description: json['description']?.toString() ?? json['Description']?.toString(),
      stockQuantity: int.tryParse(json['stockQuantity']?.toString() ?? json['StockQuantity']?.toString() ?? '0') ?? 0,
      isAvailableForDirectSale: json['isAvailableForDirectSale'] ?? json['IsAvailableForDirectSale'] ?? false,
      directSalePrice: double.tryParse(json['directSalePrice']?.toString() ?? json['DirectSalePrice']?.toString() ?? '0') ?? 0.0,
      isAvailableForAuction: json['isAvailableForAuction'] ?? json['IsAvailableForAuction'] ?? false,
      startBiddingPrice: double.tryParse(json['startBiddingPrice']?.toString() ?? json['StartBiddingPrice']?.toString() ?? '0') ?? 0.0,
      expiryDate: json['expiryDate']?.toString() ?? json['ExpiryDate']?.toString(),
      barcode: json['barcode']?.toString() ?? json['Barcode']?.toString(),
      weightUnit: int.tryParse(json['weightUnit']?.toString() ?? json['WeightUnit']?.toString() ?? '0') ?? 0,
      productType: int.tryParse(json['productType']?.toString() ?? json['ProductType']?.toString() ?? '0') ?? 0,
      images: json['images'] ?? json['Images'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'stockQuantity': stockQuantity,
      'isAvailableForDirectSale': isAvailableForDirectSale,
      'directSalePrice': directSalePrice,
      'isAvailableForAuction': isAvailableForAuction,
      'startBiddingPrice': startBiddingPrice,
      'expiryDate': expiryDate,
      'barcode': barcode,
      'weightUnit': weightUnit,
      'productType': productType,
      if (images != null) 'images': images,
    };
  }
}