// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// // --- إضافات الفايربيز ---
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'firebase_options.dart';
// // ------------------------

// import 'package:root2route/core/theme/app_theme.dart';
// import 'package:root2route/features/auctions/cubit/auction_cubit.dart';
// import 'package:root2route/features/theme/cubit/theme_cubit.dart';
// import 'package:root2route/models/auction_model.dart';
// import 'package:root2route/screens/auction/create_auction_screen.dart';
// import 'package:root2route/screens/auction/bid_history_screen.dart';
// import 'package:root2route/screens/auction/update_auction_screen.dart';
// import 'package:root2route/screens/auction/buyer_auctions_screen.dart';
// import 'package:root2route/screens/auction/auction_details_screen.dart';
// import 'package:root2route/screens/auth/create_new_password.dart';
// import 'package:root2route/screens/auth/forgot_password_screen.dart';
// import 'package:root2route/screens/auth/register_screen.dart';
// import 'package:root2route/screens/guest/guest_home_screen.dart';
// import 'package:root2route/screens/auth/login_screen.dart';
// import 'package:root2route/screens/splash_screen.dart';
// import 'package:root2route/screens/intro_screen.dart';
// import 'package:root2route/services/storage_service.dart';
// import 'package:root2route/core/navigator_service.dart';
// import 'package:root2route/screens/order/checkout_screen.dart';
// import 'package:root2route/screens/order/cart_screen.dart';
// import 'package:root2route/features/notifications/cubit/notification_cubit.dart';
// import 'package:root2route/features/cart/cubit/cart_cubit.dart';

// // 1. الدالة دي لازم تكون بره أي كلاس (عشان تشتغل والأبلكيشن مقفول تماماً)
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   print("Handling a background message: ${message.messageId}");
// }

// // 2. دالة طلب الصلاحيات وجلب الـ Token بتاع الجهاز
// Future<void> setupFCM() async {
//   FirebaseMessaging messaging = FirebaseMessaging.instance;

//   // طلب الصلاحيات (ضروري جداً للأندرويد 13+ والآيفون)
//   NotificationSettings settings = await messaging.requestPermission(
//     alert: true,
//     badge: true,
//     sound: true,
//   );

//   if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//     print('تم إعطاء صلاحية الإشعارات بنجاح!');

//     // الحصول على التوكين السحري!
//     String? token = await messaging.getToken();
//     print("====================================");
//     print("FCM DEVICE TOKEN: $token");
//     print("====================================");
//   } else {
//     print('المستخدم رفض صلاحية الإشعارات.');
//   }
// }

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // --- تهيئة الفايربيز ---
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

//   // ربط الإشعارات في الخلفية
//   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

//   // استدعاء دالة طلب الصلاحيات وجلب التوكين
//   await setupFCM();
//   // -----------------------

//   await StorageService().init();
//   final themeCubit = ThemeCubit();
//   await themeCubit.loadTheme();

//   runApp(MyApp(themeCubit: themeCubit));
// }

// class MyApp extends StatelessWidget {
//   final ThemeCubit themeCubit;
//   const MyApp({super.key, required this.themeCubit});

//   @override
//   Widget build(BuildContext context) {
//     return MultiBlocProvider(
//       providers: [
//         BlocProvider<ThemeCubit>.value(value: themeCubit),
//         BlocProvider<AuctionCubit>(create: (_) => AuctionCubit()),
//         BlocProvider<NotificationCubit>(
//           create: (_) => NotificationCubit()..fetchNotifications(),
//         ),
//         BlocProvider<CartCubit>(create: (_) => CartCubit()),
//       ],
//       child: ScreenUtilInit(
//         designSize: const Size(360, 690),
//         minTextAdapt: true,
//         splitScreenMode: true,
//         builder: (_, child) {
//           return BlocBuilder<ThemeCubit, ThemeState>(
//             builder: (context, themeState) {
//               return MaterialApp(
//                 navigatorKey: NavigatorService.navigatorKey,
//                 debugShowCheckedModeBanner: false,
//                 theme: AppTheme.lightTheme,
//                 darkTheme: AppTheme.darkTheme,
//                 themeMode: themeState.themeMode,
//                 initialRoute: SplashScreen.id,
//                 routes: {
//                   SplashScreen.id: (_) => const SplashScreen(),
//                   IntroScreen.id: (_) => const IntroScreen(),
//                   LoginScreen.id: (_) => const LoginScreen(),
//                   RegisterScreen.id: (_) => const RegisterScreen(),
//                   ForgotPasswordScreen.id: (_) => const ForgotPasswordScreen(),
//                   CreateNewPassword.id: (_) => const CreateNewPassword(),
//                   GuestHomeScreen.id: (_) => const GuestHomeScreen(),
//                   CreateAuctionScreen.id: (_) => const CreateAuctionScreen(),
//                   UpdateAuctionScreen.id: (context) {
//                     final auction =
//                         ModalRoute.of(context)!.settings.arguments
//                             as AuctionModel;
//                     return UpdateAuctionScreen(auction: auction);
//                   },
//                   BidHistoryScreen.id: (_) => const BidHistoryScreen(),
//                   AuctionDetailsScreen.id: (_) => const AuctionDetailsScreen(),
//                   BuyerAuctionsScreen.id: (_) => const BuyerAuctionsScreen(),
//                   CheckoutScreen.id: (_) => const CheckoutScreen(),
//                   CartScreen.id: (_) => const CartScreen(),
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// --- إضافات الفايربيز ---
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
// ------------------------

import 'package:root2route/services/api.dart';

import 'package:root2route/core/theme/app_theme.dart';
import 'package:root2route/features/auctions/cubit/auction_cubit.dart';
import 'package:root2route/features/theme/cubit/theme_cubit.dart';
import 'package:root2route/models/auction_model.dart';
import 'package:root2route/screens/auction/create_auction_screen.dart';
import 'package:root2route/screens/auction/bid_history_screen.dart';
import 'package:root2route/screens/auction/update_auction_screen.dart';
import 'package:root2route/screens/auction/buyer_auctions_screen.dart';
import 'package:root2route/screens/auction/auction_details_screen.dart';
import 'package:root2route/screens/auth/create_new_password.dart';
import 'package:root2route/screens/auth/forgot_password_screen.dart';
import 'package:root2route/screens/auth/register_screen.dart';
import 'package:root2route/screens/guest/guest_home_screen.dart';
import 'package:root2route/screens/auth/login_screen.dart';
import 'package:root2route/screens/splash_screen.dart';
import 'package:root2route/screens/intro_screen.dart';
import 'package:root2route/services/storage_service.dart';
import 'package:root2route/core/navigator_service.dart';
import 'package:root2route/screens/order/checkout_screen.dart';
import 'package:root2route/screens/order/cart_screen.dart';
import 'package:root2route/features/notifications/cubit/notification_cubit.dart';
import 'package:root2route/features/cart/cubit/cart_cubit.dart';

 @pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

// دالة طلب الصلاحيات وجلب الـ Token واستقبال الإشعارات
Future<void> setupFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('تم إعطاء صلاحية الإشعارات بنجاح!');

    String? token = await messaging.getToken();
    print("====================================");
    print("FCM DEVICE TOKEN: $token");
    print("====================================");

    // 🔔 If the user is already logged in (app re-launch), send the FCM
    // token to the backend immediately. This covers the case where the
    // token was refreshed since the last session, or was never uploaded.
    // The call is fire-and-forget; errors are handled inside sendFcmToken.
    if (StorageService().isLoggedIn) {
      ApiService().sendFcmToken();
    }

    // --- لقط الإشعار والأبلكيشن مفتوح ---
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 إشعار جديد وصل والأبلكيشن مفتوح!');
      if (message.notification != null) {
        print('عنوان الإشعار: ${message.notification!.title}');
        print('محتوى الإشعار: ${message.notification!.body}');
      }
    });
    // ----------------------------------------------------
  } else {
    print('المستخدم رفض صلاحية الإشعارات.');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة الفايربيز
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔔 Register the FCM token provider with ApiService so the service layer
  // can obtain the device token without importing firebase_messaging directly.
  ApiService.setFcmTokenProvider(
    () => FirebaseMessaging.instance.getToken(),
  );

  // ربط الإشعارات في الخلفية
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await StorageService().init();

  // استدعاء دالة الفايربيز (بعد init حتى يكون StorageService جاهزاً)
  await setupFCM();

  final themeCubit = ThemeCubit();
  await themeCubit.loadTheme();

  runApp(MyApp(themeCubit: themeCubit));
}

class MyApp extends StatelessWidget {
  final ThemeCubit themeCubit;
  const MyApp({super.key, required this.themeCubit});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: themeCubit),
        BlocProvider<AuctionCubit>(create: (_) => AuctionCubit()),
        BlocProvider<NotificationCubit>(
          create: (_) => NotificationCubit()..fetchNotifications(),
        ),
        BlocProvider<CartCubit>(create: (_) => CartCubit()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, child) {
          return BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              return MaterialApp(
                navigatorKey: NavigatorService.navigatorKey,
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeState.themeMode,
                initialRoute: SplashScreen.id,
                routes: {
                  SplashScreen.id: (_) => const SplashScreen(),
                  IntroScreen.id: (_) => const IntroScreen(),
                  LoginScreen.id: (_) => const LoginScreen(),
                  RegisterScreen.id: (_) => const RegisterScreen(),
                  ForgotPasswordScreen.id: (_) => const ForgotPasswordScreen(),
                  CreateNewPassword.id: (_) => const CreateNewPassword(),
                  GuestHomeScreen.id: (_) => const GuestHomeScreen(),
                  CreateAuctionScreen.id: (_) => const CreateAuctionScreen(),
                  UpdateAuctionScreen.id: (context) {
                    final auction =
                        ModalRoute.of(context)!.settings.arguments
                            as AuctionModel;
                    return UpdateAuctionScreen(auction: auction);
                  },
                  BidHistoryScreen.id: (_) => const BidHistoryScreen(),
                  AuctionDetailsScreen.id: (_) => const AuctionDetailsScreen(),
                  BuyerAuctionsScreen.id: (_) => const BuyerAuctionsScreen(),
                  CheckoutScreen.id: (_) => const CheckoutScreen(),
                  CartScreen.id: (_) => const CartScreen(),
                },
              );
            },
          );
        },
      ),
    );
  }
}
