import 'package:flutter/material.dart';
import 'package:root2route/screens/auth/create_new_password.dart';
import 'package:root2route/screens/auth/forgot_password_screen.dart';
import 'package:root2route/screens/auth/register_screen.dart';
import 'package:root2route/screens/auth/recovery_screen.dart';
import 'package:root2route/screens/guest/guest_home_screen.dart';
import 'package:root2route/screens/auth/login_screen.dart';
import 'package:root2route/screens/guest/products_screen.dart';
import 'package:root2route/screens/splash_screen.dart';
import 'package:root2route/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة خدمة التخزين
  await StorageService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: false),
      initialRoute: SplashScreen.id,
      routes: {
        SplashScreen.id: (_) => const SplashScreen(),
        LoginScreen.id: (_) => const LoginScreen(),
        RegisterScreen.id: (_) => const RegisterScreen(),
        ForgotPasswordScreen.id: (_) => const ForgotPasswordScreen(),
        CreateNewPassword.id: (_) => const CreateNewPassword(),
        RecoveryScreen.id: (_) => const RecoveryScreen(),
        GuestHomeScreen.id: (_) => const GuestHomeScreen(),
        ProductsScreen.id: (_) => const ProductsScreen(),
      },
    );
  }
}



