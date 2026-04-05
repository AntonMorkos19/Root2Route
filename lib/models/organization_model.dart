class OrganizationModel {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final String? contactEmail;
  final String? contactPhone;
  final String? logoUrl;
  final int type;

  OrganizationModel({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.contactEmail,
    this.contactPhone,
    this.logoUrl,
    required this.type,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
     final String parsedId = json['organizationId']?.toString() ?? 
                            json['OrganizationId']?.toString() ?? 
                            json['id']?.toString() ?? 
                            json['Id']?.toString() ?? 
                            '';

    return OrganizationModel(
      id: parsedId,
       name: json['name']?.toString() ?? json['Name']?.toString() ?? '',
      description: json['description']?.toString() ?? json['Description']?.toString(),
      address: json['address']?.toString() ?? json['Address']?.toString(),
      contactEmail: json['contactEmail']?.toString() ?? json['ContactEmail']?.toString(),
      contactPhone: json['contactPhone']?.toString() ?? json['ContactPhone']?.toString(),
      logoUrl: json['logoUrl']?.toString() ?? json['LogoUrl']?.toString(),
       type: int.tryParse(json['type']?.toString() ?? json['Type']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "description": description,
      "address": address,
      "contactEmail": contactEmail,
      "contactPhone": contactPhone,
      "logoUrl": logoUrl,
      "type": type,
    };
  }

   String get typeName {
    switch (type) {
      case 0:
        return 'Farmer';
      case 1:
        return 'Restaurant';
      case 2:
        return 'Factory';
      case 3:
        return 'Tradesman';
      default:
        return 'Unknown';
    }
  }
}

class OrganizationStatisticsModel {
  final int totalMembers;
  final int totalProducts;
  final int totalOrders;
  final int totalFarms;
  
  OrganizationStatisticsModel({
    required this.totalMembers,
    required this.totalProducts,
    required this.totalOrders,
    required this.totalFarms,
  });

  factory OrganizationStatisticsModel.fromJson(Map<String, dynamic> json) {
    return OrganizationStatisticsModel(
      totalMembers: json['membersCount'] ?? json['MembersCount'] ?? 0,
      totalProducts: json['marketItemsCount'] ?? json['MarketItemsCount'] ?? 0,
      totalOrders: json['totalOrders'] ?? json['TotalOrders'] ?? 0,
      totalFarms: json['totalFarms'] ?? json['TotalFarms'] ?? 0,
    );
  }
}
