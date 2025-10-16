import 'package:churppy_customer/screens/profile.dart';
import 'package:churppy_customer/screens/support.dart';
import 'package:flutter/material.dart';
import '../widgets/churppy_navbar.dart';
import 'ChurppyAlertsScreen.dart';
import 'home_screen.dart';

class MapAlertsScreen extends StatelessWidget {
  const MapAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final scale = (w / 390).clamp(0.85, 1.25);
    double fs(double x) => x * scale;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: fs(16), vertical: fs(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔰 Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/images/logo.png', height: fs(30)),
                  CircleAvatar(
                    radius: fs(18),
                    backgroundImage: const AssetImage('assets/images/profile.png'),
                  ),
                ],
              ),
              SizedBox(height: fs(14)),

              /// 🔍 Search Bar
              Container(
                padding: EdgeInsets.symmetric(horizontal: fs(12), vertical: fs(8)),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(fs(12)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    SizedBox(width: fs(10)),
                    Expanded(
                      child: Text(
                        'Enter Zip, City, Airport, Bus Name',
                        style: TextStyle(fontSize: fs(14), color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.tune, color: Colors.purple),
                  ],
                ),
              ),
              SizedBox(height: fs(14)),

              /// 🗺 Title
              Text(
                'MAP - Active Churppy Alerts',
                style: TextStyle(
                  fontSize: fs(16),
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              SizedBox(height: fs(14)),

              /// 🗺 Map Image
              ClipRRect(
                borderRadius: BorderRadius.circular(fs(12)),
                child: Image.asset(
                  'assets/images/map_preview.png',
                  width: double.infinity,
                  height: fs(150),
                  fit: BoxFit.fill,
                ),
              ),
              SizedBox(height: fs(20)),

              /// 🏪 Business Info + Timer
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tee’s Tasty Kitchen',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: fs(16),
                            color: Colors.purple,
                          ),
                        ),
                        SizedBox(height: fs(8)),
                        Text(
                          'Current Location\n10 N. Churppy Bell\nSuburban, GA 30346\nHours 11a to 6p',
                          style: TextStyle(fontSize: fs(13)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Icon(Icons.timer, color: Colors.redAccent, size: fs(20)),
                      SizedBox(height: fs(4)),
                      Text(
                        '3 Hours Left',
                        style: TextStyle(fontSize: fs(13), color: Colors.redAccent),
                      ),
                    ],
                  )
                ],
              ),
              SizedBox(height: fs(16)),

              /// 🟩 View Menu + arrow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: w * 0.5,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6DC24B),
                        padding: EdgeInsets.symmetric(vertical: fs(12)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(fs(10)),
                        ),
                      ),
                      child: Text('View Menu/Order',
                          style: TextStyle(
                              fontSize: fs(13),
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_left, size: fs(22), color: Colors.black54),
                ],
              ),
              SizedBox(height: fs(12)),

              /// 🟨 Directions + arrow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: w * 0.42,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD95E),
                        padding: EdgeInsets.symmetric(vertical: fs(12)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(fs(10)),
                        ),
                      ),
                      child: Text('Directions',
                          style: TextStyle(
                              fontSize: fs(13),
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_right, size: fs(22), color: Colors.black54),
                ],
              ),
            ],
          ),
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
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (_) => const HomeScreen()),
              // );
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
/// ========================= INLINE NAVBAR WIDGET =========================
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
      notchMargin: 10.0, // ✅ a bit larger
      child: SizedBox(
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (index) {
            if (index == 2) {
              return const SizedBox(width: 60); // ✅ wider center gap
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
