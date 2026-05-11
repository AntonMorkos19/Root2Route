import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/features/auctions/cubit/auction_cubit.dart';
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
import 'package:root2route/services/storage_service.dart';
import 'package:root2route/core/navigator_service.dart';
import 'package:root2route/screens/order/checkout_screen.dart';
import 'package:root2route/screens/order/cart_screen.dart';
import 'package:root2route/features/notifications/cubit/notification_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuctionCubit>(create: (_) => AuctionCubit()),
        BlocProvider<NotificationCubit>(create: (_) => NotificationCubit()..fetchNotifications()),
      ],
      child: MaterialApp(
        navigatorKey: NavigatorService.navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: false),
        initialRoute: SplashScreen.id,
        routes: {
          SplashScreen.id: (_) => const SplashScreen(),
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
      ),
    );
  }
}
