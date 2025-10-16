import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../router.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const double _designW = 430;
  static const double _designH = 932;
  static const double _goW = 137;
  static const double _goH = 46;
  static const double _goLeftFrac = 0.58;
  static const double _goTopFrac = 0.55;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;

            final scaleX = w / _designW;
            final scaleY = h / _designH;
            final uni = math.min(scaleX, scaleY);

            final btnW = (_goW * uni).clamp(110.0, 200.0);
            final btnH = (_goH * uni).clamp(36.0, 70.0);
            final btnLeft = (w * _goLeftFrac);
            final btnTop = (h * _goTopFrac);

            return Stack(
              children: [
                const Positioned.fill(child: ColoredBox(color: Colors.white)),
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/splashScreen.png',
                    fit: BoxFit.fill,
                  ),
                ),
                Positioned(
                  left: btnLeft,
                  top: btnTop,
                  width: btnW,
                  height: btnH,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pushReplacementNamed(AppRoutes.login),
                    child: Image.asset(
                      'assets/images/Continue Button.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
