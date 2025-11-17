import 'package:churppy_customer/screens/auth/login.dart';
import 'package:churppy_customer/screens/auth/signup_screen.dart';
import 'package:churppy_customer/screens/churppy_difference.dart';
import 'package:churppy_customer/screens/slider2.dart'; // 👈 make sure this file exists
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Slider1 extends StatelessWidget {
  const Slider1({super.key});

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final scale = (w / 390).clamp(0.85, 1.25);
            double fs(double x) => x * scale;

            const cardBg = Color(0xFFF1FBE2);
            const orange = Color(0xFFFF9633);

            return Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: fs(20), vertical: fs(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ✅ Logo
                        Image.asset(
                          'assets/images/logo.png',
                          width: fs(120),
                        ),
                        SizedBox(height: fs(8)),

                        // ✅ Main yellow card
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(fs(25)),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: fs(20), vertical: fs(25)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'DISCOVER CHURPPY',
                                style: GoogleFonts.lemon(
                                  fontSize: fs(22),
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              SizedBox(height: fs(10)),

                              Text(
                                'A consumer-driven crowd sourcing platform offering Smart Delivery',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: fs(14),
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                              SizedBox(height: fs(18)),

                              Text(
                                'Why you’ll love CHURPPY!',
                                style: GoogleFonts.lemon(
                                  fontSize: fs(17),
                                  fontWeight: FontWeight.w800,
                                  color: orange,
                                ),
                              ),
                              SizedBox(height: fs(15)),

                              Text(
                                'Find great food + services faster',
                                style: GoogleFonts.lemon(
                                  fontSize: fs(16),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: fs(10)),

                              // ✅ Bullet points
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildBullet(fs, 'Locate your favorite Foodtruck, mobile service or business'),
                                  SizedBox(height: fs(6)),
                                  _buildBullet(fs, 'Map Locator'),
                                  SizedBox(height: fs(6)),
                                  _buildBullet(fs, 'Instantly know When and Where they are'),
                                ],
                              ),
                              SizedBox(height: fs(18)),

                              // ✅ Info Card
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(fs(12)),
                                  border: Border.all(color: Colors.black26, width: 1.2),
                                  color: Colors.white,
                                ),
                                padding: EdgeInsets.all(fs(12)),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image.asset(
                                      'assets/images/tees_tasty_logo.png',
                                      width: fs(80),
                                      height: fs(80),
                                      fit: BoxFit.contain,
                                    ),
                                    SizedBox(width: fs(10)),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: GoogleFonts.poppins(
                                            fontSize: fs(11.5),
                                            color: Colors.black,
                                            height: 1.35,
                                          ),
                                          children: [
                                            const TextSpan(
                                              text:
                                                  "Tee’s Tasty Kitchen will be located at 33 Churppy Rd, Churppy, 33333 on October 9th from 11am to 6pm. Look Forward to Seeing You! ",
                                            ),
                                            TextSpan(
                                              text: "1hr 22mins left",
                                              style: TextStyle(
                                                color: Colors.redAccent,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: fs(30)),

                              // ✅ Three Orange Dashes
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  3,
                                  (i) => Padding(
                                    padding: EdgeInsets.symmetric(horizontal: fs(15)),
                                    child: Container(
                                      width: fs(60),
                                      height: fs(2.0),
                                      decoration: BoxDecoration(
                                        color: orange,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: fs(30)),

                              // ✅ Buttons Section inside card
                              _buildButton(
                                text: "Sign Up",
                                color: Colors.purple,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const SignupScreen()),
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
                                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildButton(
                                text: "Foodtrucks | Mobile | Vendors (Business App)",
                                color: Colors.grey,
                                onTap: () => debugPrint("Business App (Vendor) pressed"),
                              ),
                              const SizedBox(height: 12),
                              _buildButton(
                                text: "Explore More → The Churppy Difference",
                                color: Colors.lightBlue,
                                onTap: (){ Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ChurppyDifference()), // 👈 Go Next
                          );}
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenH * 0.09),
                      ],
                    ),
                  ),
                ),

                // ✅ Bottom Navigation Arrows
                Positioned(
                  bottom: 25,
                  left: 25,
                  right: 25,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _navArrow(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () {
                          Navigator.pop(context); // 👈 Go Back
                        },
                      ),
                      _navArrow(
                        icon: Icons.arrow_forward_ios_rounded,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const Slider2()), // 👈 Go Next
                          );
                        },
                      ),
                    ],
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

// ✅ Helper Widgets

Widget _buildBullet(double Function(double) fs, String text) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("• "),
      Expanded(
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: fs(14.5),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}

Widget _buildButton({
  required String text,
  required Color color,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 30),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: Colors.white.withOpacity(0.2),
      child: Container(
        height: 50,
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
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _navArrow({required IconData icon, required VoidCallback onTap}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(50),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black12,
      ),
      child: Icon(
        icon,
        color: Colors.black87,
        size: 22,
      ),
    ),
  );
}
