import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:root2route/features/auctions/cubit/auction_cubit.dart';
import 'package:root2route/screens/auction/my_auctions_screen.dart';
import 'package:root2route/screens/auction/create_auction_screen.dart';
import 'package:root2route/screens/auction/edit_auction_screen.dart';
import 'package:root2route/screens/auction/bid_history_screen.dart';
import 'package:root2route/screens/auth/create_new_password.dart';
import 'package:root2route/screens/auth/forgot_password_screen.dart';
import 'package:root2route/screens/auth/register_screen.dart';
import 'package:root2route/screens/guest/guest_home_screen.dart';
import 'package:root2route/screens/auth/login_screen.dart';
import 'package:root2route/screens/splash_screen.dart';
import 'package:root2route/services/storage_service.dart';
import 'package:root2route/core/navigator_service.dart';

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
      providers: [BlocProvider<AuctionCubit>(create: (_) => AuctionCubit())],
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
          MyAuctionsScreen.id:
              (_) => BlocProvider(
                create: (_) => AuctionCubit(),
                child: const MyAuctionsScreen(),
              ),
          CreateAuctionScreen.id:
              (_) => BlocProvider(
                create: (_) => AuctionCubit(),
                child: const CreateAuctionScreen(),
              ),
          EditAuctionScreen.id:
              (_) => BlocProvider(
                create: (_) => AuctionCubit(),
                child: const EditAuctionScreen(),
              ),
          BidHistoryScreen.id:
              (_) => BlocProvider(
                create: (_) => AuctionCubit(),
                child: const BidHistoryScreen(),
              ),
        },
      ),
    );
  }
}
