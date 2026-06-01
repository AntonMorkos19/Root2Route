import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:root2route/screens/auth/login_screen.dart';
import 'package:root2route/screens/guest/guest_home_screen.dart';
import 'package:root2route/screens/farmer/farmer_home_screen.dart';
import 'package:root2route/screens/intro_screen.dart';
import 'package:root2route/services/api.dart';
import 'package:root2route/services/storage_service.dart';
import 'package:root2route/screens/factory/factory_home_screen.dart';
import 'package:root2route/screens/restaurant/restaurant_home_screen.dart';
import 'package:root2route/screens/tradesman/tradesman_home_screen.dart';

class SplashScreen extends StatefulWidget {
  static const String id = '/splashScreen';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    _initializeAndRoute();
  }

  Future<void> _initializeAndRoute() async {
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    final isFirstTime = StorageService().isFirstTime;

    if (isFirstTime) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const IntroScreen()),
        (route) => false,
      );
      return;
    }

    final isLoggedIn = StorageService().isLoggedIn;
    final isTokenValid = StorageService().isTokenValid;

    if (!isLoggedIn || !isTokenValid) {
      if (isLoggedIn && !isTokenValid) {
        debugPrint('Access Token expired. Attempting silent refresh...');
        bool refreshed = await ApiService().refreshAuthToken();
        
        if (!refreshed) {
          await StorageService().logout();
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
          return;
        }
      } else {
        if (!mounted) return;
        final isExplicitGuest = StorageService().isExplicitGuest;

        if (isExplicitGuest) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const GuestHomeScreen()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
        return;
      }
    }

    final hasOrganization = StorageService().hasOrganization;
    final orgType = StorageService().organizationType;

    if (hasOrganization) {
      Widget targetScreen = const FarmerHomeScreen();
      if (orgType != null) {
        switch (orgType) {
          case 0:
            targetScreen = const FarmerHomeScreen();
            break;
          case 1:
            targetScreen = const RestaurantHomeScreen();
            break;
          case 2:
            targetScreen = const FactoryHomeScreen();
            break;
          case 3:
            targetScreen = const TradesmanHomeScreen();
            break;
        }
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => targetScreen),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const GuestHomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B5E20),
              Color(0xFF2E7D32),
              Color(0xFF388E3C),
              Color(0xFF43A047),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _animation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Image.asset(
                    "assets/images/SplashScreen.png",
                    width: 260,
                    height: 260,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 28),

                Text(
                  'Root2Route',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Manage  • Connect  •  Grow",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8,
                  ),
                ),

                const SizedBox(height: 48),

                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
