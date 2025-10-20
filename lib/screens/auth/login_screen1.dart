import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_screen2.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final scale = (w / 390).clamp(0.85, 1.25);
            double fs(double x) => x * scale;

            const purple = Color(0xFF6C2FA0);
            const green = Color(0xFF1CC019);
            const cardBg = Color(0xFFF1FBE2);


            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: fs(20), vertical: fs(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: fs(10)),
                          Image.asset('assets/images/logo.png', width: fs(100), fit: BoxFit.contain),
                          SizedBox(height: fs(16)),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(fs(22)),
                            ),
                            padding: EdgeInsets.fromLTRB(fs(18), fs(18), fs(18), fs(20)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: fs(18), vertical: fs(10)),
                                  child: Text(
                                    'DISCOVER CHURPPY',
                                    style: GoogleFonts.getFont(
                                      'Lemon',
                                      fontSize: fs(22),
                                      fontWeight: FontWeight.w400,
                                      height: 1.0,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                SizedBox(height: fs(14)),
                                Text(
                                  'A consumer-driven crowd\nsourcing platform offering Smart\nDelivery',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: "lemon",
                                    fontSize: fs(15),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                    height: 1.35,
                                  ),
                                ),
                                SizedBox(height: fs(18)),
                                Text(
                                  'Delivery includes:',
                                  style: TextStyle(
                                    fontFamily: "lemon",
                                    fontSize: fs(18),
                                    fontWeight: FontWeight.w900,
                                    color: purple,
                                  ),
                                ),
                                SizedBox(height: fs(6)),
                                Text(
                                  'joining people\nfood\nservices',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: "lemon",
                                    fontSize: fs(14.5),
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                    height: 1.35,
                                  ),
                                ),
                                SizedBox(height: fs(14)),
                                Text(
                                  'How?',
                                  style: TextStyle(
                                    fontFamily: "lemon",
                                    fontSize: fs(18),
                                    fontWeight: FontWeight.w900,
                                    color: purple,
                                  ),
                                ),
                                SizedBox(height: fs(6)),
                                Text(
                                  'alerts\nnotifications',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: "lemon",
                                    fontSize: fs(14.5),
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                    height: 1.35,
                                  ),
                                ),
                                SizedBox(height: fs(6)),
                                Text(
                                  'Churppy Chain - Bundle Orders',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: "lemon",
                                    fontSize: fs(18),
                                    fontWeight: FontWeight.w900,
                                    color: purple,
                                  ),
                                ),
                                SizedBox(height: fs(16)),
                                Text(
                                  'Why?',
                                  style: TextStyle(
                                    fontFamily: "lemon",
                                    fontSize: fs(18),
                                    fontWeight: FontWeight.w900,
                                    color: purple,
                                  ),
                                ),
                                SizedBox(height: fs(8)),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: fs(6)),
                                    child: Text(
                                      '> to tell people where you are\n'
                                          '> offer last minute real-time deals\n'
                                          '> bundles deliveries together\n'
                                          '> prevents restaurants from going\n'
                                          '  back and forth to the same\n'
                                          '  delivery address or area\n'
                                          '> saves gas and time\n'
                                          '> creates buzz\n'
                                          '> user credits for participating in\n'
                                          '  Churppy Chains\n'
                                          '> market anywhere\n'
                                          '> join a pick up game\n'
                                          '> just landed, find ',
                                      style: TextStyle(
                                        fontFamily: "lemon",
                                        fontSize: fs(14.5),
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: fs(10)),
                                SizedBox(
                                  width: fs(260),
                                  height: fs(44),
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: green,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fs(12))),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const LoginScreen2(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Active Churppy Alerts',
                                      style: TextStyle(
                                        fontFamily: "lemon",
                                        fontSize: fs(14.5),
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: fs(14)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
