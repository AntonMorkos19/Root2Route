import 'package:flutter/material.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:root2route/components/custom_button.dart';
import 'package:root2route/components/theme_toggle_button.dart';
import 'package:root2route/core/responsive/app_sizes.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/screens/Organizations/add_organization_screen.dart';
import 'package:root2route/screens/auth/login_screen.dart';
import 'package:root2route/services/api.dart';
import 'package:root2route/services/storage_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    final String fullName = StorageService().userFullName ?? 'Guest User';
    final String email = StorageService().userEmail ?? 'No Email';
    final bool isGuest = StorageService().isGuest;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
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
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 55,
                    color: AppColors.primary,
                  ),
                ),
              ),  ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.paddingSize(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isGuest && !StorageService().hasOrganization) ...[
                    const SizedBox(height: 24),
                    InkWell(
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddOrganizationScreen(),
                            ),
                          ),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, Color(0xFF1B5E20)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create Organization',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Set up your business to start selling',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 10),
                    child: Text(
                      "Personal Information",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleMedium?.color,
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
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.badge_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          title: const Text(
                            'Name',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
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
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.alternate_email,
                              color: AppColors.primary,
                            ),
                          ),
                          title: const Text(
                            'Email',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
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

                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 10),
                    child: Text(
                      "Settings & Security",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleMedium?.color,
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
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          title: const Text(
                            'Change Password',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Colors.grey,
                          ),
                          onTap: () {},
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
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.language_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                          title: const Text(
                            'Language Settings',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'English',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          onTap: () => _showLanguageDialog(context),
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
                            'Delete Account',
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'This feature will be available soon.',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: Colors.grey,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  CustomButton(
                    text: isGuest ? 'Login' : 'Logout',
                    color:
                        isGuest
                            ? AppColors.primary
                            : Colors.redAccent.withValues(alpha: 0.9),
                    onPressed: () {
                      if (isGuest) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      } else {
                        QuickAlert.show(
                          context: context,
                          type: QuickAlertType.confirm,
                          title: 'Logout',
                          text: 'Are you sure you want to exit?',
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
                      }
                    },
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text("Select Language"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text("English"),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  title: const Text("Arabic"),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
    );
  }
}
