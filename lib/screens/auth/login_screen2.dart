import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../ChurppyAlertsScreen.dart';
import 'login.dart';

class LoginScreen2 extends StatelessWidget {
  const LoginScreen2({super.key});

  static const purple = Color(0xFF6C2FA0);
  static const green = Color(0xFF1CC019);

  static const headerBg = 'assets/images/alerts_header_bg.png';
  static const vendorLogo = 'assets/images/tees_tasty_logo.png';

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

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: fs(20), vertical: fs(16)),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(fs(24)),
                        ),
                        padding: EdgeInsets.fromLTRB(fs(16), fs(18), fs(16), fs(20)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'PRESENTING',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: "Roboto",
                                fontSize: fs(40),
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: fs(12)),

                            /// 🔹 Clickable Header Image
                            InkWell(
                              onTap: () {
                                // Navigator.push(context, MaterialPageRoute(builder: (_) => const ChurppyAlertsScreen()));
                              },
                              borderRadius: BorderRadius.circular(fs(18)),
                              child: Container(
                                height: fs(200),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(fs(18)),
                                  image: const DecorationImage(
                                    image: AssetImage(headerBg),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: fs(16)),
                            Stack(
                              children: [
                                Container(
                                  height: fs(6),
                                  margin: EdgeInsets.only(top: fs(150)),
                                  decoration: BoxDecoration(
                                    color: purple.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(fs(12)),
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(fs(16)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 6),
                                      ),
                                      BoxShadow(
                                        color: Colors.purple.withOpacity(0.35),
                                        blurRadius: 18,
                                        offset: const Offset(6, 8),
                                      ),
                                    ],
                                  ),
                                  padding: EdgeInsets.fromLTRB(fs(18), fs(16), fs(18), fs(18)),
                                  child: Column(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8F8F8),
                                          borderRadius: BorderRadius.circular(fs(12)),
                                        ),
                                        padding: EdgeInsets.all(fs(10)),
                                        child: Image.asset(
                                          vendorLogo,
                                          width: fs(120),
                                          height: fs(80),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      SizedBox(height: fs(14)),
                                      Text(
                                        "Someone in your area\njust ordered from Tee’s\nTasty Kitchen\nCurrently located at...",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: fs(16),
                                          fontWeight: FontWeight.w800,
                                          height: 1.25,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: fs(10)),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'Show More',
                                style: TextStyle(
                                  fontSize: fs(14),
                                  fontWeight: FontWeight.w700,
                                  color: purple,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            SizedBox(height: fs(6)),
                            SizedBox(
                              width: double.infinity,
                              height: fs(46),
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: green,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(fs(12))),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Place Your Own Order',
                                  style: TextStyle(
                                    fontSize: fs(15),
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: fs(14)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.circle_outlined, size: fs(16), color: purple),
                                SizedBox(width: fs(8)),
                                Text(
                                  '25 Min',
                                  style: TextStyle(
                                    fontSize: fs(14),
                                    fontWeight: FontWeight.w700,
                                    color: purple,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
