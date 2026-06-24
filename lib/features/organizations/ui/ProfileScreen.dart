import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:root2route/core/theme/app_colors.dart';
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
import 'package:root2route/features/withdrawals/presentation/screens/wallet_screen.dart';
import 'package:root2route/features/auth/ui/login_screen.dart';
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
  bool _isLoadingWallet = true;
  double _walletBalance = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatusUpdatesSilent();
    _fetchWalletBalance();
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
      _fetchWalletBalance();
    }
  }

  Future<void> _fetchWalletBalance() async {
    if (StorageService().isGuest) {
      if (mounted) {
        setState(() {
          _walletBalance = 0.0;
          _isLoadingWallet = false;
        });
      }
      return;
    }

    if (!StorageService().hasOrganization) {
      if (mounted) setState(() => _isLoadingWallet = false);
      return;
    }

    if (mounted) setState(() => _isLoadingWallet = true);

    try {
      final result = await ApiService().getMyOrganizations();
      if (!mounted) return;
      if (result['success'] == true) {
        final List dataList = result['data'] ?? [];
        if (dataList.isNotEmpty && dataList[0] is Map) {
          final org = dataList[0] as Map;
          final rawBalance = org['walletBalance'] ?? org['WalletBalance'] ?? 0;
          _walletBalance = double.tryParse(rawBalance.toString()) ?? 0.0;
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch wallet balance: $e');
    } finally {
      if (mounted) setState(() => _isLoadingWallet = false);
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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildHeader(),
                  Positioned(
                    bottom: -35.h,
                    left: 20.w,
                    right: 20.w,
                    child: _buildBalanceCard(),
                  ),
                ],
              ),
              SizedBox(height: 55.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    _buildGroup1(),
                    SizedBox(height: 20.h),
                    _buildGroup2(),
                    SizedBox(height: 20.h),
                    _buildGroup3(),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 70.h,
        bottom: 60.h,
        left: 20.w,
        right: 20.w,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B7A35), Color(0xFF2ECC71)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30.r),
          bottomRight: Radius.circular(30.r),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32.r,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Icon(Icons.person, color: Colors.white, size: 36.r),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً بك',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'إدارة حسابك بسهولة',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final bool isGuest = StorageService().isGuest;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (isGuest) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletScreen()),
            ).then((_) => _fetchWalletBalance());
          }
        },
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(
                isGuest
                    ? Icons.login_rounded
                    : Icons.account_balance_wallet_rounded,
                color: AppColors.primary,
                size: 26.r,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isGuest ? 'مرحباً بك كزائر' : 'الرصيد المتاح',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  if (isGuest)
                    Text(
                      'سجل الدخول واستمتع بمميزاتنا',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else if (_isLoadingWallet)
                    SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  else
                    Text(
                      '${_walletBalance.toStringAsFixed(2)} EGP',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16.r,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardGroup({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    Widget? subtitle,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          leading: Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: iconColor, size: 22.r),
          ),
          title: Text(
            title,
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
          ),
          subtitle: subtitle,
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16.r,
            color: Colors.grey.shade400,
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.shade100,
            indent: 64.w,
            endIndent: 16.w,
          ),
      ],
    );
  }

  Widget _buildGroup1() {
    final bool isGuest = StorageService().isGuest;

    return _buildCardGroup(
      children: [
        _buildListTile(
          icon: Icons.person_outline,
          iconColor: AppColors.primary,
          title: 'إعدادات الحساب',
          onTap: () {
            if (isGuest) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountScreen()),
              );
            }
          },
        ),
        _buildListTile(
          icon: Icons.location_on_outlined,
          iconColor: AppColors.primary,
          title: 'عناويني',
          showDivider: false,
          onTap: () {
            if (isGuest) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddressesScreen(),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildGroup2() {
    if (StorageService().hasOrganization &&
        StorageService().organizationStatus == 0) {
      return Column(
        children: [
          if (_isCheckingStatus)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: SizedBox(
                  width: 24.w,
                  height: 24.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => _checkApprovalStatus(),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(16.r),
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
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.hourglass_top_rounded,
                        color: Colors.amber.shade800,
                        size: 24.r,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'طلب إنشاء الشركة قيد مراجعة الإدارة ⏳',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade900,
                              fontSize: 14.sp,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'اضغط هنا للتحقق من حالة الطلب',
                            style: TextStyle(
                              color: Colors.amber.shade700,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.refresh_rounded,
                      color: Colors.amber.shade700,
                      size: 20.r,
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: 20.h),
          _buildCardGroup(
            children: [
              _buildListTile(
                icon: Icons.swap_horiz_rounded,
                iconColor: AppColors.primary,
                title: 'تبديل الشركة',
                onTap: () => showSwitchOrganizationSheet(context),
              ),
              _buildListTile(
                icon: Icons.language,
                iconColor: AppColors.primary,
                title: 'لوحة تحكم الشركة (ويب)',
                showDivider: false,
                onTap: _launchWebDashboard,
              ),
            ],
          ),
        ],
      );
    }

    List<Widget> children = [];

    if (!(StorageService().hasOrganization &&
        StorageService().organizationStatus == 0)) {
      children.add(
        _buildListTile(
          icon: Icons.business_center_outlined,
          iconColor: AppColors.primary,
          title: 'إدارة الشركات',
          showDivider: StorageService().hasOrganization,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ManageOrganizationsScreen(),
              ),
            ).then((_) => setState(() {}));
          },
        ),
      );
    }

    if (StorageService().hasOrganization) {
      children.add(
        _buildListTile(
          icon: Icons.swap_horiz_rounded,
          iconColor: AppColors.primary,
          title: 'تبديل الشركة',
          showDivider: true,
          onTap: () => showSwitchOrganizationSheet(context),
        ),
      );
      children.add(
        _buildListTile(
          icon: Icons.language,
          iconColor: AppColors.primary,
          title: 'لوحة تحكم الشركة (ويب)',
          showDivider: false,
          onTap: _launchWebDashboard,
        ),
      );
    }

    return children.isEmpty
        ? const SizedBox.shrink()
        : _buildCardGroup(children: children);
  }

  Widget _buildGroup3() {
    if (!StorageService().hasOrganization) return const SizedBox.shrink();

    return _buildCardGroup(
      children: [
        _buildListTile(
          icon: Icons.star_rate_rounded,
          iconColor: Colors.amber,
          title: 'تقييمات العملاء',
          showDivider: false,
          onTap: () {
            final orgId = StorageService().organizationId;
            if (orgId == null || orgId.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('لم يتم العثور على مؤسسة نشطة لعرض التقييمات.'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        OrganizationReviewsScreen(organizationId: orgId),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _launchWebDashboard() async {
    final Uri url = Uri.parse('https://root2-route-front.vercel.app/');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch url');
      }
    } catch (e) {
      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'عذرًا',
          text: 'حدث خطأ أثناء محاولة فتح الرابط.',
          confirmBtnText: 'موافق',
        );
      }
    }
  }
}
