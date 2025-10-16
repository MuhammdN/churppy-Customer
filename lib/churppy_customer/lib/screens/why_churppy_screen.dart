import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_drawing/path_drawing.dart';


import 'auth/login_screen2.dart';

class TrackWithTruck extends StatefulWidget {
  const TrackWithTruck({super.key});

  @override
  State<TrackWithTruck> createState() => _TrackWithTruckState();
}

class _TrackWithTruckState extends State<TrackWithTruck>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Path _path;
  late PathMetric _metric;

  double _lastAngle = 0.0; // track previous angle for smoothness

  final String svgPathData =
      "M122.9.014l2.451,179.365a28.872,28.872,0,0,0,18.673,26.885,20.316,20.316,0,0,0,14.7.171c3.1,1.273,41.278-5.435,66.731,17.671l.09.133a71.954,71.954,0,0,1,5.934,11.341c10.779,27.071,22.445,74.106-34.024,114.515a44.668,44.668,0,0,1-27.86,1.07c-14.155-4.043-34.936-11.261-42.2-20.386a39.48,39.48,0,0,0-15.965-11.693C93.5,311.7,70.245,311,36.131,338.046a28.916,28.916,0,0,0-8.007,9.843c-5.193,10.533-13.167,34.023-4.76,68.626,7.128,29.341,34.326,49.775,64.428,47.408q.954-.075,1.922-.18a46.959,46.959,0,0,0,27.494-13.014c11.687-11.278,36.261-28.09,64.861-31.779a45.34,45.34,0,0,1,44.666,22.023,146.871,146.871,0,0,1,20.072,69.806,34.114,34.114,0,0,1-7.1,22.152c-9.393,12.117-26.366,29.022-22.007,27.208-21.272,8.851-54.174,14-102.39-22.7a44.258,44.258,0,0,0-15.244-7.483C81.526,524.934,60.71,522.649,29,572c0,0-14.515,22.028,11.264,76.705a52.9,52.9,0,0,0,52.507,30.273l.76-.071a86.691,86.691,0,0,0,18.181-3.994c7.532-2.42,22.958-2.179,25.841,38.476l1.423,169.486";

  @override
  void initState() {
    super.initState();

    _path = parseSvgPathData(svgPathData);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..forward();

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _goToNextScreen();
        }
      });
  }

  void _goToNextScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen2()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Path _getTransformedPath(Size size) {
    final matrix4 = Matrix4.identity()
      ..translate(size.width * 0.5, size.height * 0.0)
      ..scale(size.width / 550, size.height / 890);
    return _path.transform(matrix4.storage);
  }

  /// define discrete target angles
  double _getTargetAngle(double progress) {
    if (progress < 0.13) return math.pi / 2; // 90
    else if (progress < 0.19) return 0;      // 0
    else if (progress < 0.27) return math.pi / 2; // 90
    else if (progress < 0.36) return math.pi;     // 180
    else if (progress < 0.45) return math.pi / 2; // 90
    else if (progress < 0.55) return 0;
    else if (progress < 0.65) return math.pi / 2;
    else if (progress < 0.72) return math.pi;
    else if (progress < 0.81) return math.pi / 2;
    else if (progress < 0.86) return 0;
    else return math.pi / 2;
  }

  /// smoothly interpolate between last angle and target angle
  double _getSmoothAngle(double target) {
    const smoothing = 0.08; // smaller = slower turning
    double diff = target - _lastAngle;

    // normalize to shortest path
    if (diff > math.pi) diff -= 2 * math.pi;
    if (diff < -math.pi) diff += 2 * math.pi;

    _lastAngle += diff * smoothing;
    return _lastAngle;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTapDown: (_) {
          if (_controller.isAnimating) {
            _controller.stop(); // 👉 tap down → pause
          }
        },
        onTapUp: (_) {
          if (!_controller.isAnimating) {
            _controller.forward(); // 👉 tap up → resume
          }
        },
        onTapCancel: () {
          if (!_controller.isAnimating) {
            _controller.forward(); // 👉 agar tap cancel hua toh bhi resume
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final transformed = _getTransformedPath(constraints.biggest);
            _metric = transformed.computeMetrics().first;

            return AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final progress = _animation.value;
                final distance = _metric.length * progress;
                final tangent = _metric.getTangentForOffset(distance)!;

                final targetAngle = _getTargetAngle(progress);
                final smoothAngle = _getSmoothAngle(targetAngle);

                return Stack(
                  children: [
                    /// background images
                    SizedBox.expand(
                      child: Image.asset(
                        "assets/images/2ndPage.png",
                        fit: BoxFit.fill,
                      ),
                    ),
                    SizedBox.expand(
                      child: Image.asset(
                        "assets/images/track2.png",
                        fit: BoxFit.fill,
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 5,
                      child: ElevatedButton(
                        onPressed: _goToNextScreen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "SKIP",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),

                    /// truck image (with smooth rotation)
                    Positioned(
                      left: tangent.position.dx - 20,
                      top: tangent.position.dy - 20,
                      child: Transform.rotate(
                        angle: smoothAngle,
                        child: Image.asset("assets/images/truck.png", width: 40),
                      ),
                    ),

                    /// responsive locate.png
                    Positioned(
                      top: constraints.biggest.height * 0.40,
                      left: constraints.biggest.width * 0.57,
                      child: Image.asset(
                        "assets/images/customers.png",
                        width: constraints.biggest.width * 0.175,
                      ),
                    ),
                    Positioned(
                      top: constraints.biggest.height * 0.51,
                      left: constraints.biggest.width * 0.72,
                      child: Image.asset(
                        "assets/images/alert.png",
                        width: constraints.biggest.width * 0.180,
                      ),
                    ),
                    Positioned(
                      top: constraints.biggest.height * 0.27,
                      left: constraints.biggest.width * 0.70,
                      child: Image.asset(
                        "assets/images/locate.png",
                        width: constraints.biggest.width * 0.180,
                      ),
                    ),
                    Positioned(
                      top: constraints.biggest.height * 0.65,
                      left: constraints.biggest.width * 0.60,
                      child: const AnimatedClockWidget(size: 70),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class AnimatedClockWidget extends StatefulWidget {
  final double size;
  const AnimatedClockWidget({super.key, this.size = 100});
  @override
  State<AnimatedClockWidget> createState() => _AnimatedClockWidgetState();
}

class _AnimatedClockWidgetState extends State<AnimatedClockWidget>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _elapsed = Duration.zero;
  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      setState(() => _elapsed = elapsed);
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(widget.size),
      painter: _ClockPainter(_elapsed),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final Duration elapsed;
  _ClockPainter(this.elapsed);
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final paint = Paint()..isAntiAlias = true;
    paint.color = const Color(0xFF5E8BD1);
    canvas.drawCircle(center, radius, paint);
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.78, paint);
    paint.color = const Color(0xFFFFA7A7);
    canvas.drawCircle(center, 6, paint);
    paint.strokeWidth = 3;
    for (int i = 0; i < 4; i++) {
      final angle = math.pi / 2 * i;
      final start =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius * 0.65);
      final end =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius * 0.78);
      canvas.drawLine(start, end, paint);
    }
    final seconds = elapsed.inMilliseconds / 1000.0;
    final speed = 50.0;
    final hourAngle = (seconds * speed / 60) * math.pi / 6;
    final minAngle = (seconds * speed) * math.pi / 30;
    final secAngle = (seconds * speed * 6) * math.pi / 180;
    _drawHand(
      canvas,
      center,
      hourAngle,
      radius * 0.35,
      6,
      const Color(0xFF716DC2),
    );
    _drawHand(
      canvas,
      center,
      minAngle,
      radius * 0.50,
      5,
      const Color(0xFF716DC2),
    );
    _drawHand(canvas, center, secAngle, radius * 0.65, 2, Colors.black);
  }

  void _drawHand(Canvas canvas, Offset center, double angle, double length,
      double width, Color color) {
    final handPaint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    final end = center + Offset(math.cos(angle), math.sin(angle)) * length;
    canvas.drawLine(center, end, handPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
