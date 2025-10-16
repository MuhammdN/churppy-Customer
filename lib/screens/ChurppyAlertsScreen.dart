import 'dart:convert';
import 'package:churppy_customer/screens/profile.dart';
import 'package:churppy_customer/screens/support.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../widgets/churppy_navbar.dart';
import 'home_screen.dart' hide ChurppyNavbar;
import 'map_active_alert.dart';

class ChurppyAlertsScreen extends StatefulWidget {
  const ChurppyAlertsScreen({super.key});

  @override
  State<ChurppyAlertsScreen> createState() => _ChurppyAlertsScreenState();
}

class _ChurppyAlertsScreenState extends State<ChurppyAlertsScreen> {
  String? _profileImageUrl;
  int? _userId;
  bool _loadingProfile = true;
  bool showArchive = false; // ✅ NEW STATE

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString("user");
      if (userString != null) {
        final userMap = jsonDecode(userString);
        _userId = userMap['id'];
        if (_userId != null) {
          final url =
              "https://churppy.eurekawebsolutions.com/api/user.php?id=$_userId";
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['status'] == 'success') {
              setState(() {
                _profileImageUrl = data['data']['image'];
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint("⚠️ Profile load failed: $e");
    } finally {
      setState(() => _loadingProfile = false);
    }
  }

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
            /// 🔰 Header
            Column(
              children: [
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: fs(16), vertical: fs(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: fs(30),
                        fit: BoxFit.contain,
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ProfileScreen()),
                          );
                        },
                        child: CircleAvatar(
                          radius: fs(20),
                          backgroundColor: Colors.grey[300],
                          backgroundImage: _profileImageUrl != null &&
                                  _profileImageUrl!.startsWith("http")
                              ? NetworkImage(_profileImageUrl!)
                              : null,
                          child: (_profileImageUrl == null ||
                                  !_profileImageUrl!.startsWith("http"))
                              ? Icon(Icons.person,
                                  size: fs(20), color: Colors.grey[800])
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),

                /// 🟢 Green Title Bar
                Container(
                  color: const Color(0xFF8BC34A),
                  padding:
                      EdgeInsets.symmetric(horizontal: fs(16), vertical: fs(12)),
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

            /// 🔁 Tabs (Recent / Archive)
            Container(
              color: const Color(0xFFE9E9E9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => showArchive = false),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: fs(10)),
                        decoration: BoxDecoration(
                          color: !showArchive ? Colors.white : Colors.transparent,
                          border: Border(
                            bottom: BorderSide(
                              color: !showArchive
                                  ? Colors.purple
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Recent',
                          style: TextStyle(
                            fontSize: fs(14),
                            fontWeight: FontWeight.bold,
                            color: !showArchive ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => showArchive = true),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: fs(10)),
                        decoration: BoxDecoration(
                          color: showArchive ? Colors.white : Colors.transparent,
                          border: Border(
                            bottom: BorderSide(
                              color: showArchive
                                  ? Colors.purple
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Archive',
                          style: TextStyle(
                            fontSize: fs(14),
                            fontWeight: FontWeight.bold,
                            color: showArchive ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// 🔔 Body
            Expanded(
              child: showArchive
                  ? Center(
                      child: Text(
                        "📂 There is nothing in the Archive right now.",
                        style: TextStyle(
                          fontSize: fs(15),
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.symmetric(
                          horizontal: fs(14), vertical: fs(12)),
                      children: [
                        _alertCard(
                          context,
                          fs,
                          image: 'assets/images/bbq.png',
                          label:
                              'SOMEONE IN YOUR NEIGHBORHOOD\nJUST ORDERED FROM',
                          title: "Tee’s Tasty Kitchen",
                          buttonText: "Place Your Own Order",
                          trailingText: "25 Min",
                        ),
                        SizedBox(height: fs(16)),
                        _alertCard(
                          context,
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

      /// ➕ FAB
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

      /// 🔻 Bottom Navbar
      bottomNavigationBar: ChurppyNavbar(
        selectedIndex: 0,
        onTap: (int index) {
          switch (index) {
            case 0:
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()));
              break;
            case 1:
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()));
              break;
            case 2:
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChurppyAlertsScreen()));
              break;
            case 3:
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ContactSupportScreen()));
              break;
            case 4:
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MapAlertsScreen()));
              break;
          }
        },
      ),
    );
  }

  /// 🔔 Alert Card Widget
  Widget _alertCard(
    BuildContext context,
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
          if (!isCustomPromo)
            Image.asset(image, height: fs(160), fit: BoxFit.cover)
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.purple, width: 5),
              ),
              child: Image.asset(image,
                  height: fs(160), fit: BoxFit.cover, width: double.infinity),
            ),
          SizedBox(height: fs(10)),
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
            )
          else
            Container(
              width: double.infinity,
              color: isRed ? Colors.orange[200] : Colors.orange,
              padding:
                  EdgeInsets.symmetric(vertical: fs(10), horizontal: fs(12)),
              child: Column(
                children: [
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      fontSize: fs(14),
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
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: fs(10), vertical: fs(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MapAlertsScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6DC24B),
                    padding:
                        EdgeInsets.symmetric(horizontal: fs(16), vertical: fs(10)),
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
}
