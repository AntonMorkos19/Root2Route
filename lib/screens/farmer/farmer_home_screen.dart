import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:root2route/core/theme/app_colors.dart';
import 'package:root2route/screens/Organizations/ProfileScreen.dart';
 import 'package:root2route/screens/Market/add_product_screen.dart';
import 'package:root2route/screens/farmer/RequestProduct.dart';
import 'package:root2route/screens/farmer/plants_screen.dart';
import 'package:root2route/screens/farmer/scan_screen.dart';
import 'package:root2route/screens/Market/market_screen.dart';
import 'package:root2route/services/api.dart';

class FarmerHomeScreen extends StatefulWidget {
  static const String id = '/farmerHomeScreen';

  const FarmerHomeScreen({super.key});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  String? myOrganizationId;

  // Nav items definition
  static const List<_NavItem> _navItems = [
    _NavItem(
      label: 'Plants',
      icon: Icons.local_florist_outlined,
      activeIcon: Icons.local_florist,
    ),
    _NavItem(
      label: 'Scan',
      icon: Icons.camera_alt_outlined,
      activeIcon: Icons.camera_alt,
    ),
    _NavItem(
      label: 'Market',
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag,
    ),
    _NavItem(
      label: 'Profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  // Pages — IndexedStack preserves state across tabs
  static const List<Widget> _pages = [
    PlantsScreen(),
    ScanScreen(),
    MarketScreen(),
    ProfileScreen(),
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

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    HapticFeedback.lightImpact();
    setState(() => _selectedIndex = index);
  }

  Widget? funFab() {
    switch (_selectedIndex) {
      case 0:
        return FloatingActionButton(
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
        );

      case 2:
        return null;

      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      floatingActionButton: funFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _CustomNavBar(
        selectedIndex: _selectedIndex,
        items: _navItems,
        onTap: _onItemTapped,
      ),
    );
  }
}

 
class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

 
class _CustomNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _CustomNavBar({
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding + 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E), // dark charcoal background
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final isSelected = index == selectedIndex;
            return _NavBarItem(
              item: items[index],
              isSelected: isSelected,
              onTap: () => onTap(index),
            );
          }),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors
                      .primary // bright green pill
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 22,
              color: isSelected ? Colors.white : Colors.white54,
            ),
            // Animated label slide-in
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOut,
              child:
                  isSelected
                      ? Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Text(
                          item.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      )
                      : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
