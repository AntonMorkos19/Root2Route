import 'package:root2route/models/order_model.dart';

/// Base state for all order-related cubits.
abstract class OrderState {
  const OrderState();
}

/// Initial / idle state before any fetch.
class OrderInitial extends OrderState {
  const OrderInitial();
}

/// In-progress loading state.
class OrderLoading extends OrderState {
  const OrderLoading();
}

/// Successfully loaded a list of orders.
class OrderListLoaded extends OrderState {
  final List<OrderModel> orders;
  const OrderListLoaded(this.orders);
}

/// Successfully loaded a single order.
class OrderDetailLoaded extends OrderState {
  final OrderModel order;
  const OrderDetailLoaded(this.order);
}

/// A mutating action succeeded (e.g. status change).
class OrderActionSuccess extends OrderState {
  final String message;
  const OrderActionSuccess(this.message);
}

/// Error state with user-visible message.
class OrderError extends OrderState {
  final String message;
  const OrderError(this.message);
}
