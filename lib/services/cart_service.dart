import 'package:flutter/foundation.dart';

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  // Each item will be a Map: {"productId": String, "quantity": int, "name": String, "price": double}
  final List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => List.unmodifiable(_items);

  void addItem({
    required String productId,
    required String name,
    required double price,
    String? imageUrl,
    int quantity = 1,
  }) {
    final index = _items.indexWhere((item) => item['productId'] == productId);
    if (index >= 0) {
      // المنتج موجود بالفعل، لا نفعل شيئاً بناءً على طلب المستخدم
      return;
    } else {
      _items.add({
        "productId": productId,
        "name": name,
        "price": price,
        "imageUrl": imageUrl,
        "quantity": 1, // دائماً 1 لأن التاجر يبيع الكمية كاملة
      });
    }
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item['productId'] == productId);
  }

  void clearCart() {
    _items.clear();
  }

  double get totalPrice {
    return _items.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));
  }
}
