import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/components/floating_nav_bar.dart';
import 'package:root2route/screens/Organizations/ProfileScreen.dart';
 import 'package:root2route/screens/guest/guest_products_tab.dart';

class GuestHomeScreen extends StatefulWidget {
  static const String id = '/guesthomescreen';

  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  int index = 0;

  final List<Widget> _screens = const [GuestProductsTab(), ProfileScreen()];

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
        body: _screens[index],
        bottomNavigationBar: FloatingGNavBar(
          selectedIndex: index,
          onTabChange: (i) => setState(() => index = i),
          tabs: const [
            GButton(icon: Icons.eco_outlined, text: 'المنتجات'),
            GButton(icon: Icons.person_outline, text: 'بروفيل'),
          ],
        ),
      ),
    );
  }
}
