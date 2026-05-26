import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:root2route/screens/auth/login_screen.dart';
import 'package:root2route/services/storage_service.dart';

class IntroScreen extends StatelessWidget {
  static const String id = '/introScreen';

  const IntroScreen({super.key});

  void _onIntroEnd(BuildContext context) async {
    await StorageService().saveIsFirstTime(false);
    Navigator.of(context).pushReplacementNamed(LoginScreen.id);
  }

  @override
  Widget build(BuildContext context) {
    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.w700,
        color: Color(0xFF2E7D32),
      ),
      bodyTextStyle: TextStyle(fontSize: 16.0, color: Colors.black87),
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      globalBackgroundColor: Colors.white,
      allowImplicitScrolling: true,
      pages: [
        PageViewModel(
          title: "Welcome to Root2Route",
          body:
              "Your ultimate agricultural marketplace. Connect directly with a trusted network of buyers and sellers to trade crops with ease and confidence.",
          image: _buildImage(Icons.agriculture_rounded),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Direct Market Access",
          body:
              "Cut out the middleman. Buy premium fresh produce straight from farmers or sell your harvest to a massive network.",
          image: _buildImage(Icons.shopping_basket_rounded),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Real-Time Auctions",
          body:
              "Join live bidding! Secure high-quality crops at the best market prices or maximize the profit of your own yield.",
          image: _buildImage(Icons.gavel_rounded),
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context),
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      skip: const Text(
        'Skip',
        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
      ),
      next: const Icon(Icons.arrow_forward, color: Color(0xFF2E7D32)),
      done: const Text(
        'Done',
        style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
      ),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Color(0xFFBDBDBD),
        activeSize: Size(22.0, 10.0),
        activeColor: Color(0xFF2E7D32),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }

  Widget _buildImage(IconData iconData) {
    return Container(
      margin: const EdgeInsets.only(top: 60.0),
      padding: const EdgeInsets.all(40.0),
      decoration: const BoxDecoration(
        color: Color(0xFFE8F5E9),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, size: 100.0, color: const Color(0xFF2E7D32)),
    );
  }
}
