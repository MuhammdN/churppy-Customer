import 'package:churppy_customer/screens/firstpage.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen1.dart';

class AppRoutes {
  static const SplashStep2BottomAligned = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const product = '/product';
  static const cart = '/cart';
  static const payment = '/payment';
  static const alerts = '/alerts';
  static const mapAlerts = '/alerts/map';
  static const profile = '/profile';
  static const support = '/support';
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.SplashStep2BottomAligned:
        return _mat(const SplashStep2BottomAligned(), settings);
      case AppRoutes.login:
        return _mat(const LoginScreen(), settings);
      default:
        return _mat(const _NotFound(), settings);
    }
  }

  static MaterialPageRoute _mat(Widget child, RouteSettings s) =>
      MaterialPageRoute(builder: (_) => child, settings: s);
}

class _NotFound extends StatelessWidget {
  const _NotFound({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Route not found')));
  }
}
