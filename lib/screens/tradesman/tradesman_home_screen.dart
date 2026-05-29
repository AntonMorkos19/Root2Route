import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/components/floating_nav_bar.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/screens/Organizations/ProfileScreen.dart';
 import 'package:root2route/screens/Organizations/add_organization_screen.dart';
import 'package:root2route/screens/market_screen.dart';
import 'package:root2route/screens/product/my_products_screen.dart';

class TradesmanHomeScreen extends StatefulWidget {
  const TradesmanHomeScreen({super.key});

  @override
  State<TradesmanHomeScreen> createState() => _TradesmanHomeScreenState();
}

class _TradesmanHomeScreenState extends State<TradesmanHomeScreen> {
  int index = 0;

  final screens = const [MarketScreen(), ProfileScreen()];

  Widget? funFab() {
    switch (index) {
      case 0:
        return FloatingActionButton(
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: AppColors.iconPrimary),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyProductsScreen(organizationId: ''),
              ),
            );
          },
        );

      case 1:
        return FloatingActionButton(
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: AppColors.iconPrimary),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddOrganizationScreen()),
            );
          },
        );

      default:
        return null;
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
        floatingActionButton: funFab(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: screens[index],
        bottomNavigationBar: FloatingGNavBar(
          selectedIndex: index,
          onTabChange: (i) => setState(() => index = i),
          tabs: const [
            GButton(icon: Icons.shopping_bag_outlined, text: 'السوق'),
            GButton(icon: Icons.person_outline, text: 'الحساب'),
          ],
        ),
      ),
    );
  }
}
