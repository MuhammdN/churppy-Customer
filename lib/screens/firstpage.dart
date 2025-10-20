import 'dart:async';
import 'dart:ui' show lerpDouble;
import 'package:audioplayers/audioplayers.dart';
import 'package:churppy_customer/screens/why_churppy_screen.dart';
import 'package:flutter/material.dart';

class SplashStep2BottomAligned extends StatefulWidget {
  const SplashStep2BottomAligned({super.key, this.onSkip});
  final VoidCallback? onSkip;

  @override
  State<SplashStep2BottomAligned> createState() =>
      _SplashStep2BottomAlignedState();
}

class _SplashStep2BottomAlignedState extends State<SplashStep2BottomAligned>
    with TickerProviderStateMixin {
  late AnimationController _zoomCtrl;
  late Animation<double> _zoom;

  // End zoom (zoom-out) controller
  late AnimationController _endZoomCtrl;
  late Animation<double> _endZoom;

  late AnimationController _trackCtrl1;
  late Animation<double> _t1;

  late AnimationController _trackCtrl2;
  late Animation<double> _t2;

  Timer? _bounceTimer;
  double _bounce = 0;

  late AnimationController _bellAppearCtrl;
  late AnimationController _bellSwingCtrl;
  late AnimationController _bellUpCtrl;
  late AnimationController _logoCtrl;
  bool _showCenterBell = false;
  bool _showCenterLogo = false;

  bool _showSkip = true;

  // Two players: one for bell ding, one for chirp sound (so they can overlap if needed)
  late final AudioPlayer _bellPlayer;
  late final AudioPlayer _churpPlayer;

  @override
  void initState() {
    super.initState();

    // Audio players
    _bellPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    _churpPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

    _zoomCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    _zoom = Tween<double>(begin: 1.80, end: 1.1).animate(
      CurvedAnimation(parent: _zoomCtrl, curve: Curves.easeInOut),
    )..addListener(() => setState(() {}));

    // end zoom (zoom-out) controller: starts only when track phase 2 completes
    _endZoomCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _endZoom = Tween<double>(begin: 1.0, end: 0.80).animate(
      CurvedAnimation(parent: _endZoomCtrl, curve: Curves.easeInOut),
    )..addListener(() => setState(() {}));
    _endZoomCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        // After zoom-out done, navigate to next screen
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TrackWithTruck()),
        );
      }
    });

    _trackCtrl1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    )..addStatusListener((s) async {
      if (s == AnimationStatus.completed) {
        await Future.delayed(const Duration(milliseconds: 120));
        await _startBellLogoCenterSequence();
        if (!mounted) return;
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        _trackCtrl2.forward();
      }
    });
    _t1 = CurvedAnimation(parent: _trackCtrl1, curve: Curves.easeInOut)
      ..addListener(() => setState(() {}));

    _trackCtrl2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 9000),
    );
    _t2 = CurvedAnimation(parent: _trackCtrl2, curve: Curves.easeInOut)
      ..addListener(() => setState(() {}));

    /// 🚀 When Phase 2 ends, first play the final zoom-out, then navigation occurs
    _trackCtrl2.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        // start end zoom; navigation is handled in _endZoomCtrl.status listener
        _endZoomCtrl.forward();
      }
    });

    _bounceTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      setState(() => _bounce = _bounce == 0 ? -4 : 0);
    });

    _bellAppearCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bellSwingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _bellUpCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    /// 👉 Delay 2 seconds before starting initial animations (as before)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _zoomCtrl.forward();
        _trackCtrl1.forward();
      }
    });
  }

  Future<void> _startBellLogoCenterSequence() async {
    setState(() => _showCenterBell = true);
    await _bellAppearCtrl.forward();

    // Play sounds: ding ding then chirp chirp (client requested "churp churp").
    // Using two players so chirps can overlap / be independent.
    try {
      // Ding 1
      await _bellPlayer.play(AssetSource('audio/ding.mp3'), volume: 1.0);
      await Future.delayed(const Duration(milliseconds: 250));
      // Ding 2
      await _bellPlayer.play(AssetSource('audio/ding.mp3'), volume: 1.0);

      // Short pause then chirps
      await Future.delayed(const Duration(milliseconds: 180));
      await _churpPlayer.play(AssetSource('audio/churp.mp3'), volume: 1.0);
      await Future.delayed(const Duration(milliseconds: 180));
      await _churpPlayer.play(AssetSource('audio/churp.mp3'), volume: 1.0);
    } catch (_) {
      // ignore audio errors silently
    }

    // Bell wiggle and lift + show logo
    _bellSwingCtrl.repeat(reverse: true);
    await Future.delayed(const Duration(milliseconds: 500));
    _bellUpCtrl.forward();

    setState(() => _showCenterLogo = true);
    await _logoCtrl.forward();

    // Optionally stop bell swing after some time so it doesn't spin forever.
    // We'll stop it after 1500ms from showing logo (you can adjust or remove)
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _bellSwingCtrl.stop();
    });
  }

  @override
  void dispose() {
    _zoomCtrl.dispose();
    _endZoomCtrl.dispose();
    _trackCtrl1.dispose();
    _trackCtrl2.dispose();
    _bellAppearCtrl.dispose();
    _bellSwingCtrl.dispose();
    _bellUpCtrl.dispose();
    _logoCtrl.dispose();
    _bounceTimer?.cancel();
    _bellPlayer.dispose();
    _churpPlayer.dispose();
    super.dispose();
  }

  Path _buildTruckPathPhase1(Size screen) {
    final w = screen.width;
    const leftPad = 15.0;
    final trackW = w * 0.70;
    Offset p(double fx, double fy) =>
        Offset(leftPad + trackW * fx, 55 + trackW * fy);

    return Path()
      ..moveTo(p(0.08, 0).dx, p(0.08, 0).dy)
      ..lineTo(p(0.22, 0).dx, p(0.22, 0).dy)
      ..lineTo(p(0.55, 0).dx, p(0.55, 0).dy)
      ..quadraticBezierTo(
        p(0.600, 0.029).dx,
        p(0.515, 0.025).dy,
        p(0.645, 0.070).dx,
        p(0.545, 0.070).dy,
      )
      ..quadraticBezierTo(
        p(0.59, 0.150).dx,
        p(0.59, 0.150).dy,
        p(0.605, 0.240).dx,
        p(0.605, 0.240).dy,
      )
      ..quadraticBezierTo(
        p(0.675, 0.330).dx,
        p(0.675, 0.330).dy,
        p(0.805, 0.355).dx,
        p(0.805, 0.355).dy,
      );
  }

  Path _buildTruckPathPhase2(Size screen) {
    final w = screen.width;
    const leftPad = 15.0;
    final trackW = w * 0.80;
    Offset p(double fx, double fy) =>
        Offset(leftPad + trackW * fx, 55 + trackW * fy);

    return Path()
      ..moveTo(p(0.730, 0.355).dx, p(0.730, 0.355).dy)
      ..quadraticBezierTo(
        p(0.805, 0.340).dx,
        p(0.805, 0.340).dy,
        p(0.860, 0.315).dx,
        p(0.860, 0.315).dy,
      )
      ..quadraticBezierTo(
        p(0.905, 0.285).dx,
        p(0.905, 0.285).dy,
        p(0.930, 0.255).dx,
        p(0.930, 0.255).dy,
      )
      ..quadraticBezierTo(
        p(0.912, 0.200).dx,
        p(0.912, 0.200).dy,
        p(0.912, 0.120).dx,
        p(0.912, 0.120).dy,
      )
      ..cubicTo(
        p(0.895, 0.080).dx,
        p(0.895, 0.080).dy,
        p(0.870, 0.050).dx,
        p(0.870, 0.050).dy,
        p(0.840, 0.020).dx,
        p(0.840, 0.020).dy,
      )
      ..lineTo(p(0.820, -0.50).dx, p(0.820, -0.50).dy);
  }

  double _flattenAngleAtEndPhase1(double angle, double t) {
    const start = 0.96;
    if (t <= start) return angle;
    final k = (t - start) / (1 - start);
    return lerpDouble(angle, 0.0, k)!;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final clusterH = h * 0.62;
    final truckW = w * 0.12;
    final truckH = truckW * 0.61;

    final bellSize = w * 0.16;
    final bellPopScale = lerpDouble(0.6, 1.0, _bellAppearCtrl.value)!;
    final bellSwingAngle = lerpDouble(-0.16, 0.16, _bellSwingCtrl.value)!;
    final bellLift = 22.0 * _bellUpCtrl.value;

    final logoW = w * 0.80;
    final logoOpacity = _logoCtrl.value.clamp(0.0, 1.0);
    final logoSlide = (1 - _logoCtrl.value) * 28;

    Path path;
    double tSample;
    if (_trackCtrl2.value > 0.0) {
      path = _buildTruckPathPhase2(Size(w, h));
      tSample = _t2.value;
    } else {
      path = _buildTruckPathPhase1(Size(w, h));
      tSample = _t1.value;
    }

    final metric = path.computeMetrics().first;
    final dist = metric.length * tSample;
    final tangent = metric.getTangentForOffset(dist)!;
    final pos = tangent.position;
    var angle = tangent.angle;
    if (_trackCtrl2.value == 0.0) {
      angle = _flattenAngleAtEndPhase1(angle, _t1.value);
    }

    // combine initial zoom and end zoom (endZoom starts at 1.0 so no effect until triggered)
    final combinedScale = _zoom.value * _endZoom.value;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Transform.scale(
                scale: combinedScale,
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: w,
                  height: clusterH,
                  child: Stack(
                    children: [
                      const Positioned(
                        left: 15,
                        bottom: -12,
                        child: _TrackImage(),
                      ),
                      Positioned(
                        left: w * 0.09,
                        bottom: clusterH * 0.13,
                        child: Image.asset(
                          'assets/images/tree.png',
                          width: w * 0.10,
                        ),
                      ),
                      Positioned(
                        left: w * 0.03,
                        bottom: clusterH * 0.16,
                        child: Image.asset(
                          'assets/images/bird.png',
                          width: w * 0.12,
                        ),
                      ),
                      Positioned(
                        left: pos.dx - truckW / 2,
                        bottom: pos.dy - truckH / 2 + _bounce + 10,
                        child: Transform.rotate(
                          angle: angle,
                          child: Image.asset(
                            'assets/images/truck.png',
                            width: truckW,
                            height: truckH,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_showCenterBell)
              Align(
                alignment: const Alignment(0, -0.06),
                child: Transform.translate(
                  offset: Offset(0, -bellLift),
                  child: Transform.rotate(
                    angle: bellSwingAngle,
                    child: Transform.scale(
                      scale: bellPopScale,
                      child: Image.asset(
                        'assets/images/bell.png',
                        width: bellSize,
                      ),
                    ),
                  ),
                ),
              ),
            if (_showCenterLogo)
              Align(
                alignment: const Alignment(0.4, 0.1),
                child: Opacity(
                  opacity: logoOpacity,
                  child: Transform.translate(
                    offset: Offset(0, logoSlide),
                    child: Image.asset('assets/images/logo.png', width: logoW),
                  ),
                ),
              ),
            if (_showSkip)
              Positioned(
                right: 15,
                bottom: 15,
                child: GestureDetector(
                  onTap: () {
                    // If user taps Skip — cancel animations / timers and go immediate
                    // Stop animations to avoid duplicated navigation
                    _endZoomCtrl.stop();
                    _zoomCtrl.stop();
                    _trackCtrl1.stop();
                    _trackCtrl2.stop();
                    _bellSwingCtrl.stop();
                    // navigate immediately to next screen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const TrackWithTruck()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C2FA0),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'SKIP',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrackImage extends StatelessWidget {
  const _TrackImage();
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Image.asset(
      'assets/images/track.png',
      width: w * 0.80,
      fit: BoxFit.contain,
    );
  }
}
