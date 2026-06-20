import 'package:root2route/features/shipments/data/models/shipment_address_model.dart';

/// Base state for all shipment-related cubits.
abstract class ShipmentState {
  const ShipmentState();
}

/// Initial / idle state.
class ShipmentInitial extends ShipmentState {
  const ShipmentInitial();
}

/// In-progress loading/submitting state.
class ShipmentLoading extends ShipmentState {
  const ShipmentLoading();
}

/// Successfully loaded a list of shipment addresses.
class ShipmentAddressesLoaded extends ShipmentState {
  final List<ShipmentAddressModel> addresses;
  const ShipmentAddressesLoaded(this.addresses);
}

/// A mutation action completed successfully (dispatch, status update, add address).
class ShipmentActionSuccess extends ShipmentState {
  final String message;
  const ShipmentActionSuccess(this.message);
}

/// Error state with a user-visible message.
class ShipmentError extends ShipmentState {
  final String message;
  const ShipmentError(this.message);
}
