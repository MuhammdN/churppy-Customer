import 'package:churppy_customer/screens/auth/login.dart';
import 'package:churppy_customer/screens/auth/signup_screen.dart';
import 'package:churppy_customer/screens/churppy_difference.dart';
import 'package:churppy_customer/screens/slider1.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:audioplayers/audioplayers.dart'; // 🎵



class SplashScreen1 extends StatefulWidget {
  const SplashScreen1({super.key});

  @override
  State<SplashScreen1> createState() => _SplashScreen1State();
}

class _SplashScreen1State extends State<SplashScreen1>
    with TickerProviderStateMixin {
  late final AnimationController _wingController;
  late final AnimationController _moveController;
  late final AnimationController _bounceController;
  late final AnimationController _fadeController;
  late final AnimationController _buttonController;
  late final AudioPlayer _audioPlayer;

  int _frame = 0;
  bool _animationEnded = false;

  final List<String> birdFramesNormal = [
    'assets/images/spd1.png',
    'assets/images/spd2.png',
    'assets/images/spd3.png',
  ];

  final List<String> birdFramesTurn = [
    'assets/images/sp1.png',
    'assets/images/sp2.png',
    'assets/images/sp3.png',
  ];

  late final Path flightPath;

  @override
  void initState() {
    super.initState();

    flightPath = parseSvgPathData('M316,378S93,345,64,217s117-67,117-67');
    _audioPlayer = AudioPlayer();

    _wingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    )..addListener(() {
        if (_wingController.status == AnimationStatus.completed) {
          _wingController.repeat();
        }
        setState(() {
          _frame = (_wingController.value * 3).floor() % 3;
        });
      });
    _wingController.forward();

    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _animationEnded = true);
          _playDing();
          _startBounce();
          _fadeController.forward();
          Future.delayed(const Duration(milliseconds: 600), () {
            _buttonController.forward();
          });
        }
      })
      ..forward();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  Future<void> _playDing() async {
    try {
      await _audioPlayer.play(AssetSource('audio/1.wav'));
    } catch (e) {
      debugPrint("⚠️ Audio error: $e");
    }
  }

  void _startBounce() {
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _wingController.dispose();
    _moveController.dispose();
    _bounceController.dispose();
    _fadeController.dispose();
    _buttonController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Offset _getPositionAlongPath(double progress) {
    final pathMetric = flightPath.computeMetrics().first;
    final pos =
        pathMetric.getTangentForOffset(pathMetric.length * progress * 0.9);
    return pos?.position ?? Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final endPos = _getPositionAlongPath(1.0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background1.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            /// 🔔 Bell
            Align(
              alignment: const Alignment(0, -0.72),
              child: Image.asset(
                'assets/images/bell_churppy.png',
                width: screenW * 0.28,
              ),
            ),

            /// 🕊️ Flying bird
            if (!_animationEnded)
              AnimatedBuilder(
                animation: _moveController,
                builder: (context, child) {
                  final progress = _moveController.value;
                  final pos = _getPositionAlongPath(progress);

                  double fadeFactor = 0.0;
                  if (progress >= 0.65 && progress <= 0.75) {
                    fadeFactor = (progress - 0.65) / 0.1;
                  } else if (progress > 0.75) {
                    fadeFactor = 1.0;
                  }

                  final double x = (pos.dx - 50) / 400 * screenW;
                  final double y = (pos.dy - 100) / 800 * screenH;

                  return Positioned(
                    left: x,
                    top: y,
                    child: Stack(
                      children: [
                        Opacity(
                          opacity: 1 - fadeFactor,
                          child: Transform.scale(
                            scale: 0.38,
                            child: Image.asset(
                              birdFramesNormal[_frame],
                              width: screenW * 0.45,
                            ),
                          ),
                        ),
                        Opacity(
                          opacity: fadeFactor,
                          child: Transform.scale(
                            scale: 0.38,
                            child: Image.asset(
                              birdFramesTurn[_frame],
                              width: screenW * 0.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            /// 🕊️ Landed bird
            if (_animationEnded)
              AnimatedBuilder(
                animation:
                    Listenable.merge([_bounceController, _fadeController]),
                builder: (context, child) {
                  final double bounceY =
                      (_bounceController.value - 0.5) * 10;
                  final opacity =
                      Curves.easeInOut.transform(_fadeController.value);
                  final scale = 0.8 + (_fadeController.value * 0.2);

                  return Positioned(
                    left: ((endPos.dx - 35) / 400 * screenW),
                    top: ((endPos.dy - 140) / 800 * screenH + bounceY),
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: 0.8,
                        child: Image.asset(
                          'assets/images/last_bird.png',
                          width: screenW * 0.45,
                        ),
                      ),
                    ),
                  );
                },
              ),

            /// 🟣 Logo (slightly moved up)
            Align(
              alignment: const Alignment(0, -0.20),
              child: Image.asset(
                'assets/images/logo2.png',
                width: screenW * 0.8,
                fit: BoxFit.contain,
              ),
            ),

            /// 🎨 Buttons
            AnimatedBuilder(
              animation: _buttonController,
              builder: (context, child) {
                final slideY =
                    60 * (1 - Curves.easeOut.transform(_buttonController.value));
                final opacity =
                    Curves.easeInOut.transform(_buttonController.value);
                return Positioned(
                  bottom: screenH * 0.12 + slideY,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: opacity,
                    child: Column(
                      children: [
                        _buildButton(
                          text: "Sign Up",
                          color: Color(0xFF804692),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildButton(
                          text: "Login",
                          color: const Color(0xFF8DC63F),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildButton(
                          text:
                              "Foodtrucks | Mobile | Vendors (Business App)",
                          color: Colors.pink,
                          onTap: () =>
                              debugPrint("Business App (Vendor) pressed"),
                        ),
                        const SizedBox(height: 12),
                        _buildButton(
                          text: "Explore More → The Churppy Difference",
                          color: Colors.lightBlue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChurppyDifference(),
                              ),
                            );
                          },
                        ),

                        /// 🧡 Tagline as tapable button
                        const SizedBox(height: 25),
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          splashColor: const Color(0xFFFF9633).withOpacity(0.3),
                          onTap: () {
                         Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Slider1(),
                                        ),
                                      );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(
                              "Why you’ll love CHURPPY!",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lemon(
                                fontSize: 19.25,
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.normal,
                                color: const Color(0xFFFF9633),
                                letterSpacing: -0.36,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            /// 📜 Footer Text
            Positioned(
              bottom: 29,
              left: 0,
              right: 0,
              child: Text(
                "Churppy\nTrademark and Patent Pending",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 70),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white.withOpacity(0.2),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
