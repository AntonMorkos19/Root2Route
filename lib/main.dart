 import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:root2route/core/services/api.dart';
import 'package:root2route/features/notifications/data/services/local_notification_service.dart';
import 'package:root2route/core/theme/app_theme.dart';
import 'package:root2route/features/auctions/cubit/auction_cubit.dart';
import 'package:root2route/features/theme/cubit/theme_cubit.dart';
import 'package:root2route/features/auctions/data/models/auction_model.dart';
import 'package:root2route/features/auctions/ui/create_auction_screen.dart';
import 'package:root2route/features/auctions/ui/bid_history_screen.dart';
import 'package:root2route/features/auctions/ui/update_auction_screen.dart';
import 'package:root2route/features/auctions/ui/buyer_auctions_screen.dart';
import 'package:root2route/features/auctions/ui/auction_details_screen.dart';
import 'package:root2route/features/auth/ui/create_new_password.dart';
import 'package:root2route/features/auth/ui/forgot_password_screen.dart';
import 'package:root2route/features/auth/ui/register_screen.dart';
import 'package:root2route/features/dashboards/ui/guest/guest_home_screen.dart';
import 'package:root2route/features/auth/ui/login_screen.dart';
import 'package:root2route/features/startup/ui/splash_screen.dart';
import 'package:root2route/features/startup/ui/intro_screen.dart';
import 'package:root2route/core/services/storage_service.dart';
import 'package:root2route/core/navigator_service.dart';
import 'package:root2route/features/orders/ui/checkout_screen.dart';
import 'package:root2route/features/orders/ui/cart_screen.dart';
import 'package:root2route/features/notifications/cubit/notification_cubit.dart';
import 'package:root2route/features/cart/cubit/cart_cubit.dart';

// ── Background handler ──────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FCM-BG] Handling background message: ${message.messageId}');
  debugPrint('[FCM-BG] Title: ${message.notification?.title}');
  debugPrint('[FCM-BG] Body : ${message.notification?.body}');
}

// ── FCM setup ───────────────────────────────────────────────────────────────
Future<void> setupFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    debugPrint('[FCM]  Notification permission granted');

    String? token = await messaging.getToken();
    debugPrint('====================================');
    debugPrint('FCM DEVICE TOKEN: $token');
    debugPrint('====================================');

    if (StorageService().isLoggedIn) {
      ApiService().sendFcmToken();
    }

    messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] Token refreshed: $newToken');
      if (StorageService().isLoggedIn) {
        ApiService().sendFcmToken();
      }
    });

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM-FG]  Foreground message received');
      LocalNotificationService().showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM]  Notification opened app — data: ${message.data}');
    });
  } else {
    debugPrint('[FCM]  User denied notification permission');
  }
}

// ── Main ─────────────────────────────────────────────────────────────────────
void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await LocalNotificationService().init();

  ApiService.setFcmTokenProvider(() => FirebaseMessaging.instance.getToken());

  await StorageService().init();

   setupFCM();

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
