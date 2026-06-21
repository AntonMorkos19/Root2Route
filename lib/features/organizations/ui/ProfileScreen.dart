import 'package:flutter/material.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/features/organizations/ui/organizations_list_screen.dart';
import 'package:root2route/features/account/ui/account_screen.dart';
import 'package:root2route/features/shipments/ui/addresses_screen.dart';
import 'package:root2route/core/services/storage_service.dart';
import 'package:root2route/core/services/api.dart';
import 'package:root2route/features/reviews/ui/organization_reviews_screen.dart';
import 'package:root2route/features/organizations/widgets/switch_organization_sheet.dart';
import 'package:root2route/features/organizations/ui/manage_organizations_screen.dart';
import 'package:root2route/features/dashboards/ui/farmer/farmer_home_screen.dart';
import 'package:root2route/features/dashboards/ui/restaurant/restaurant_home_screen.dart';
import 'package:root2route/features/dashboards/ui/factory/factory_home_screen.dart';
import 'package:root2route/features/dashboards/ui/tradesman/tradesman_home_screen.dart';
import 'package:root2route/features/withdrawals/presentation/screens/withdrawal_request_screen.dart';
import 'package:root2route/features/withdrawals/presentation/screens/withdrawal_history_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quickalert/quickalert.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  bool _isCheckingStatus = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatusUpdatesSilent();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatusUpdatesSilent();
    }
  }

  Future<void> _checkStatusUpdatesSilent() async {
    final currentOrgId = StorageService().organizationId;
    if (currentOrgId == null || StorageService().organizationStatus == 1) {
      if (mounted) setState(() => _isCheckingStatus = false);
      return;
    }

    if (mounted) setState(() => _isCheckingStatus = true);

    try {
      final orgsResult = await ApiService().getMyOrganizations();
      if (!mounted) return;

      if (orgsResult['success'] == true) {
        final List dataList = orgsResult['data'] ?? [];
        for (var org in dataList) {
          if (org is Map) {
            final orgId =
                org['id']?.toString() ??
                org['organizationId']?.toString() ??
                org['OrganizationId']?.toString();
            if (orgId == currentOrgId) {
              final status =
                  org['organizationStatus'] ??
                  org['status'] ??
                  org['OrganizationStatus'] ??
                  org['Status'];
              if (status == 1 || status == '1') {
                await StorageService().saveOrganizationStatus(1);
                // Also silently refresh the token so the user gets owner claims
                await ApiService().refreshAuthToken();
              }
              break;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Silent status update failed: $e');
    } finally {
      if (mounted) setState(() => _isCheckingStatus = false);
    }
  }

  Future<void> _checkApprovalStatus() async {
    // Show loading
    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: 'جاري التحقق',
      text: 'يرجى الانتظار...',
      barrierDismissible: false,
      confirmBtnText: 'موافق',
    );

    try {
      final orgsResult = await ApiService().getMyOrganizations();

      if (!mounted) return;

      bool isApproved = false;
      int? approvedOrgType;
      String? approvedOrgId;

      if (orgsResult['success'] == true) {
        final List dataList = orgsResult['data'] ?? [];
        for (var org in dataList) {
          if (org is Map) {
            final status =
                org['organizationStatus'] ??
                org['status'] ??
                org['OrganizationStatus'] ??
                org['Status'];
            if (status == 1 || status == '1') {
              isApproved = true;
              approvedOrgType = org['type'] ?? org['Type'];
              approvedOrgId =
                  org['id']?.toString() ??
                  org['organizationId']?.toString() ??
                  org['OrganizationId']?.toString();
              break;
            }
          }
        }
      }

      if (isApproved && approvedOrgId != null) {
        // Save its data to local storage
        await StorageService().saveOrganizationDetails(
          orgId: approvedOrgId.toString(),
          orgType: int.tryParse(approvedOrgType?.toString() ?? '0') ?? 0,
          status: 1,
        );

        // NOW, call await ApiService().refreshAuthToken()
        await ApiService().refreshAuthToken();

        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop(); // close loading

        if (!mounted) return;

        // ✅ Approved — route to the correct dashboard
        final orgType = StorageService().organizationType ?? 0;
        final targetScreen = _getHomeScreenForType(orgType);

        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          title: 'تمت الموافقة!',
          text: 'جاري تحويلك للوحة تحكم شركتك...',
          confirmBtnText: 'موافق',
          barrierDismissible: false,
          onConfirmBtnTap: () {
            Navigator.of(context, rootNavigator: true).pop(); // close alert
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => targetScreen),
              (route) => false,
            );
          },
        );
      } else {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop(); // close loading

        // ⏳ Still pending
        QuickAlert.show(
          context: context,
          type: QuickAlertType.info,
          title: 'قيد المراجعة',
          text: 'طلبك لا يزال قيد المراجعة. يرجى المحاولة لاحقاً.',
          confirmBtnText: 'موافق',
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // close loading
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'خطأ',
        text: 'حدث خطأ أثناء التحقق. يرجى المحاولة لاحقاً.',
        confirmBtnText: 'موافق',
      );
    }
  }

  Widget _getHomeScreenForType(int type) {
    switch (type) {
      case 0:
        return const FarmerHomeScreen();
      case 1:
        return const RestaurantHomeScreen();
      case 2:
        return const FactoryHomeScreen();
      case 3:
        return const TradesmanHomeScreen();
      default:
        return const FarmerHomeScreen();
    }
  }

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
                // ── Manage Organizations / Pending Banner ──────────────
                if (StorageService().hasOrganization &&
                    StorageService().organizationStatus == 0)
                  if (_isCheckingStatus)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    )
                  else
                    // Pending review banner — tappable to check approval status
                    GestureDetector(
                      onTap: () => _checkApprovalStatus(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amber.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.hourglass_top_rounded,
                                  color: Colors.amber.shade800,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'طلب إنشاء الشركة قيد مراجعة الإدارة ⏳',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.amber.shade900,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'اضغط هنا للتحقق من حالة الطلب',
                                      style: TextStyle(
                                        color: Colors.amber.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.refresh_rounded,
                                color: Colors.amber.shade700,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                else
                  // Normal manage organizations tile
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
                              builder:
                                  (context) =>
                                      const ManageOrganizationsScreen(),
                            ),
                          ).then((_) => setState(() {}));
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
                        leading: const Icon(
                          Icons.star_rate,
                          color: Colors.amber,
                        ),
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
                  const SizedBox(height: 15),
                  // ── Web Dashboard ────────────────────────────────────
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
                          Icons.language,
                          color: AppColors.primary,
                        ),
                        title: const Text(
                          'لوحة تحكم الشركة (ويب)',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(Icons.open_in_browser, size: 20),
                        onTap: () async {
                          final Uri url = Uri.parse(
                            'https://root2-route-front.vercel.app/',
                          );
                          try {
                            if (!await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            )) {
                              throw Exception('Could not launch url');
                            }
                          } catch (e) {
                            if (context.mounted) {
                              QuickAlert.show(
                                context: context,
                                type: QuickAlertType.error,
                                title: 'عذرًا',
                                text: 'حدث خطأ أثناء محاولة فتح الرابط.',
                                confirmBtnText: 'موافق',
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  // ── Withdrawal Section ───────────────────────────────
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
                      child: Column(
                        children: [
                          // ── طلب سحب جديد ──────────────────────────────
                          ListTile(
                            leading: const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: AppColors.primary,
                            ),
                            title: const Text(
                              'طلب سحب رصيد',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => const WithdrawalRequestScreen(),
                                ),
                              );
                            },
                          ),
                          //  SizedBox(height:10,),                          // ── سجل طلبات السحب ───────────────────────────
                          //                 ListTile(
                          //                   leading: const Icon(
                          //                     Icons.history_rounded,
                          //                     color: AppColors.primary,
                          //                   ),
                          //                   title: const Text(
                          //                     'سجل طلبات السحب',
                          //                     style: TextStyle(fontWeight: FontWeight.w600),
                          //                   ),
                          //                   trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          //                   onTap: () {
                          //                     Navigator.push(
                          //                       context,
                          //                       MaterialPageRoute(
                          //                         builder: (_) => const WithdrawalHistoryScreen(),
                          //                       ),
                          //                     );
                          //                   },
                          //                 ),
                        ],
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
