import 'package:flutter/material.dart';

import 'menuScreen.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final scale = (w / 390).clamp(0.85, 1.25);
    double fs(double x) => x * scale;

    return Scaffold(
      backgroundColor: const Color(0xfff9f9f9),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: fs(16), vertical: fs(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// 🔰 Top Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            size: fs(22),
                            color: Colors.black,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),

                        SizedBox(width: fs(8)),
                        Image.asset("assets/images/logo.png", height: fs(34)),
                      ],
                    ),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: fs(18),
                          backgroundImage:
                          const AssetImage("assets/images/profile.png"),
                        ),
                        SizedBox(width: fs(10)),
                        Icon(Icons.search, size: fs(22), color: Colors.black),
                      ],
                    )
                  ],
                ),

                SizedBox(height: fs(40)),

                /// 🔔 Icon
                Image.asset("assets/images/bell_churppy.png", height: fs(100)),
                SizedBox(height: fs(20)),

                /// ✅ Success Card
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: fs(20), vertical: fs(32)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      /// ✅ Icon
                      Container(
                        padding: EdgeInsets.all(fs(16)),
                        decoration: const BoxDecoration(
                          color: Colors.purple,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check, color: Colors.white, size: fs(28)),
                      ),
                      SizedBox(height: fs(18)),

                      /// Success !
                      Text(
                        "Success !",
                        style: TextStyle(
                          fontSize: fs(18),
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: fs(8)),

                      Text(
                        "Your payment was successful.\nA receipt for this purchase is in\nyour Profile.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: fs(13),
                          color: Colors.grey.shade800,
                        ),
                      ),

                      SizedBox(height: fs(24)),

                      /// Go Back button
                      ElevatedButton(
                        onPressed: () {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(builder: (_) => const MenuScreen()),
                          // );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(
                              horizontal: fs(34), vertical: fs(12)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text("Go Back",
                            style: TextStyle(
                                fontSize: fs(14), color: Colors.white)),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: fs(30)),

                /// ⛓️ CHURPPY CHAIN BUTTON
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: fs(16), vertical: fs(16)),
                  decoration: BoxDecoration(
                    color: const Color(0xffff7c00),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "CLICK TO START A\nCHURPPY CHAIN",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: fs(14),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: fs(8)),
                      Text(
                        "[Business Must Approve]",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: fs(11),
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
