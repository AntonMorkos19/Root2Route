import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/features/cart/cubit/cart_state.dart';
import 'package:root2route/services/cart_service.dart';

class CartCubit extends Cubit<CartState> {
  final CartService _cartService = CartService();

  CartCubit() : super(CartInitial()) {
    loadCart();
  }

  void loadCart() {
    emit(CartLoaded(List.from(_cartService.items)));
  }

  void addItem({
    required String productId,
    required String name,
    required double price,
    String? imageUrl,
    int quantity = 1,
  }) {
    _cartService.addItem(
      productId: productId,
      name: name,
      price: price,
      imageUrl: imageUrl,
      quantity: quantity,
    );
    emit(CartLoaded(List.from(_cartService.items)));
  }

  void removeItem(String productId) {
    _cartService.removeItem(productId);
    emit(CartLoaded(List.from(_cartService.items)));
  }

  void clearCart() {
    _cartService.clearCart();
    emit(CartLoaded(List.from(_cartService.items)));
  }
}
