/// Represents a shipment address returned by /api/v1/shipments/addresses.
class ShipmentAddressModel {
  final int? id;
  final String fullName;
  final String phone;
  final String city;
  final String street;
  final String buildingNumber;
  final String notes;
  final bool isDefault;

  const ShipmentAddressModel({
    this.id,
    this.fullName = '',
    this.phone = '',
    this.city = '',
    this.street = '',
    this.buildingNumber = '',
    this.notes = '',
    this.isDefault = false,
  });

  factory ShipmentAddressModel.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'] ?? json['Id'] ?? json['addressId'] ?? json['AddressId'];
    return ShipmentAddressModel(
      id: idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? ''),
      fullName:
          (json['label'] ?? json['fullName'] ?? json['FullName'] ?? '').toString(),
      phone:
          (json['phone'] ?? json['Phone'] ?? json['contactPhone'] ?? json['ContactPhone'] ?? '')
              .toString(),
      city: (json['city'] ?? json['City'] ?? '').toString(),
      street: (json['street'] ?? json['Street'] ?? '').toString(),
      buildingNumber:
          (json['buildingNumber'] ?? json['BuildingNumber'] ?? '').toString(),
      notes: (json['notes'] ?? json['Notes'] ?? '').toString(),
      isDefault:
          json['isDefault'] as bool? ?? json['IsDefault'] as bool? ?? false,
    );
  }

  /// Exports to JSON.
  /// Using PascalCase keys as they are common in this project's POST requests.
  Map<String, dynamic> toJson() => {
    'Label': fullName,
    'Phone': phone,
    'City': city,
    'Street': street,
    'BuildingNumber': buildingNumber,
    'Notes': notes,
    'IsDefault': isDefault,
  };
}
