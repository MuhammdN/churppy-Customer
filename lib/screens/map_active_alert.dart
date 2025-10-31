import 'dart:convert';
import 'package:churppy_customer/screens/home_screen.dart';
import 'package:churppy_customer/screens/menuScreen.dart' hide ChurppyNavbar;
import 'package:churppy_customer/screens/profile.dart';
import 'package:churppy_customer/screens/support.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/churppy_navbar.dart' hide ChurppyNavbar;
import 'ChurppyAlertsScreen.dart';

class MapAlertsScreen extends StatefulWidget {
  const MapAlertsScreen({super.key});

  @override
  State<MapAlertsScreen> createState() => _MapAlertsScreenState();
}

class _MapAlertsScreenState extends State<MapAlertsScreen> {
  LatLng? _currentLatLng;
  String _currentAddress = "Getting location...";
  bool _loading = true;
  List<Map<String, dynamic>> _alerts = [];
  List<Map<String, dynamic>> _filteredAlerts = [];
  String _searchQuery = "";

  String? _profileImageUrl;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _getCurrentLocation();
  }

  Future<void> _loadUserProfile() async {
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
            setState(() => _profileImageUrl = data['data']['image']);
          }
        }
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      setState(() {
        _loading = false;
        _currentAddress = "Location permission denied";
      });
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    debugPrint(
        "📍 User Location: Latitude = ${pos.latitude}, Longitude = ${pos.longitude}");

    setState(() {
      _currentLatLng = LatLng(pos.latitude, pos.longitude);
    });

    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _currentAddress =
              "${p.name ?? ''} ${p.street ?? ''}, ${p.locality ?? ''}, ${p.administrativeArea ?? ''}";
        });
      } else {
        setState(() {
          _currentAddress = "${pos.latitude}, ${pos.longitude}";
        });
      }
    } catch (e) {
      debugPrint("❌ Reverse geocoding failed: $e");
      setState(() {
        _currentAddress = "${pos.latitude}, ${pos.longitude}";
      });
    }

    _fetchNearbyAlerts(pos.latitude, pos.longitude);
  }

  Future<void> _fetchNearbyAlerts(double lat, double lng) async {
    final url = Uri.parse(
        "https://churppy.eurekawebsolutions.com/api/nearby_merchants.php?lat=$lat&lng=$lng");

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success' && data['alerts'] is List) {
          final alerts = List<Map<String, dynamic>>.from(data['alerts']);
          for (var alert in alerts) {
            if (alert['discount'] != null &&
                alert['discount'].toString().isNotEmpty &&
                alert['discount'].toString() != "0") {
              debugPrint(
                  "🔥 DISCOUNT ALERT FOUND → ${alert['discount']}% for ${alert['title']}");
            }
          }
          setState(() {
            _alerts = alerts;
            _filteredAlerts = alerts;
            _loading = false;
          });
        } else {
          setState(() => _loading = false);
        }
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint("❌ Error fetching alerts: $e");
      setState(() => _loading = false);
    }
  }

  void _filterAlerts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredAlerts = _alerts;
      } else {
        _filteredAlerts = _alerts.where((a) {
          final t = (a['title'] ?? a['type'] ?? '').toString().toLowerCase();
          return t.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _openDirections(double destLat, double destLng) async {
    if (_currentLatLng == null) return;
    final origin = "${_currentLatLng!.latitude},${_currentLatLng!.longitude}";
    final destination = "$destLat,$destLng";

    final googleMapsUrl =
        "https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=driving";
    final appleMapsUrl =
        "http://maps.apple.com/?saddr=$origin&daddr=$destination";

    final g = Uri.parse(googleMapsUrl);
    final a = Uri.parse(appleMapsUrl);

    if (await canLaunchUrl(g)) {
      await launchUrl(g, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(a)) {
      await launchUrl(a, mode: LaunchMode.externalApplication);
    }
  }

  LatLng? _parseLatLng(String? csv) {
    if (csv == null) return null;
    final parts = csv.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  List<Widget> _buildAddressLines(Map<String, dynamic> a, double fs) {
    final line2 = (a['zone']?.toString().isNotEmpty ?? false)
        ? a['zone'].toString()
        : (a['area']?.toString() ?? '');
    final city = (a['city'] ?? '').toString();
    final state = (a['state'] ?? '').toString();
    final zip = (a['zip_code'] ?? '').toString();

    final line3 = [
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) (city.isNotEmpty ? ', ' : '') + state,
      if (zip.isNotEmpty)
        (state.isNotEmpty ? ' ' : (city.isNotEmpty ? ' ' : '')) + zip
    ].join('');

    return [
      Text(
        _currentAddress,
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: fs),
      ),
      SizedBox(height: fs * 0.3),
      if (line2.isNotEmpty)
        Text(line2, style: TextStyle(fontSize: fs * 0.9)),
      if (line3.trim().isNotEmpty) SizedBox(height: fs * 0.2),
      if (line3.trim().isNotEmpty)
        Text(line3.trim(), style: TextStyle(fontSize: fs * 0.9)),
    ];
  }

  Widget _mapPreview(LatLng? alertPos, double fs, bool hasDiscount, String discount) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(fs),
          child: SizedBox(
            height: fs * 15,
            width: double.infinity,
            child: (alertPos == null)
                ? const Center(child: Text("No location"))
                : FlutterMap(
                    options: MapOptions(
                      initialCenter: alertPos,
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.churppy.customer',
                      ),
                      if (_currentLatLng != null)
                        MarkerLayer(markers: [
                          Marker(
                            point: _currentLatLng!,
                            width: 50,
                            height: 50,
                            child: const Icon(Icons.location_on,
                                size: 40, color: Colors.red),
                          )
                        ]),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: alertPos,
                            width: 40,
                            height: 40,
                            child: Transform.rotate(
                              angle: 270 * 3.141592653589793 / 140,
                              child: Image.asset(
                                "assets/images/bell_churppy.png",
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
          ),
        ),

        // ✅ Discount badge if present
        if (hasDiscount)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: Text(
                "$discount% OFF",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final scale = (w / 390).clamp(0.85, 1.25);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 16 * scale, vertical: 12 * scale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset('assets/images/logo.png',
                              height: 30 * scale),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ProfileScreen()),
                              );
                            },
                            child: CircleAvatar(
                              radius: 18 * scale,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: _profileImageUrl != null &&
                                      _profileImageUrl!.startsWith("http")
                                  ? NetworkImage(_profileImageUrl!)
                                  : null,
                              child: (_profileImageUrl == null ||
                                      !_profileImageUrl!.startsWith("http"))
                                  ? Icon(Icons.person,
                                      size: 18 * scale,
                                      color: Colors.grey[800])
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14 * scale),

                      // Search bar
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12 * scale, vertical: 8 * scale),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                          borderRadius: BorderRadius.circular(12 * scale),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.grey),
                            SizedBox(width: 10 * scale),
                            Expanded(
                              child: TextField(
                                onChanged: _filterAlerts,
                                decoration: InputDecoration(
                                  hintText:
                                      'Search for food, restaurants Alerts',
                                  border: InputBorder.none,
                                  isDense: true,
                                  hintStyle: TextStyle(
                                      fontSize: 14 * scale,
                                      color: Colors.grey),
                                ),
                                style: TextStyle(fontSize: 14 * scale),
                              ),
                            ),
                            const Icon(Icons.tune, color: Colors.purple),
                          ],
                        ),
                      ),
                      SizedBox(height: 14 * scale),

                      Text(
                        'MAP - Active Churppy Alerts',
                        style: TextStyle(
                          fontSize: 22 * scale,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF6C2FA0),
                        ),
                      ),
                      SizedBox(height: 14 * scale),

                      if (_filteredAlerts.isEmpty)
                        const Text("No nearby alerts found",
                            style: TextStyle(color: Colors.black54))
                      else
                        Column(
                          children: _filteredAlerts.map((a) {
                            final p = _parseLatLng(a['location']?.toString());
                            final title =
                                (a['title'] ?? 'Churppy Alert').toString();
                            final discount =
                                a['discount']?.toString() ?? '';
                            final hasDiscount = discount.isNotEmpty &&
                                discount != '0' &&
                                discount != '0.0';

                            return Card(
                              elevation: 3,
                              margin: EdgeInsets.only(bottom: 18 * scale),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14 * scale)),
                              child: Padding(
                                padding: EdgeInsets.all(14 * scale),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _mapPreview(p, 12 * scale, hasDiscount, discount),
                                    SizedBox(height: 14 * scale),

                                    // Title + Time left
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 18 * scale,
                                              color: const Color(0xFF6C2FA0),
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Icon(Icons.access_time,
                                                color: Colors.redAccent,
                                                size: 20 * scale),
                                            SizedBox(width: 6 * scale),
                                            Text(
                                              a['time_left']?.toString() ??
                                                  'N/A',
                                              style: TextStyle(
                                                fontSize: 15 * scale,
                                                color: Colors.redAccent,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10 * scale),
                                    ..._buildAddressLines(a, 14 * scale),
                                    SizedBox(height: 14 * scale),

                                    // View Menu / Order
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => MenuScreen(
                                                    merchantId:
                                                        a['merchant_id'],
                                                    categoryId:
                                                        a['category_id'],
                                                    title: a['title'] ?? '',
                                                    image: a['image'] ?? '',
                                                    description:
                                                        a['description'] ?? '',
                                                  ),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF1CC019),
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 14 * scale),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        24 * scale),
                                              ),
                                            ),
                                            child: Text(
                                              'View Menu/Order',
                                              style: TextStyle(
                                                fontSize: 18 * scale,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12 * scale),
                                        Icon(Icons.arrow_back,
                                            color: Colors.black87,
                                            size: 22 * scale),
                                      ],
                                    ),
                                    SizedBox(height: 12 * scale),

                                    // Directions
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: (p == null)
                                                ? null
                                                : () => _openDirections(
                                                    p.latitude, p.longitude),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFFFFD95E),
                                              disabledBackgroundColor:
                                                  Colors.grey.shade300,
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 12 * scale),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        24 * scale),
                                              ),
                                            ),
                                            child: Text(
                                              'Directions',
                                              style: TextStyle(
                                                fontSize: 18 * scale,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12 * scale),
                                        Icon(Icons.arrow_forward,
                                            color: Colors.black87,
                                            size: 22 * scale),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ChurppyAlertsScreen()),
          );
        },
        backgroundColor: const Color(0xFF6C2FA0),
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
}
