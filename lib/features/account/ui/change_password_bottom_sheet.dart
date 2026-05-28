import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/components/custom_button.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/features/account/cubit/account_cubit.dart';
import 'package:root2route/features/account/cubit/account_state.dart';

class ChangePasswordBottomSheet extends StatefulWidget {
  final AccountCubit accountCubit;

  const ChangePasswordBottomSheet({super.key, required this.accountCubit});

  static void show(BuildContext context, AccountCubit accountCubit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangePasswordBottomSheet(accountCubit: accountCubit),
    );
  }

  @override
  State<ChangePasswordBottomSheet> createState() => _ChangePasswordBottomSheetState();
}

class _ChangePasswordBottomSheetState extends State<ChangePasswordBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordCtrl.text != _confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password and confirm password do not match.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    widget.accountCubit.changePassword(
      oldPassword: _oldPasswordCtrl.text,
      newPassword: _newPasswordCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocProvider.value(
      value: widget.accountCubit,
      child: BlocConsumer<AccountCubit, AccountState>(
        listener: (context, state) {
          if (state is ChangePasswordSuccess) {
            Navigator.pop(context); // close bottom sheet
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Password updated successfully.'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is ChangePasswordFailure) {
            QuickAlert.show(
              context: context,
              type: QuickAlertType.error,
              title: 'Error',
              text: state.error,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is ChangePasswordLoading;

          return Container(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    _buildPasswordField(
                      controller: _oldPasswordCtrl,
                      label: 'Old Password',
                      obscureText: _obscureOld,
                      onToggleObscure: () => setState(() => _obscureOld = !_obscureOld),
                    ),
                    const SizedBox(height: 16),

                    _buildPasswordField(
                      controller: _newPasswordCtrl,
                      label: 'New Password',
                      obscureText: _obscureNew,
                      onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                    const SizedBox(height: 16),

                    _buildPasswordField(
                      controller: _confirmPasswordCtrl,
                      label: 'Confirm New Password',
                      obscureText: _obscureConfirm,
                      onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    const SizedBox(height: 32),

                    if (isLoading)
                      const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    else
                      CustomButton(
                        text: 'Update Password',
                        onPressed: _submit,
                        color: AppColors.primary,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleObscure,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: (val) => val == null || val.isEmpty ? 'This field is required' : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggleObscure,
        ),
      ),
    );
  }
}
