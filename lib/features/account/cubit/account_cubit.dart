import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/features/account/cubit/account_state.dart';
import 'package:root2route/features/account/models/change_password_request_model.dart';
import 'package:root2route/core/services/api.dart';

class AccountCubit extends Cubit<AccountState> {
  final ApiService _apiService;

  AccountCubit({ApiService? apiService})
      : _apiService = apiService ?? ApiService(),
        super(const AccountInitial());

  Future<void> deleteAccount() async {
    if (isClosed) return;
    emit(const DeleteAccountLoading());
    try {
      await _apiService.deleteMyAccount();
      if (!isClosed) emit(const DeleteAccountSuccess());
    } catch (e) {
      if (!isClosed) {
        // Remove 'Exception: ' prefix if present for cleaner UI messages
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        emit(DeleteAccountFailure(errorMessage));
      }
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (isClosed) return;
    emit(const ChangePasswordLoading());
    try {
      final request = ChangePasswordRequestModel(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      await _apiService.changePassword(request);
      if (!isClosed) emit(const ChangePasswordSuccess());
    } catch (e) {
      if (!isClosed) {
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        emit(ChangePasswordFailure(errorMessage));
      }
    }
  }
}
