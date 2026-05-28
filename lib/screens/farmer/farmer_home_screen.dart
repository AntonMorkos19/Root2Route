import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/screens/Organizations/ProfileScreen.dart';
import 'package:root2route/screens/farmer/plants_screen.dart';
import 'package:root2route/screens/market_screen.dart';
import 'package:root2route/screens/farmer/scan_screen.dart';
import 'package:root2route/screens/order/my_orders_screen.dart';
import 'package:root2route/services/api.dart';

class FarmerHomeScreen extends StatefulWidget {
  static const String id = '/farmerHomeScreen';

  const FarmerHomeScreen({super.key});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen> {
  int index = 0;
  String? myOrganizationId;
  List<Widget> get screens => [
    const PlantsScreen(),
    const ScanScreen(),
    MarketScreen(organizationId: myOrganizationId),
    const MyOrdersScreen(),
    const ProfileScreen(),
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
    return Scaffold(
      extendBody: true,
      body: screens[index],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
                  icon: Icon(Icons.grass_outlined),
                  selectedIcon: Icon(Icons.grass_rounded),
                  label: "Plants",
                ),
                NavigationDestination(
                  icon: Icon(Icons.camera_enhance_outlined),
                  selectedIcon: Icon(Icons.camera_enhance),
                  label: "Scan",
                ),
                NavigationDestination(
                  icon: Icon(Icons.shopping_bag_outlined),
                  selectedIcon: Icon(Icons.shopping_bag),
                  label: "Market",
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: "Orders",
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
