import 'package:flutter/material.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/screens/Organizations/organizations_list_screen.dart';
import 'package:root2route/screens/account_screen.dart';
import 'package:root2route/features/shipments/ui/addresses_screen.dart';
import 'package:root2route/services/storage_service.dart';
import 'package:root2route/features/reviews/ui/organization_reviews_screen.dart';
import 'package:root2route/features/organizations/widgets/switch_organization_sheet.dart';
import 'package:root2route/screens/Organizations/manage_organizations_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            PopupMenuButton<String>(
              icon: Icon(Icons.menu, color: Theme.of(context).iconTheme.color),
              onSelected: (value) {
                if (value == 'all_orgs') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OrganizationsListScreen(),
                    ),
                  );
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'all_orgs',
                      child: ListTile(
                        leading: Icon(
                          Icons.business_outlined,
                          color: Color(0xff0F4C5C),
                        ),
                        title: Text('كل الشركات'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.person_outline,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        'إعدادات الحساب',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AccountScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        'عناويني',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddressesScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // ── Manage Organizations ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.business_center_outlined,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        'إدارة الشركات',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ManageOrganizationsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (StorageService().hasOrganization) ...[
                  const SizedBox(height: 15),
                  // ── Switch Organization ───────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.swap_horiz_rounded,
                          color: AppColors.primary,
                        ),
                        title: const Text(
                          'تبديل الشركة',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => showSwitchOrganizationSheet(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // ── Customer reviews ─────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.star_rate, color: Colors.amber),
                        title: const Text(
                          'تقييمات العملاء',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          final orgId = StorageService().organizationId;
                          if (orgId == null || orgId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'لم يتم العثور على مؤسسة نشطة لعرض التقييمات.',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => OrganizationReviewsScreen(
                                    organizationId: orgId,
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
