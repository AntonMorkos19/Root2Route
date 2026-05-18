abstract class CartState {
  final List<Map<String, dynamic>> cartItems;
  const CartState(this.cartItems);
}

class CartInitial extends CartState {
  const CartInitial() : super(const []);
}

class CartLoading extends CartState {
  const CartLoading(super.cartItems);
}

class CartLoaded extends CartState {
  const CartLoaded(super.cartItems);
}

class CartError extends CartState {
  final String message;
  const CartError(this.message, super.cartItems);
}
