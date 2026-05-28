abstract class AccountState {
  const AccountState();
}

class AccountInitial extends AccountState {
  const AccountInitial();
}

class DeleteAccountLoading extends AccountState {
  const DeleteAccountLoading();
}

class DeleteAccountSuccess extends AccountState {
  const DeleteAccountSuccess();
}

class DeleteAccountFailure extends AccountState {
  final String error;
  const DeleteAccountFailure(this.error);
}

class ChangePasswordLoading extends AccountState {
  const ChangePasswordLoading();
}

class ChangePasswordSuccess extends AccountState {
  const ChangePasswordSuccess();
}

class ChangePasswordFailure extends AccountState {
  final String error;
  const ChangePasswordFailure(this.error);
}
