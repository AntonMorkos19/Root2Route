import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService().init();
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
        BlocProvider<NotificationCubit>(create: (_) => NotificationCubit()..fetchNotifications()),
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
                    ModalRoute.of(context)!.settings.arguments as AuctionModel;
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
