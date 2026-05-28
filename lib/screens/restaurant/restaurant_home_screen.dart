import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/screens/Organizations/ProfileScreen.dart';
import 'package:root2route/screens/Organizations/add_organization_screen.dart';
import 'package:root2route/screens/market_screen.dart';
import 'package:root2route/screens/product/my_products_screen.dart';

class RestaurantHomeScreen extends StatefulWidget {
  const RestaurantHomeScreen({super.key});

  @override
  State<RestaurantHomeScreen> createState() => _RestaurantHomeScreenState();
}

class _RestaurantHomeScreenState extends State<RestaurantHomeScreen> {
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
                builder:
                    (context) => const MyProductsScreen(organizationId: ''),
              ),
            );
          },
        );

      case 2:
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
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      extendBody: true,
      floatingActionButton: funFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      body: screens[index],
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
                  icon: Icon(Icons.shopping_bag_outlined),
                  selectedIcon: Icon(Icons.shopping_bag),
                  label: "Market",
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long),
                  selectedIcon: Icon(Icons.receipt_long_outlined),
                  label: "History",
                ),

                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: "Profile",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
