import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/components/floating_nav_bar.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/screens/Organizations/ProfileScreen.dart';
  import 'package:root2route/screens/market_screen.dart';
 
class FactoryHomeScreen extends StatefulWidget {
  const FactoryHomeScreen({super.key});

  @override
  State<FactoryHomeScreen> createState() => _FactoryHomeScreenState();
}

class _FactoryHomeScreenState extends State<FactoryHomeScreen> {
  int index = 0;

  final screens = const [MarketScreen(), ProfileScreen()];

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
            GButton(icon: Icons.shopping_bag_outlined, text: 'السوق'),
            GButton(icon: Icons.person_outline, text: 'الحساب'),
          ],
        ),
      ),
    );
  }
}
