import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/components/floating_nav_bar.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/screens/Organizations/ProfileScreen.dart';
import 'package:root2route/screens/market_screen.dart';
import 'package:root2route/screens/order/my_orders_screen.dart';
import 'package:root2route/services/api.dart';

class FactoryHomeScreen extends StatefulWidget {
  static const String id = '/factoryHome';

  const FactoryHomeScreen({super.key});

  @override
  State<FactoryHomeScreen> createState() => _FactoryHomeScreenState();
}

class _FactoryHomeScreenState extends State<FactoryHomeScreen> {
  int index = 2;
  String? myOrganizationId;

  List<Widget> get screens => [
    const ProfileScreen(),
    const MyOrdersScreen(canSell: false),
    MarketScreen(organizationId: myOrganizationId, canSell: false),
  ];

  @override
  void initState() {
    super.initState();
    _fetchMyOrganizationId();
  }

  Future<void> _fetchMyOrganizationId() async {
    try {
      final result = await ApiService().getMyOrganizations();
      if (result['success'] == true && result['data'].isNotEmpty) {
        if (mounted) {
          setState(() {
            myOrganizationId =
                result['data'][0]['id'] ?? result['data'][0]['organizationId'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching org id: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        QuickAlert.show(
          context: context,
          type: QuickAlertType.warning,
          title: 'تأكيد الخروج',
          text: 'هل تريد إغلاق التطبيق بالفعل؟',
          confirmBtnText: 'خروج',
          cancelBtnText: 'إلغاء',
          showCancelBtn: true,
          confirmBtnColor: Colors.red,
          onConfirmBtnTap: () {
            Navigator.of(context, rootNavigator: true).pop();
            SystemNavigator.pop();
          },
          onCancelBtnTap: () {
            Navigator.of(context, rootNavigator: true).pop();
          },
        );
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: AppColors.backgroundColor,
        body: screens[index],
        bottomNavigationBar: FloatingGNavBar(
          selectedIndex: index,
          onTabChange: (i) => setState(() => index = i),
          tabs: const [
            GButton(icon: Icons.person_outline, text: 'الحساب'),
            GButton(icon: Icons.receipt_long_outlined, text: 'الطلبات'),
            GButton(icon: Icons.shopping_bag_outlined, text: 'السوق'),
          ],
        ),
      ),
    );
  }
}
