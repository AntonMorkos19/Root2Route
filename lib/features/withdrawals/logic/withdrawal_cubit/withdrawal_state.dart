import 'package:root2route/features/withdrawals/data/models/withdrawal_model.dart';

/// Base state for all withdrawal-related cubit operations.
abstract class WithdrawalState {
  const WithdrawalState();
}

/// Initial / idle state before any action.
class WithdrawalInitial extends WithdrawalState {
  const WithdrawalInitial();
}

/// Indicates an async operation is in progress.
class WithdrawalLoading extends WithdrawalState {
  const WithdrawalLoading();
}

/// Successfully loaded a list of withdrawals.
class WithdrawalListLoaded extends WithdrawalState {
  final List<WithdrawalModel> withdrawals;
  const WithdrawalListLoaded(this.withdrawals);
}

/// A mutation (request/approve/reject/process) completed successfully.
class WithdrawalActionSuccess extends WithdrawalState {
  final String message;
  const WithdrawalActionSuccess(this.message);
}

/// An error occurred during any operation.
class WithdrawalError extends WithdrawalState {
  final String message;
  const WithdrawalError(this.message);
}
