import 'package:flutter/material.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/screens/Market/market_screen.dart';
import 'package:root2route/screens/Organizations/add_organization_screen.dart';
import 'package:root2route/screens/account_screen.dart';
 
class GuestHomeScreen extends StatefulWidget {
  static const String id = '/guesthomescreen';

  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  int index = 0;

  final screens = const [MarketScreen(), AccountScreen()];
  Widget? funFab() {
    switch (index) {
      case 0:
        return FloatingActionButton.extended(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: AppColors.primary,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        const AddOrganizationScreen(), // أو CreateOrganizationScreen حسب اسم الكلاس عندك
              ),
            );
          },
          label: const Text(
            "Create Organization",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.add_business, color: Colors.white),
        );

      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: screens[index],
      floatingActionButton: funFab(),

      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
        decoration: BoxDecoration(
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
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  );
                }
                return const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const IconThemeData(
                    color: AppColors.iconPrimary,
                    size: 26,
                  );
                }
                return const IconThemeData(
                  color: AppColors.iconPrimary,
                  size: 24,
                );
              }),
            ),
            child: NavigationBar(
              height: 65,
              elevation: 0,
              backgroundColor: Colors.grey.withOpacity(0.80),
              selectedIndex: index,
              onDestinationSelected: (i) => setState(() => index = i),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.shopping_bag_outlined),
                  selectedIcon: Icon(Icons.shopping_bag),
                  label: "Products",
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: "Account",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
