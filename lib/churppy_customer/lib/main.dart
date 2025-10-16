import 'package:flutter/material.dart';
import 'theme.dart';
import 'router.dart';

void main() {
  runApp(const ChurppyApp());
}

class ChurppyApp extends StatelessWidget {
  const ChurppyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Churppy Customer UI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final clamped = media.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.30);
        return MediaQuery(
          data: media.copyWith(textScaler: clamped),
          child: child ?? const SizedBox.shrink(),
        );
      },
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRoutes.SplashStep2BottomAligned,
      scrollBehavior: const AppScrollBehavior(),
    );
  }
}
