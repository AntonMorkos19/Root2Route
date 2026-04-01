import 'package:flutter/material.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:root2route/components/custom_button.dart';
import 'package:root2route/components/info_account_card.dart';
import 'package:root2route/components/settings_account_card.dart';
import 'package:root2route/core/responsive/app_sizes.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/screens/auth/login_screen.dart';
import 'package:root2route/screens/change_password_screen.dart';
import 'package:root2route/screens/notifications_screen.dart';
import 'package:root2route/services/api.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Account",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.notification_important,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 50),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Personal information",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            InfoAccountCard(
              icon: Icons.badge_outlined,
              title: 'Name',
              info: 'Anton Morkos',
            ),
            InfoAccountCard(
              icon: Icons.email,
              title: 'Email',
              info: 'Antonmorkos6@gamil.com',
            ),

            const SizedBox(height: 2),

            Padding(
              padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),

              child: Row(
                children: [
                  Text(
                    "Settings and security",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            SettingsAccountCard(
              icon: Icons.lock_outline,
              title: 'Change Password',
              value: '',
              iconButton: Icons.arrow_forward_ios,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),
            SettingsAccountCard(
              icon: Icons.public,
              title: ' Language settings',

              value: 'English',

              iconButton: Icons.arrow_forward_ios,
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: const Text("Change Language"),

                        content: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: const Text("English"),
                                onTap: () {
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                title: const Text("العربية"),
                                onTap: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                );
              },
            ),

            SettingsAccountCard(
              icon: Icons.delete,
              title: 'DeleteAccount',
              value: '',
              iconButton: Icons.arrow_forward_ios,
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        title: const Text(
                          'Delete account?',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        content: const Text(
                          'This action is permanent. Your account and data will be deleted.',
                        ),
                        actionsPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 25,
                        ),
                        actions: [
                          Row(
                            children: [
                              const SizedBox(width: 12),
                              Expanded(
                                child: CustomButton(
                                  text: 'Ok',
                                  color: Colors.red,
                                  onPressed: () {
                                    Navigator.pop(context);
                                    QuickAlert.show(
                                      context: context,
                                      type: QuickAlertType.success,
                                      text: "The account has been deleted",
                                      showConfirmBtn: false,
                                    );

                                    Future.delayed(
                                      const Duration(seconds: 3),
                                      () {
                                        if (!context.mounted) return;
                                        Navigator.pushNamedAndRemoveUntil(
                                          context,
                                          LoginScreen.id,
                                          (route) => false,
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: CustomButton(
                                  text: 'Cancel',
                                  color: AppColors.iconSecondary,
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                );
              },
            ),
            const SizedBox(height: 2),
            Padding(
              padding: EdgeInsets.all(AppSizes.paddingSize(context)),
              child: CustomButton(
                text: 'Logout',
                onPressed: () {
                  QuickAlert.show(
                    context: context,
                    type: QuickAlertType.confirm,
                    title: 'Logout',
                    text: 'Are you sure you want to logout?',
                    confirmBtnText: 'Yes, Logout',
                    cancelBtnText: 'Cancel',
                    confirmBtnColor: Colors.red,
                    showCancelBtn: true,
                    onConfirmBtnTap: () async {
                      // Dismiss the confirm dialog
                      Navigator.pop(context);

                      // Show a brief loading
                      QuickAlert.show(
                        context: context,
                        type: QuickAlertType.loading,
                        title: 'Logging out',
                        text: 'Please wait...',
                        barrierDismissible: false,
                      );

                      // Clear all auth data
                      await ApiService().logout();

                      if (!mounted) return;

                      // Dismiss loading dialog
                      Navigator.pop(context);

                      if (!mounted) return;

                      // Navigate to LoginScreen and destroy the entire stack
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                  );
                },
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
