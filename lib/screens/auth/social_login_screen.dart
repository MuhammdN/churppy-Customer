import 'package:churppy_customer/screens/google_login_service.dart.dart';
import 'package:flutter/material.dart';


class SocialLoginScreen extends StatelessWidget {
  const SocialLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Social Login Test')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                await SocialAuthService.loginWithGoogle();
              },
              child: const Text('Continue with Google'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await SocialAuthService.loginWithApple();
              },
              child: const Text('Continue with Apple'),
            ),
          ],
        ),
      ),
    );
  }
}
