import 'package:churppy_customer/screens/profile.dart';
import 'package:churppy_customer/screens/support.dart';
import 'package:flutter/material.dart';
import '../widgets/churppy_navbar.dart';
import 'home_screen.dart';
import 'map_active_alert.dart'; // ✅ Make sure path is correct

class ChurppyAlertsScreen extends StatelessWidget {
  const ChurppyAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final scale = (w / 390).clamp(0.85, 1.25);
    double fs(double x) => x * scale;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            /// 🔰 Top Header
            Column(
              children: [
                /// Top White Bar with Logo and Profile
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: fs(16), vertical: fs(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: fs(30),
                        fit: BoxFit.contain,
                      ),
                      CircleAvatar(
                        radius: fs(18),
                        backgroundImage: const AssetImage('assets/images/profile.png'),
                      ),
                    ],
                  ),
                ),

                /// Green Title Bar with Close and Title
                Container(
                  color: const Color(0xFF8BC34A),
                  padding: EdgeInsets.symmetric(horizontal: fs(16), vertical: fs(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.close, color: Colors.white, size: fs(20)),
                      ),
                      Text(
                        'Churppy Alerts',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: fs(16),
                        ),
                      ),
                      SizedBox(width: fs(36)),
                    ],
                  ),
                ),
              ],
            ),

            /// 🔁 Tabs
            Container(
              color: const Color(0xFFE9E9E9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: fs(10)),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: Colors.purple, width: 2),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text('Recent',
                          style: TextStyle(
                              fontSize: fs(14), fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: fs(10)),
                      alignment: Alignment.center,
                      child: Text('Archive',
                          style: TextStyle(fontSize: fs(14), color: Colors.grey)),
                    ),
                  ),
                ],
              ),
            ),

            /// 🔔 Alert List
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: fs(14), vertical: fs(12)),
                children: [
                  _alertCard(
                    context, // ✅ context pass kiya
                    fs,
                    image: 'assets/images/bbq.png',
                    label: 'SOMEONE IN YOUR NEIGHBORHOOD\nJUST ORDERED FROM',
                    title: "Tee’s Tasty Kitchen",
                    buttonText: "Place Your Own Order",
                    trailingText: "25 Min",
                  ),
                  SizedBox(height: fs(16)),
                  _alertCard(
                    context, // ✅ context pass kiya
                    fs,
                    image: 'assets/images/last_call.png',
                    label: '',
                    title:
                    "25% OFF and MORE\nBuy One Get Two\nOR JOIN A PICK UP GAME",
                    buttonText: "Place Your Own Order",
                    trailingText: "18 mins left",
                    isRed: true,
                    isCustomPromo: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      /// FAB → Alerts
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ChurppyAlertsScreen()),
          );
        },
        backgroundColor: const Color(0xFF6C2FA0),
        shape: const CircleBorder(),
        elevation: 6,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      /// Bottom Navbar (INLINE)
      bottomNavigationBar: ChurppyNavbar(
        selectedIndex: 0, // Home selected
        onTap: (int index) {
          switch (index) {
            case 0: // Home
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
              break;
            case 1: // Profile
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              break;
            case 2: // center gap (optional: also open Alerts)
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChurppyAlertsScreen()),
              );
              break;
            case 3: // Orders (placeholder)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ContactSupportScreen(),
                ),
              );
              break;
            case 4: // Favorites (placeholder)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MapAlertsScreen(),
                ),
              );
              break;
          }
        },
      ),
    );
  }

  }

  /// 🔔 Alert Card Widget
  Widget _alertCard(
      BuildContext context, // ✅ context added
      double Function(double) fs, {
        required String image,
        required String label,
        required String title,
        required String buttonText,
        required String trailingText,
        bool isRed = false,
        bool isCustomPromo = false,
      }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(fs(12)),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          /// 🔳 Image with optional purple border
          Container(
            decoration: isCustomPromo
                ? BoxDecoration(
              border: Border.all(color: Colors.purple, width: 5),
            )
                : null,
            child: Image.asset(
              image,
              height: fs(160),
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),

          SizedBox(height: fs(10)),

          /// 🟣 Purple Text Promo (only if custom)
          if (isCustomPromo)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: fs(12)),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fs(14),
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  color: Colors.purple,
                ),
              ),
            ),

          /// 🟧 Standard orange banner (default alerts)
          if (!isCustomPromo)
            Container(
              width: double.infinity,
              color: isRed ? Colors.orange[200] : Colors.orange,
              padding: EdgeInsets.symmetric(vertical: fs(10), horizontal: fs(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      fontSize: fs(14),
                      height: 1.35,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: fs(4)),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      fontSize: fs(16),
                      height: 1.35,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

          /// 🔘 Button and Timer
          Padding(
            padding: EdgeInsets.symmetric(horizontal: fs(10), vertical: fs(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context, // ✅ context available now
                      MaterialPageRoute(builder: (_) => const MapAlertsScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6DC24B),
                    padding: EdgeInsets.symmetric(
                        horizontal: fs(16), vertical: fs(10)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(fs(6)),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: TextStyle(
                      fontSize: fs(12),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                /// 🕒 Clock + Text
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: fs(14),
                        color: isRed ? Colors.red : Colors.purple),
                    SizedBox(width: fs(4)),
                    Text(
                      trailingText,
                      style: TextStyle(
                        color: isRed ? Colors.red : Colors.purple,
                        fontSize: fs(12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

// ========================= INLINE NAVBAR WIDGET (same file) =========================
class ChurppyNavbar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;

  const ChurppyNavbar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.home_outlined,
      Icons.person_outline,
      Icons.receipt_long_outlined,
      Icons.favorite_border,
    ];

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      color: const Color(0xFF6C2FA0),
      notchMargin: 8.0,
      child: SizedBox(
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (index) {
            if (index == 2) {
              return const SizedBox(width: 40); // Center FAB space
            }

            final iconIndex = index > 2 ? index - 1 : index;
            final isSelected = selectedIndex == index;

            return IconButton(
              onPressed: () => onTap(index),
              icon: Icon(
                icons[iconIndex],
                color: Colors.white,
                size: isSelected ? 28 : 24,
              ),
              tooltip: _tooltipFor(index),
            );
          }),
        ),
      ),
    );
  }

  String _tooltipFor(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Profile';
      case 3:
        return 'Orders';
      case 4:
        return 'Favorites';
      default:
        return '';
    }
  }
}
