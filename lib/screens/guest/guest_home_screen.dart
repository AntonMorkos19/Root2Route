import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/screens/account_screen.dart';
import 'package:root2route/screens/guest/guest_products_tab.dart';

class GuestHomeScreen extends StatefulWidget {
  static const String id = '/guesthomescreen';

  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  int index = 0;

  final List<Widget> _screens = const [
    GuestProductsTab(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _screens[index],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorColor: AppColors.primary,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                if (states.contains(WidgetState.selected)) {
                  return TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.primary,
                  );
                }
                return TextStyle(
                  fontSize: 14.sp,
                  color: isDark ? Colors.white60 : Colors.black54,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                if (states.contains(WidgetState.selected)) {
                  return const IconThemeData(
                    color: Colors.white,
                    size: 26,
                  );
                }
                return IconThemeData(
                  color: isDark ? Colors.white60 : Colors.black54,
                  size: 24,
                );
              }),
            ),
            child: NavigationBar(
              height: 65,
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedIndex: index,
              onDestinationSelected: (i) => setState(() => index = i),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.category_outlined),
                  selectedIcon: Icon(Icons.category),
                  label: 'Products',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Account',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
