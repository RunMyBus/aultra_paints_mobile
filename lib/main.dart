import 'dart:io';

import 'package:aultra_paints_mobile/screens/LayOut/LayOutPage.dart';
import 'package:aultra_paints_mobile/screens/catalog/ProductsCatalogScreen.dart';
import 'package:aultra_paints_mobile/screens/dashboard/DashboardNewPage.dart';
import 'package:aultra_paints_mobile/screens/dashboard/PainterPopUpPage.dart';
import 'package:aultra_paints_mobile/screens/launch/launchPage.dart';
import 'package:aultra_paints_mobile/screens/painter/PainterPage.dart';
import 'package:aultra_paints_mobile/screens/pointsLedger/pointsLedgerPage.dart';
import 'package:aultra_paints_mobile/services/UserViewModel.dart';
import 'package:aultra_paints_mobile/screens/cart/CartScreen.dart';
import 'package:aultra_paints_mobile/providers/cart_provider.dart';
import 'package:aultra_paints_mobile/providers/auth_provider.dart';

import '/screens/authentication/otp/OtpPage.dart';
import 'screens/myOrders/myOrdersPage.dart';
import 'screens/orders/createOrder/CreateOrders.dart';
import 'screens/orders/createProduct/CreateProduct.dart';
import 'screens/orders/orderDetails/OrderDetails.dart';
import 'screens/orders/ordersList/OrdersList.dart';
import 'screens/orders/qrScanner/QrScanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '/utility/CustomAnimation.dart';
import 'package:provider/provider.dart';

import '/screens/authentication/login/LoginPage.dart';
import '/screens/authentication/login/LoginViewModel.dart';
import 'screens/splash/SplashPage.dart';
import '/screens/dashboard/DashboardPage.dart';
import '/screens/authentication/signup/SignupPage.dart';

void configLoading() {
  EasyLoading.instance
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..maskType = EasyLoadingMaskType.black
    ..userInteractions = false
    ..dismissOnTap = false;
}

Future<void> main() async {
  configLoading();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<LoginViewModel>(
        create: (context) => LoginViewModel(),
      ),
      ChangeNotifierProvider<UserViewModel>(
        create: (context) => UserViewModel(),
      ),
      ChangeNotifierProvider<CartProvider>(
        create: (context) => CartProvider(),
      ),
      ChangeNotifierProvider<AuthProvider>(
        create: (context) => AuthProvider(),
      ),
    ],
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  Map<dynamic, dynamic>? get dealer => null;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: EasyLoading.init(),
      // title: '',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        platform: TargetPlatform.iOS,
      ),
      home: const SplashPage(),
      // home: const DashboardPage(),
      routes: {
        "/splashPage": (context) => const SplashPage(),
        "/launchPage": (context) => const LaunchPage(),
        "/loginPage": (context) => const LoginPage(),
        "/signupPage": (context) => const SignupPage(),
        "/otpPage": (context) => const OtpPage(),
        "/dashboardPage": (context) => LayoutPage(child: DashboardNewPage()),
        "/painters": (context) => LayoutPage(child: PainterPage()),
        "/qrScanner": (context) => const QrScanner(),
        "/painterPopUpPage": (context) => const PainterPopUpPage(),
        "/pointsLedgerPage": (context) => LayoutPage(child: PointsLedgerPage()),
        "/cart": (context) => CartScreen(dealer!),
        "/ProductsCatalogScreen": (context) =>
            LayoutPage(child: ProductsCatalogScreen()),
        "/myOrdersPage": (context) => LayoutPage(child: MyOrdersPage()),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const LoginPage(),
        );
      },
    );
  }
}
