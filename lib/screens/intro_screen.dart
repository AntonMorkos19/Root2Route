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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: IntroductionScreen(
        globalBackgroundColor: Colors.white,
        allowImplicitScrolling: true,
        pages: [
          PageViewModel(
            title: "أهلاً بك في Root2Route",
            body:
                "سوقك الزراعي المتكامل. تواصل مباشرةً مع شبكة موثوقة من المشترين والبائعين لتداول المحاصيل بسهولة وثقة.",
            image: _buildImage(Icons.agriculture_rounded),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "وصول مباشر للسوق",
            body:
                "تخلّص من الوسيط. اشترِ المنتجات الطازجة مباشرةً من المزارعين أو بِع محصولك لشبكة واسعة من العملاء.",
            image: _buildImage(Icons.shopping_basket_rounded),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "مزادات فورية",
            body:
                "انضم للمزايدة الحية! احصل على محاصيل عالية الجودة بأفضل الأسعار أو حقّق أعلى عائد من محصولك.",
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
          'تخطي',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E7D32),
          ),
        ),
        next: const Icon(Icons.arrow_forward, color: Color(0xFF2E7D32)),
        done: const Text(
          'ابدأ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E7D32),
          ),
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
