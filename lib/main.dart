import 'package:churppy_customer/screens/firstpage.dart';
import 'package:churppy_customer/screens/splash_screen.dart';
import 'package:churppy_customer/screens/splash_screen1.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

void main() {
   WidgetsFlutterBinding.ensureInitialized();

  
  Stripe.publishableKey = "pk_test_51S5zcnRrXfDjT97KJW5stvP7bGYTJZAiBsLYkWM4rhC8kDW6s1hqWsO6EY3h21m7PJVCLc4CeJXYOuZ562DW6VbZ00PmGFh5bv";
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // ✅ Debug banner हट गया
      title: 'Churppy',
      themeMode: ThemeMode.light, // ✅ सिर्फ Light Mode enforce किया
      theme: ThemeData(
        brightness: Brightness.light, // ✅ Dark theme disable
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SplashScreen1(),
    );
  }
}
