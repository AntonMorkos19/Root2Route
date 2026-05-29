import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class FloatingGNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChange;
  final List<GButton> tabs;

  const FloatingGNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChange,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: GNav(
            haptic: true,
            gap: 8,
            iconSize: 24,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            tabBorderRadius: 50,
            duration: const Duration(milliseconds: 400),
            // Active tab styling
            activeColor: primaryColor,
            tabBackgroundColor: primaryColor.withValues(alpha: 0.1),
            // Inactive styling
            color: Colors.grey,
            textStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
            // Ripple/hover
            rippleColor: primaryColor.withValues(alpha: 0.1),
            hoverColor: primaryColor.withValues(alpha: 0.07),
            selectedIndex: selectedIndex,
            onTabChange: onTabChange,
            tabs: tabs,
          ),
        ),
      ),
    );
  }
}
