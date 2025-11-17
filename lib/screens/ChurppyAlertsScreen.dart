import 'dart:convert';
import 'package:churppy_customer/screens/profile.dart';
import 'package:churppy_customer/screens/support.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

import '../widgets/churppy_navbar.dart';
import 'home_screen.dart' hide ChurppyNavbar;
import 'map_active_alert.dart';

// ========================= MODELS =========================
class AlertModel {
  final int id;
  final int merchantId;
  final String title;
  final String description;
  final String image;
  final String startDate;
  final String expiryDate;
  final String businessLogo;
  final String businessTitle;
  final String? discount;
  final String? timeLeft;
  final double? distance;

  AlertModel({
    required this.id,
    required this.merchantId,
    required this.title,
    required this.description,
    required this.image,
    required this.startDate,
    required this.expiryDate,
    required this.businessLogo,
    required this.businessTitle,
    this.discount,
    this.timeLeft,
    this.distance,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] ?? 0,
      merchantId: json['merchant_id'] ?? 0,
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      startDate: (json['start_date'] ?? '').toString(),
      expiryDate: (json['expiry_date'] ?? '').toString(),
      businessLogo: (json['business_logo'] ?? '').toString(),
      businessTitle: (json['business_title'] ?? '').toString(),
      discount: json['discount']?.toString(),
      timeLeft: json['time_left']?.toString(),
      distance: json['distance'] != null 
          ? double.tryParse(json['distance'].toString())
          : null,
    );
  }
}

// ========================= SERVICES =========================
class AlertsService {
  static Future<List<AlertModel>> fetchAlerts({required double lat, required double lng}) async {
    try {
      final res = await http.get(
        Uri.parse(
          "https://churppy.eurekawebsolutions.com/api/alerts.php"
          "?lat=$lat&lng=$lng",
        ),
      );

      if (res.statusCode != 200) {
        throw Exception("Server error: ${res.statusCode}");
      }
      
      final body = json.decode(res.body);
      if (body['status'] != 'success') {
        throw Exception(body['message'] ?? "Unexpected API response");
      }
      
      final List data = body['alerts'] ?? [];
      final alerts = data.map((e) => AlertModel.fromJson(e)).toList();
      
      // Filter active alerts
      return alerts.where((alert) {
        return alert.timeLeft != "Expired" && alert.timeLeft != "N/A";
      }).toList();
      
    } catch (e) {
      throw Exception("Failed to fetch alerts: $e");
    }
  }
}

class ChurppyAlertsScreen extends StatefulWidget {
  const ChurppyAlertsScreen({super.key});

  @override
  State<ChurppyAlertsScreen> createState() => _ChurppyAlertsScreenState();
}

class _ChurppyAlertsScreenState extends State<ChurppyAlertsScreen> {
  String? _profileImageUrl;
  int? _userId;
  bool _loadingProfile = true;
  bool showArchive = false;
  
  // ✅ NEW: Alerts data
  late Future<List<AlertModel>> futureAlerts;
  bool _loadingAlerts = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _getLocationAndLoadAlerts();
  }

  Future<void> _getLocationAndLoadAlerts() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please enable Location Services to continue."),
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Location permission is required to load alerts."),
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Enable location permission from settings to continue."),
          ),
        );
        await Geolocator.openAppSettings();
        return;
      }

      // Get location and load alerts
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        futureAlerts = AlertsService.fetchAlerts(
          lat: position.latitude, 
          lng: position.longitude
        );
        _loadingAlerts = false;
      });

    } catch (e) {
      print("❌ Location error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to get location: $e")),
      );
      setState(() => _loadingAlerts = false);
    }
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

  /// ✅ Relative → Absolute URL normalizer for images
  String _absUrl(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    const base = 'https://churppy.eurekawebsolutions.com/';
    final cleaned = url.replaceFirst(RegExp(r'^/+'), '');
    return '$base$cleaned';
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
                  color: Color(0xFF804692),
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
                          'Latest',
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

            /// 🔔 Body - API Based Alerts
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
                  : _buildAlertsList(fs),
            ),
          ],
        ),
      ),

      // FAB → Alerts screen
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ChurppyAlertsScreen()),
          );
        },
        backgroundColor: const Color(0xFF804692),
        shape: const CircleBorder(),
        elevation: 6,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Image.asset(
            'assets/images/alert1.png',
            color: Colors.white,
            fit: BoxFit.contain,
          ),
        ),
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

  /// ✅ NEW: Build Alerts List from API
  Widget _buildAlertsList(double Function(double) fs) {
    if (_loadingAlerts) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<List<AlertModel>>(
      future: futureAlerts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(fs(16)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: fs(50), color: Colors.grey),
                  SizedBox(height: fs(16)),
                  Text(
                    "Failed to load alerts",
                    style: TextStyle(fontSize: fs(16), color: Colors.grey),
                  ),
                  SizedBox(height: fs(8)),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: fs(12), color: Colors.grey),
                  ),
                  SizedBox(height: fs(16)),
                  ElevatedButton(
                    onPressed: _getLocationAndLoadAlerts,
                    child: Text("Retry"),
                  ),
                ],
              ),
            ),
          );
        }

        final alerts = snapshot.data ?? [];
        if (alerts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off, size: fs(50), color: Colors.grey),
                SizedBox(height: fs(16)),
                Text(
                  "No active alerts available",
                  style: TextStyle(fontSize: fs(16), color: Colors.grey),
                ),
                SizedBox(height: fs(8)),
                Text(
                  "Check back later for new alerts",
                  style: TextStyle(fontSize: fs(12), color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: fs(14), vertical: fs(12)),
          itemCount: alerts.length,
          separatorBuilder: (context, index) => SizedBox(height: fs(16)),
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return _apiAlertCard(fs, alert);
          },
        );
      },
    );
  }

  /// ✅ NEW: API-based Alert Card
  Widget _apiAlertCard(double Function(double) fs, AlertModel alert) {
    final cover = alert.image.isNotEmpty ? alert.image : alert.businessLogo;
    final title = alert.title.isNotEmpty ? alert.title : alert.businessTitle;
    final desc = alert.description.isNotEmpty
        ? alert.description
        : "is serving in your area\nTime is ticking. Place order now!";
    final timeLabel = alert.timeLeft ?? "";
    
    // Determine if it's urgent (less time left)
    final isUrgent = timeLabel.toLowerCase().contains("min") && 
                    int.tryParse(timeLabel.replaceAll(RegExp(r'[^0-9]'), '')) != null &&
                    int.tryParse(timeLabel.replaceAll(RegExp(r'[^0-9]'), ''))! < 30;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(fs(12)),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Alert Image
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(fs(12)),
              topRight: Radius.circular(fs(12)),
            ),
            child: Image.network(
              _absUrl(cover),
              height: fs(160),
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: fs(160),
                color: Colors.grey[200],
                child: Icon(Icons.image_not_supported, size: fs(40), color: Colors.grey),
              ),
            ),
          ),
          
          // Alert Content
          Container(
            width: double.infinity,
            color: isUrgent ? Colors.orange[200] : const Color(0xFF8DC63F),
            padding: EdgeInsets.symmetric(vertical: fs(12), horizontal: fs(16)),
            child: Column(
              children: [
                Text(
                  "SOMEONE IN YOUR NEIGHBORHOOD\nJUST ORDERED FROM",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                    fontSize: fs(14),
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: fs(6)),
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
          
          // Button and Time Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: fs(16), vertical: fs(12)),
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
                    backgroundColor: const Color(0xFF804692),
                    padding: EdgeInsets.symmetric(horizontal: fs(20), vertical: fs(12)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(fs(8)),
                    ),
                  ),
                  child: Text(
                    "View Churppy Alert",
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
                        color: isUrgent ? Colors.red : Colors.purple),
                    SizedBox(width: fs(6)),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        color: isUrgent ? Colors.red : Colors.purple,
                        fontSize: fs(12),
                        fontWeight: FontWeight.w600,
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