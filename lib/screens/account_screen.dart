import 'package:flutter/material.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:root2route/components/custom_button.dart';
import 'package:root2route/components/theme_toggle_button.dart';
import 'package:root2route/core/responsive/app_sizes.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/screens/auth/login_screen.dart';
import 'package:root2route/services/api.dart';
import 'package:root2route/services/storage_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/features/account/cubit/account_cubit.dart';
import 'package:root2route/features/account/cubit/account_state.dart';
import 'package:root2route/features/account/ui/change_password_bottom_sheet.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AccountCubit(),
      child: const _AccountScreenView(),
    );
  }
}

class _AccountScreenView extends StatefulWidget {
  const _AccountScreenView({super.key});

  @override
  State<_AccountScreenView> createState() => _AccountScreenViewState();
}

class _AccountScreenViewState extends State<_AccountScreenView> {
  @override
  Widget build(BuildContext context) {
    final String fullName = StorageService().userFullName ?? 'User';
    final String email = StorageService().userEmail ?? 'No Email';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'حسابي',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: const [ThemeToggleButton(), SizedBox(width: 4)],
        ),
        body: BlocListener<AccountCubit, AccountState>(
          listener: (context, state) {
            if (state is DeleteAccountLoading) {
              QuickAlert.show(
                context: context,
                type: QuickAlertType.loading,
                title: 'جاري حذف الحساب',
                text: 'الرجاء الانتظار...',
                barrierDismissible: false,
              );
            } else if (state is DeleteAccountSuccess) {
              Navigator.of(
                context,
                rootNavigator: true,
              ).pop(); // dismiss loading
              QuickAlert.show(
                context: context,
                type: QuickAlertType.success,
                title: 'تم الحذف',
                text: 'تم حذف حسابك بنجاح.',
                onConfirmBtnTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              );
            } else if (state is DeleteAccountFailure) {
              Navigator.of(
                context,
                rootNavigator: true,
              ).pop(); // dismiss loading
              QuickAlert.show(
                context: context,
                type: QuickAlertType.error,
                title: 'خطأ',
                text: state.error,
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 30),
            child: Column(
              children: [
                const SizedBox(height: 10),

                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: Theme.of(context).cardColor,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 55,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                //
                const SizedBox(height: 20),

                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingSize(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 15),
                        child: Text(
                          "المعلومات الشخصية",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).textTheme.titleMedium?.color,
                          ),
                        ),
                      ),

                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.badge_outlined,
                                  color: AppColors.primary,
                                ),
                              ),
                              title: const Text(
                                'الاسم',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: Text(
                                fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const Divider(
                              height: 1,
                              indent: 56,
                              endIndent: 16,
                              color: Color(0xFFF0F0F0),
                            ),
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.alternate_email,
                                  color: AppColors.primary,
                                ),
                              ),
                              title: const Text(
                                'البريد الإلكتروني',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: Text(
                                email,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 10),
                        child: Text(
                          "الإعدادات والأمان",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).textTheme.titleMedium?.color,
                          ),
                        ),
                      ),

                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // ── Dark Mode Toggle ─────────────────────────────
                            const ThemeToggleTile(),
                            const Divider(
                              height: 1,
                              indent: 56,
                              endIndent: 16,
                              color: Color(0xFFF0F0F0),
                            ),
                            // ── Change Password ──────────────────────────────
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.lock_reset_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                              title: const Text(
                                'تغيير كلمة المرور',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: Colors.grey,
                              ),
                              onTap: () {
                                final accountCubit =
                                    context.read<AccountCubit>();
                                ChangePasswordBottomSheet.show(
                                  context,
                                  accountCubit,
                                );
                              },
                            ),
                            const Divider(
                              height: 1,
                              indent: 56,
                              endIndent: 16,
                              color: Color(0xFFF0F0F0),
                            ),

                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.delete_forever_rounded,
                                  color: Colors.redAccent,
                                ),
                              ),
                              title: const Text(
                                'حذف الحساب',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.redAccent,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: Colors.redAccent,
                              ),
                              onTap: () {
                                final accountCubit =
                                    context.read<AccountCubit>();
                                showDialog(
                                  context: context,
                                  builder: (dialogContext) {
                                    return AlertDialog(
                                      title: const Text('حذف الحساب'),
                                      content: const Text(
                                        'هل أنت متأكد أنك تريد حذف حسابك؟ لا يمكن التراجع عن هذا الإجراء.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () =>
                                                  Navigator.pop(dialogContext),
                                          child: const Text(
                                            'إلغاء',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(dialogContext);
                                            accountCubit.deleteAccount();
                                          },
                                          child: const Text(
                                            'حذف',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
                      CustomButton(
                        text: 'تسجيل الخروج',
                        color: Colors.redAccent.withValues(alpha: 0.9),
                        onPressed: () {
                          QuickAlert.show(
                            context: context,
                            type: QuickAlertType.confirm,
                            title: 'تسجيل الخروج',
                            text: 'هل أنت متأكد أنك تريد الخروج؟',
                            confirmBtnColor: Colors.red,
                            onConfirmBtnTap: () async {
                              Navigator.pop(context);
                              await ApiService().logout();
                              if (!mounted) return;
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            },
                          );
                        },
                      ),
                      // Removing the extra bottom SizedBox since SingleChildScrollView has bottom padding
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
