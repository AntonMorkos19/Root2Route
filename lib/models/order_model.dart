class OrderItemModel {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String organizationId;
  final String unitName;

  OrderItemModel({
    this.productId = '',
    this.productName = 'Unknown',
    this.quantity = 1,
    this.unitPrice = 0.0,
    this.totalPrice = 0.0,
    this.organizationId = '',
    this.unitName = '',
  });

  String get quantityWithUnit {
    if (unitName.isEmpty) {
      return '$quantity';
    }
    return '$quantity $unitName';
  }

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final qtyRaw = json['quantity'] ?? json['Quantity'] ?? 1;
    final unitRaw = json['unitPrice'] ?? json['UnitPrice'] ?? json['price'] ?? json['Price'] ?? 0;
    final totalRaw = json['totalPrice'] ?? json['TotalPrice'] ?? 0;

    final unitNameRaw = json['unitName'] ?? json['UnitName'] ?? json['unit'] ?? json['Unit'];
    final weightUnitRaw = json['weightUnit'] ?? json['WeightUnit'];

    String parsedUnitName = '';
    if (unitNameRaw != null && unitNameRaw.toString().trim().isNotEmpty) {
      parsedUnitName = unitNameRaw.toString().trim();
    } else if (weightUnitRaw != null) {
      final idx = int.tryParse(weightUnitRaw.toString());
      if (idx != null) {
        switch (idx) {
          case 0:
            parsedUnitName = 'Kg';
            break;
          case 1:
            parsedUnitName = 'pkg';
            break;
          case 2:
            parsedUnitName = 'Liter';
            break;
          default:
            parsedUnitName = '';
        }
      }
    }

    return OrderItemModel(
      productId: (json['productId'] ?? json['ProductId'] ?? '').toString(),
      productName: (json['productName'] ?? json['ProductName'] ?? json['name'] ?? json['Name'] ?? 'Unknown').toString(),
      quantity: qtyRaw is num ? qtyRaw.toInt() : int.tryParse(qtyRaw.toString()) ?? 1,
      unitPrice: unitRaw is num ? unitRaw.toDouble() : double.tryParse(unitRaw.toString()) ?? 0.0,
      totalPrice: totalRaw is num ? totalRaw.toDouble() : double.tryParse(totalRaw.toString()) ?? 0.0,
      organizationId: (json['organizationId'] ?? json['OrganizationId'] ?? '').toString(),
      unitName: parsedUnitName,
    );
  }
}

class OrderModel {
  final String id;
  final String buyerId;
  final String buyerName;
  final String receiverName;
  final String receiverPhone;
  final String shippingCity;
  final String shippingStreet;
  final String buildingNumber;
  final String organizationName;
  final int status; // 0=Pending, 1=Confirmed, 2=Shipped, 3=Delivered, 4=Cancelled
  final String note;
  final double totalAmount;
  final DateTime? createdAt;
  final List<OrderItemModel> items;
  final String organizationId;
  final int? shipmentId;
  final String? carrier;
  final String? trackingNumber;
  final String? driverPhone;

  OrderModel({
    required this.id,
    this.buyerId = '',
    this.buyerName = 'Unknown',
    this.receiverName = 'Unknown',
    this.receiverPhone = '',
    this.shippingCity = '',
    this.shippingStreet = '',
    this.buildingNumber = '',
    this.organizationName = 'Unknown',
    this.status = 0,
    this.note = '',
    this.totalAmount = 0.0,
    this.createdAt,
    this.items = const [],
    this.organizationId = '',
    this.shipmentId,
    this.carrier,
    this.trackingNumber,
    this.driverPhone,
  });

  static int _parseStatus(dynamic raw) {
    if (raw is int) return raw;
    switch (raw.toString().toLowerCase()) {
      case 'pending':   return 0;
      case 'confirmed': return 1;
      case 'shipped':   return 2;
      case 'delivered': return 3;
      case 'cancelled': return 4;
      default: return int.tryParse(raw.toString()) ?? 0;
    }
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'] ?? json['Id'] ?? json['orderId'] ?? json['OrderId'] ?? '';
    final statusRaw = json['status'] ?? json['Status'] ?? json['orderStatus'] ?? json['OrderStatus'] ?? 0;
    final totalRaw = json['finalTotal'] ?? json['FinalTotal'] ?? json['totalAmount'] ?? json['TotalAmount'] ?? json['totalPrice'] ?? json['TotalPrice'] ?? 0;

    // Parse items list safely
    final itemsRaw = json['items'] ?? json['Items'] ?? json['orderItems'] ?? json['OrderItems'];
    final List<OrderItemModel> parsedItems = [];
    if (itemsRaw != null && itemsRaw is List) {
      for (final item in itemsRaw) {
        if (item is Map<String, dynamic>) {
          parsedItems.add(OrderItemModel.fromJson(item));
        }
      }
    }

    // Parse date safely
    DateTime? parsedDate;
    final dateStr = json['orderDate'] ?? json['OrderDate'] ?? json['createdAt'] ?? json['CreatedAt'] ?? json['createdOn'] ?? json['CreatedOn'];
    if (dateStr != null && dateStr is String && dateStr.isNotEmpty) {
      try {
        String normalized = dateStr;
        if (!normalized.endsWith('Z') && !normalized.contains('+')) {
          normalized += 'Z';
        }
        parsedDate = DateTime.parse(normalized).toLocal();
      } catch (_) {}
    }

    // Parse shipmentId safely
    final shipmentIdRaw = json['shipmentId'] ?? json['ShipmentId'];
    int? parsedShipmentId;
    if (shipmentIdRaw != null) {
      parsedShipmentId = shipmentIdRaw is int
          ? shipmentIdRaw
          : int.tryParse(shipmentIdRaw.toString());
    }

    return OrderModel(
      id: idRaw.toString(),
      buyerId: (json['buyerId'] ?? json['BuyerId'] ?? '').toString(),
      buyerName: (json['buyerName'] ?? json['BuyerName'] ?? 'Unknown').toString(),
      receiverName: (json['receiverName'] ?? json['ReceiverName'] ?? 'Unknown').toString(),
      receiverPhone: (json['receiverPhone'] ?? json['ReceiverPhone'] ?? '').toString(),
      shippingCity: (json['shippingCity'] ?? json['ShippingCity'] ?? '').toString(),
      shippingStreet: (json['shippingStreet'] ?? json['ShippingStreet'] ?? '').toString(),
      buildingNumber: (json['buildingNumber'] ?? json['BuildingNumber'] ?? '').toString(),
      organizationName: (json['organizationName'] ?? json['OrganizationName'] ?? 'Unknown').toString(),
      status: _parseStatus(statusRaw),
      note: (json['note'] ?? json['Note'] ?? '').toString(),
      totalAmount: totalRaw is num ? totalRaw.toDouble() : double.tryParse(totalRaw.toString()) ?? 0.0,
      createdAt: parsedDate,
      items: parsedItems,
      organizationId: (json['organizationId'] ?? json['OrganizationId'] ?? '').toString(),
      shipmentId: parsedShipmentId,
      carrier: (json['carrier'] ?? json['Carrier'] ?? json['carrierName'] ?? json['CarrierName'])?.toString(),
      trackingNumber: (json['trackingNumber'] ?? json['TrackingNumber'])?.toString(),
      driverPhone: (json['driverPhone'] ?? json['DriverPhone'])?.toString(),
    );
  }

  /// Helper to get human-readable status string
  String get statusText {
    switch (status) {
      case 0:
        return 'Pending';
      case 1:
        return 'Confirmed';
      case 2:
        return 'Shipped';
      case 3:
        return 'Delivered';
      case 4:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
}
