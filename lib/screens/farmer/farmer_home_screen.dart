// import 'package:flutter/material.dart';
// import 'package:root2route/core/theme/app_colors.dart';
// import 'package:root2route/screens/Organizations/ProfileScreen.dart';
// import 'package:root2route/screens/farmer/RequestProduct.dart';
// import 'package:root2route/screens/farmer/plants_screen.dart';
// import 'package:root2route/screens/market_screen.dart';
// import 'package:root2route/screens/farmer/scan_screen.dart';
// import 'package:root2route/services/api.dart';

// class FarmerHomeScreen extends StatefulWidget {
//   static const String id = '/farmerHomeScreen';

//   const FarmerHomeScreen({super.key});

//   @override
//   State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
// }

// class _FarmerHomeScreenState extends State<FarmerHomeScreen> {
//   int index = 0;
//   String? myOrganizationId;
//   List<Widget> get screens => [
//     const PlantsScreen(),
//     const ScanScreen(),
//     MarketScreen(organizationId: myOrganizationId),
//     const ProfileScreen(),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _fetchMyOrganizationId();
//   }

//   Future<void> _fetchMyOrganizationId() async {
//     try {
//       final result = await ApiService().getMyOrganizations();
//       if (result['success'] == true && result['data'].isNotEmpty) {
//         if (mounted) {
//           setState(() {
//             myOrganizationId =
//                 result['data'][0]['id'] ?? result['data'][0]['organizationId'];
//           });
//         }
//       }
//     } catch (e) {
//       debugPrint("Error fetching org id: $e");
//     }
//   }

//   Widget? funFab() {
//     switch (index) {
//       case 0:
//         return FloatingActionButton(
//           backgroundColor: AppColors.primary,
//           shape: const CircleBorder(),
//           child: const Icon(Icons.add, color: AppColors.iconPrimary),
//           onPressed: () {
//             showDialog(
//               context: context,
//               builder:
//                   (_) => AlertDialog(
//                     backgroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(18),
//                     ),
//                     contentPadding: const EdgeInsets.all(16),
//                     content: const RequestProduct(),
//                   ),
//             );
//           },
//         );

//       default:
//         return null;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBody: true,
//       body: screens[index],
//       floatingActionButton: funFab(),
//       floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
//       bottomNavigationBar: Container(
//         margin: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(30),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 20,
//               offset: const Offset(0, 10),
//             ),
//           ],
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(30),
//           child: NavigationBarTheme(
//             data: NavigationBarThemeData(
//               indicatorColor: AppColors.primary,
//               labelTextStyle: WidgetStateProperty.resolveWith((states) {
//                 if (states.contains(WidgetState.selected)) {
//                   return const TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                     color: AppColors.textSecondary,
//                   );
//                 }
//                 return const TextStyle(
//                   fontSize: 12,
//                   color: AppColors.textSecondary,
//                 );
//               }),
//               iconTheme: WidgetStateProperty.resolveWith((states) {
//                 if (states.contains(WidgetState.selected)) {
//                   return const IconThemeData(
//                     color: AppColors.iconPrimary,
//                     size: 26,
//                   );
//                 }
//                 return const IconThemeData(
//                   color: AppColors.iconPrimary,
//                   size: 24,
//                 );
//               }),
//             ),
//             child: NavigationBar(
//               height: 65,
//               elevation: 0,
//               backgroundColor: Colors.grey.withOpacity(0.80),
//               selectedIndex: index,
//               onDestinationSelected: (i) => setState(() => index = i),
//               labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
//               destinations: const [
//                 NavigationDestination(
//                   icon: Icon(Icons.grass_outlined),
//                   selectedIcon: Icon(Icons.grass_rounded),
//                   label: "Plants",
//                 ),
//                 NavigationDestination(
//                   icon: Icon(Icons.camera_enhance_outlined),
//                   selectedIcon: Icon(Icons.camera_enhance),
//                   label: "Scan",
//                 ),
//                 NavigationDestination(
//                   icon: Icon(Icons.shopping_bag_outlined),
//                   selectedIcon: Icon(Icons.shopping_bag),
//                   label: "Market",
//                 ),
//                 NavigationDestination(
//                   icon: Icon(Icons.person_outline),
//                   selectedIcon: Icon(Icons.person),
//                   label: "Profile",
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/screens/Organizations/ProfileScreen.dart';
import 'package:root2route/screens/farmer/RequestProduct.dart';
import 'package:root2route/screens/farmer/plants_screen.dart';
import 'package:root2route/screens/market_screen.dart';
import 'package:root2route/screens/farmer/scan_screen.dart';
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

  Widget? funFab() {
    switch (index) {
      case 0:
        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: FloatingActionButton(
            backgroundColor: AppColors.primary,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, color: AppColors.iconPrimary),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (_) => AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      content: const RequestProduct(),
                    ),
              );
            },
          ),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                0.3,
              ), // تقليل الشفافية شوية لظل أغمق
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              // لون الـ Indicator (الخلفية الخضرا ورا الأيقونة المحددة)
              indicatorColor: AppColors.primary,
              // تعديل شكل الـ Indicator ليكون دائري أكتر ويدي شكل أنيميشن أحلى
              indicatorShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // لون النص المختار أبيض
                  );
                }
                return const TextStyle(
                  fontSize: 12,
                  color: Colors.grey, // لون النص غير المختار رمادي
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const IconThemeData(
                    color:
                        Colors
                            .white, // لون الأيقونة المختارة أبيض (أو خليه AppColors.iconPrimary لو غامق)
                    size: 26,
                  );
                }
                return const IconThemeData(
                  color: Colors.grey, // لون الأيقونة غير المختارة رمادي
                  size: 24,
                );
              }),
            ),
            child: NavigationBar(
              height: 65,
              elevation: 0,
              // لون خلفية الـ BottomNavigationBar خليناه أسود
              backgroundColor: const Color(
                0xFF1E1E1E,
              ), // أسود مطفي شيك (ممكن تخليه Colors.black)
              animationDuration: const Duration(
                milliseconds: 500,
              ), // زودنا مدة الأنيميشن عشان يبقى ناعم
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
