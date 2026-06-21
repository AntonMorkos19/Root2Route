import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/features/withdrawals/data/repositories/withdrawal_repository.dart';
import 'package:root2route/features/withdrawals/logic/withdrawal_cubit/withdrawal_state.dart';

/// Cubit that orchestrates all withdrawal operations.
/// All business logic lives here — screens only dispatch actions and observe states.
class WithdrawalCubit extends Cubit<WithdrawalState> {
  final WithdrawalRepository _repo;

  WithdrawalCubit({WithdrawalRepository? repository})
      : _repo = repository ?? WithdrawalRepository(),
        super(const WithdrawalInitial());

  /// Safety wrapper — prevents state emission after the cubit is closed.
  void _emitSafe(WithdrawalState state) {
    if (!isClosed) emit(state);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Org actions
  // ─────────────────────────────────────────────────────────────────────────

  /// Submits a new withdrawal request for the current organization.
  Future<void> requestWithdrawal({
    required String organizationId,
    required double amount,
    required String bankName,
    required String accountName,
    required String accountNumber,
    required String swiftCode,
  }) async {
    _emitSafe(const WithdrawalLoading());
    try {
      await _repo.requestWithdrawal(
        organizationId: organizationId,
        amount: amount,
        bankName: bankName,
        accountName: accountName,
        accountNumber: accountNumber,
        swiftCode: swiftCode,
      );
      _emitSafe(const WithdrawalActionSuccess('تم إرسال طلب السحب بنجاح'));
    } catch (e) {
      _emitSafe(WithdrawalError(_stripException(e)));
    }
  }

  /// Fetches the withdrawal history for the current organization.
  Future<void> fetchOrgWithdrawals() async {
    _emitSafe(const WithdrawalLoading());
    try {
      final withdrawals = await _repo.fetchOrgWithdrawals();
      _emitSafe(WithdrawalListLoaded(withdrawals));
    } catch (e) {
      _emitSafe(WithdrawalError(_stripException(e)));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Admin actions
  // ─────────────────────────────────────────────────────────────────────────

  /// Fetches all pending withdrawal requests (Admin only).
  Future<void> fetchPending() async {
    _emitSafe(const WithdrawalLoading());
    try {
      final withdrawals = await _repo.fetchPendingWithdrawals();
      _emitSafe(WithdrawalListLoaded(withdrawals));
    } catch (e) {
      _emitSafe(WithdrawalError(_stripException(e)));
    }
  }

  /// Approves a specific withdrawal request (Admin only).
  Future<void> approveWithdrawal({
    required String withdrawalId,
    String adminNote = '',
  }) async {
    _emitSafe(const WithdrawalLoading());
    try {
      await _repo.approveWithdrawal(
        withdrawalId: withdrawalId,
        adminNote: adminNote,
      );
      _emitSafe(const WithdrawalActionSuccess('تمت الموافقة على طلب السحب'));
    } catch (e) {
      _emitSafe(WithdrawalError(_stripException(e)));
    }
  }

  /// Rejects a specific withdrawal request (Admin only).
  Future<void> rejectWithdrawal({
    required String withdrawalId,
    String adminNote = '',
  }) async {
    _emitSafe(const WithdrawalLoading());
    try {
      await _repo.rejectWithdrawal(
        withdrawalId: withdrawalId,
        adminNote: adminNote,
      );
      _emitSafe(const WithdrawalActionSuccess('تم رفض طلب السحب'));
    } catch (e) {
      _emitSafe(WithdrawalError(_stripException(e)));
    }
  }

  /// Processes (transfers funds for) an approved withdrawal (Admin only).
  Future<void> processWithdrawal({required String withdrawalId}) async {
    _emitSafe(const WithdrawalLoading());
    try {
      await _repo.processWithdrawal(withdrawalId: withdrawalId);
      _emitSafe(const WithdrawalActionSuccess('تمت معالجة عملية السحب'));
    } catch (e) {
      _emitSafe(WithdrawalError(_stripException(e)));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helper
  // ─────────────────────────────────────────────────────────────────────────

  /// Removes the `Exception: ` prefix that Dart adds when rethrowing.
  String _stripException(Object e) =>
      e.toString().replaceFirst('Exception: ', '');
}
