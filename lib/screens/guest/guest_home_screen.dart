import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:quickalert/quickalert.dart';
import 'package:root2route/components/floating_nav_bar.dart';
import 'package:root2route/screens/Organizations/ProfileScreen.dart';
import 'package:root2route/screens/market_screen.dart';
import 'package:root2route/screens/order/my_orders_screen.dart';

class GuestHomeScreen extends StatefulWidget {
  static const String id = '/guesthomescreen';
  final int initialIndex;

  const GuestHomeScreen({super.key, this.initialIndex = 2}); // 2 = Market

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  late int index;

  final List<Widget> _screens = const [
    ProfileScreen(),
    MyOrdersScreen(canSell: false),
    MarketScreen(canSell: false),
  ];

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    // Ensure index is safe for the current organization's tab count
    int safeIndex = index;
    if (safeIndex >= _screens.length) {
      safeIndex = 0; // Fallback to Home (Index 0) if the previous index no longer exists
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        QuickAlert.show(
          context: context,
          type: QuickAlertType.warning,
          title: 'تأكيد الخروج',
          text: 'هل تريد إغلاق التطبيق بالفعل؟',
          barrierDismissible: false,
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
        body: _screens[safeIndex],
        bottomNavigationBar: FloatingGNavBar(
          selectedIndex: safeIndex,
          onTabChange: (i) => setState(() => index = i),
          tabs: const [
            GButton(icon: Icons.person_outline, text: 'الحساب'),
            GButton(icon: Icons.receipt_long_outlined, text: 'طلباتي'),
            GButton(icon: Icons.eco_outlined, text: 'المنتجات'),
          ],
        ),
      ),
    );
  }
}
