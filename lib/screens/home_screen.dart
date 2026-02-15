import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Screens
import 'package:churppy_customer/screens/support.dart';
import 'package:churppy_customer/screens/profile.dart';
import 'package:churppy_customer/screens/menuScreen.dart';
import 'ChurppyAlertsScreen.dart';
import 'map_active_alert.dart';

/// ========================= MODELS =========================

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

class BusinessModel {
  final int id;
  final int merchantId;
  final String title;
  final String image;
  final String description;
  final double? distance;

  BusinessModel({
    required this.id,
    required this.merchantId,
    required this.title,
    required this.image,
    required this.description,
    this.distance,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    final img = (json['business_logo'] ?? json['image'] ?? '').toString();
    return BusinessModel(
      id: json['id'] ?? 0,
      merchantId: json['merchant_id'] ?? 0,
      title: (json['title'] ?? json['business_title'] ?? '').toString(),
      image: img,
      description: (json['description'] ?? json['short_description'] ?? '').toString(),
      distance: json['distance'] != null
          ? double.tryParse(json['distance'].toString())
          : null,
    );
  }
}

/// ========================= SERVICES =========================

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

class BusinessService {
  static Future<List<BusinessModel>> fetchBusinesses({
    required double lat, 
    required double lng
  }) async {
    try {
      final url = "https://churppy.eurekawebsolutions.com/api/businesses.php?lat=$lat&lng=$lng";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['status'] == 'success') {
          final List data = body['data'] ?? [];
          return data.map((e) => BusinessModel.fromJson(e)).toList();
        } else {
          throw Exception(body['message'] ?? "Unexpected API response");
        }
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to fetch businesses: $e");
    }
  }
}

/// ========================= HOME SCREEN =========================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Async data
  late Future<List<AlertModel>> futureAlerts;
  late Future<List<BusinessModel>> futureBusinesses;

  // Search state
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;
  List<BusinessModel> filteredBusinesses = [];
  List<AlertModel> filteredAlerts = [];

  // Paging for alerts carousel
  final PageController _pageController = PageController(viewportFraction: 0.8);

  // User profile
  String? _profileImageUrl;
  int? _userId;

  // UI filters
  String selectedFilter = "All";

  @override
  void initState() {
    super.initState();

    // Empty placeholders until permission is granted
    futureAlerts = Future.value([]);
    futureBusinesses = Future.value([]);

    _loadUserProfile();
    _searchController.addListener(_onSearchChanged);

    // Wait until user enables location first
    _getLocationAndLoad();
  }

  Future<void> _getLocationAndLoad() async {
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
              content: Text("Location permission is required to load nearby data."),
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

      // Only now fetch real location and load alerts + businesses
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        futureAlerts = AlertsService.fetchAlerts(
          lat: position.latitude, 
          lng: position.longitude
        );
        futureBusinesses = BusinessService.fetchBusinesses(
          lat: position.latitude,
          lng: position.longitude,
        );
      });

    } catch (e) {
      print("❌ Location error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to get location: $e")),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// ✅ Relative → Absolute URL normalizer for images
  String _absUrl(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    const base = 'https://churppy.eurekawebsolutions.com/';
    final cleaned = url.replaceFirst(RegExp(r'^/+'), '');
    return '$base$cleaned';
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString("user");
    if (userString != null) {
      final userMap = jsonDecode(userString);
      _userId = userMap['id'];
      if (_userId != null) {
        final url = "https://churppy.eurekawebsolutions.com/api/user.php?id=$_userId";
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

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        filteredBusinesses = [];
        filteredAlerts = [];
      });
      return;
    }
    setState(() => _isSearching = true);

    futureBusinesses.then((businesses) {
      final list = businesses.where((b) {
        return b.title.toLowerCase().contains(query) ||
            b.description.toLowerCase().contains(query);
      }).toList();
      if (mounted) setState(() => filteredBusinesses = list);
    });

    futureAlerts.then((alerts) {
      final list = alerts.where((a) {
        return a.title.toLowerCase().contains(query) ||
            a.businessTitle.toLowerCase().contains(query) ||
            a.description.toLowerCase().contains(query);
      }).toList();
      if (mounted) setState(() => filteredAlerts = list);
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _isSearching = false;
      filteredBusinesses = [];
      filteredAlerts = [];
      _searchFocusNode.unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final scale = (w / 390).clamp(0.85, 1.25);
    double fs(double x) => x * scale;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: fs(16), vertical: fs(12)),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('assets/images/logo.png', width: fs(100)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                      },
                      child: CircleAvatar(
                        radius: fs(20),
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _profileImageUrl != null && _profileImageUrl!.startsWith("http")
                            ? NetworkImage(_profileImageUrl!)
                            : null,
                        child: (_profileImageUrl == null || !_profileImageUrl!.startsWith("http"))
                            ? Icon(Icons.person, size: fs(20), color: Colors.grey[800])
                            : null,
                      ),
                    )
                  ],
                ),

                // Purple divider
                Container(
                  margin: EdgeInsets.symmetric(vertical: fs(10)),
                  height: 2,
                  width: double.infinity,
                  color: const Color(0xFF6C2FA0),
                ),
                SizedBox(height: fs(20)),

                // Search bar
                Container(
                  padding: EdgeInsets.symmetric(horizontal: fs(16), vertical: fs(2)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(fs(12)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: fs(10)),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Find Alerts, Restaurants, Food Trucks',
                            hintStyle: TextStyle(fontSize: fs(14), color: Colors.grey),
                          ),
                          style: TextStyle(fontSize: fs(14)),
                          onSubmitted: (_) => _onSearchChanged(),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: _clearSearch,
                          iconSize: fs(20),
                        ),
                      const Icon(Icons.tune, color: Colors.purple),
                    ],
                  ),
                ),
                SizedBox(height: fs(20)),

                // Alerts heading
                if (!_isSearching || filteredAlerts.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(left: fs(4)),
                    child: Text(
                      "Active Churppy Alerts",
                      style: TextStyle(
                        fontSize: fs(16),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                if (!_isSearching || filteredAlerts.isNotEmpty) SizedBox(height: fs(12)),

                // Alerts carousel
                if (!_isSearching || filteredAlerts.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: fs(20)),
                    child: _buildAlertsSection(fs),
                  ),

                // Businesses Section
                if (!_isSearching || filteredBusinesses.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(left: fs(4)),
                    child: Text(
                      'Businesses, Services and Offers',
                      style: TextStyle(
                        fontSize: fs(16),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                if (!_isSearching || filteredBusinesses.isNotEmpty) SizedBox(height: fs(12)),
                if (!_isSearching) _categoryFilters(fs),
                if (!_isSearching || filteredBusinesses.isNotEmpty) SizedBox(height: fs(16)),

                // Businesses Grid
                FutureBuilder<List<BusinessModel>>(
                  future: futureBusinesses,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Padding(
                        padding: EdgeInsets.all(fs(16)),
                        child: Text("Error: ${snapshot.error}", textAlign: TextAlign.center),
                      );
                    }

                    final businesses = _isSearching ? filteredBusinesses : (snapshot.data ?? []);

                    // ✅ UPDATED FILTER LOGIC - Only match by title
                    List<BusinessModel> displayList = businesses;
                    if (selectedFilter != 'All') {
                      String filter = selectedFilter.toLowerCase();
                      displayList = businesses.where((b) {
                        final title = b.title.toLowerCase();
                        return title.contains(filter);
                      }).toList();
                    }

                    if (displayList.isEmpty) {
                      return Padding(
                        padding: EdgeInsets.all(fs(16)),
                        child: Text(
                          _isSearching
                              ? "No results found for '${_searchController.text}'"
                              : "No businesses available in '$selectedFilter' category",
                          style: TextStyle(fontSize: fs(16), color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    // ✅ Responsive grid
                    return LayoutBuilder(
                      builder: (ctx, cons) {
                        final width = cons.maxWidth;
                        int cols;
                        if (width >= 1100) {
                          cols = 4;
                        } else if (width >= 800) {
                          cols = 3;
                        } else {
                          cols = 2;
                        }

                        final horizontalPad = fs(16) * 2;
                        final spacing = fs(12) * (cols - 1);
                        final tileWidth = (width - horizontalPad - spacing) / cols;

                        double tileHeight = fs(252);
                        final ts = MediaQuery.of(context).textScaleFactor;
                        if (ts > 1.1) tileHeight += fs(16);

                        final ratio = tileWidth / tileHeight;

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: fs(12),
                            mainAxisSpacing: fs(16),
                            childAspectRatio: ratio,
                          ),
                          itemCount: displayList.length,
                          itemBuilder: (context, index) {
                            final b = displayList[index];
                            return _businessCardLikeScreenshot(fs, b);
                          },
                        );
                      },
                    );
                  },
                ),
                SizedBox(height: fs(90)),
              ],
            ),
          ),
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

      // Bottom Navbar
      bottomNavigationBar: ChurppyNavbar(
        selectedIndex: 0,
        onTap: (int index) {
          switch (index) {
            case 0:
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
              break;
            case 1:
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              break;
            case 2:
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChurppyAlertsScreen()));
              break;
            case 3:
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactSupportScreen()));
              break;
            case 4:
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MapAlertsScreen()));
              break;
          }
        },
      ),
    );
  }

  /// ========================= ALERTS UI =========================
  Widget _buildAlertsSection(double Function(double) fs) {
    return FutureBuilder<List<AlertModel>>(
      future: futureAlerts,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: fs(180),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return SizedBox(
            height: fs(180),
            child: Center(
              child: Text(
                "Error loading alerts",
                style: TextStyle(fontSize: fs(14), color: Colors.grey),
              ),
            ),
          );
        }

        final all = snap.data ?? [];
        final alerts = _isSearching ? filteredAlerts : all;
        if (alerts.isEmpty) {
          return SizedBox(
            height: fs(180),
            child: Center(
              child: Text(
                "No alerts available",
                style: TextStyle(fontSize: fs(14), color: Colors.grey),
              ),
            ),
          );
        }

        return SizedBox(
          height: fs(180),
          child: PageView.builder(
            controller: _pageController,
            padEnds: false,
            itemCount: alerts.length,
            itemBuilder: (context, i) => Padding(
              padding: EdgeInsets.only(right: fs(16)),
              child: _AlertCard(
                fs: fs,
                alert: alerts[i],
                onViewNow: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MapAlertsScreen()),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  /// Horizontal Scrollable Filters
  Widget _categoryFilters(double Function(double) fs) {
    final filters = [
      'Tee’s Tasty Kitchen',
      'Churppy Treats',
      
    ];

    return SizedBox(
      height: fs(40),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => SizedBox(width: fs(10)),
        itemBuilder: (context, index) {
          final label = filters[index];
          final bool isSelected = selectedFilter == label;
          return InkWell(
            onTap: () {
              setState(() => selectedFilter = label);
            },
            borderRadius: BorderRadius.circular(fs(20)),
            child: Chip(
              backgroundColor: isSelected ? const Color(0xFF8DC63F) : const Color(0xFFE0E0E0),
              label: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: fs(12),
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// ===== Helpers for Business card =====
  Map<String, String> _splitNameAndAddress(String about) {
    final s = about.trim();
    if (s.isEmpty) return {"name": "Business", "addr1": "", "addr2": ""};

    int idx = -1;

    final m = RegExp(r'\d').firstMatch(s);
    if (m != null) idx = m.start;

    if (idx == -1 && s.contains('\n')) idx = s.indexOf('\n');
    if (idx == -1 && s.contains(',')) {
      final firstComma = s.indexOf(',');
      if (firstComma > 8) idx = firstComma;
    }

    if (idx != -1) {
      final name = s.substring(0, idx).trim().replaceAll(RegExp(r'[,\-–|]+$'), '');
      final addr = s.substring(idx).trim();

      String addr1 = addr, addr2 = "";
      if (addr.contains(',')) {
        final parts = addr.split(',');
        addr1 = parts.take(2).join(',').trim();
        addr2 = parts.skip(2).join(',').trim();
      }
      return {
        "name": name.isEmpty ? "Business" : name,
        "addr1": addr1,
        "addr2": addr2
      };
    }

    return {"name": s, "addr1": "", "addr2": ""};
  }

  Widget _businessCardLikeScreenshot(double Function(double) fs, BusinessModel b) {
    final parsed = _splitNameAndAddress(b.description);
    final name   = (b.title.isNotEmpty ? b.title : (parsed["name"] ?? "Business"));
    final addr1  = parsed["addr1"] ?? "";
    final addr2  = parsed["addr2"] ?? "";

    String _descSnippet() {
      var s = (b.description ?? '').trim();
      if (s.isEmpty) return '';
      if (b.title.isNotEmpty &&
          s.toLowerCase().startsWith(b.title.toLowerCase())) {
        s = s.substring(b.title.length).trim();
      }
      s = s.replaceAll(RegExp(r'^[,\-\–\|\:\. ]+'), '').trim();
      return s;
    }

    final hasAddress = addr1.isNotEmpty || addr2.isNotEmpty;
    final desc = _descSnippet();

    return InkWell(
      onTap: () {
        print("Business tapped → id: ${b.id} , merchantId: ${b.merchantId}");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MenuScreen(
            merchantId: b.merchantId,
            categoryId: b.id,
            title: b.title,
            image: b.image,
            description: b.description,
          )),
        );
      },
      borderRadius: BorderRadius.circular(fs(16)),
      child: Container(
        padding: EdgeInsets.all(fs(10)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(fs(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: fs(10), vertical: fs(5)),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F5),
                  borderRadius: BorderRadius.circular(fs(30)),
                ),
                child: Text(
                  (b.title.isNotEmpty ? b.title : "Business"),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: fs(10.5), color: Colors.black87),
                ),
              ),
            ),
            SizedBox(height: fs(8)),

            ClipRRect(
              borderRadius: BorderRadius.circular(fs(12)),
              child: Image.network(
                _absUrl(b.image),
                height: fs(84),
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(height: fs(84), color: Colors.grey[200]),
              ),
            ),
            SizedBox(height: fs(10)),

            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fs(13),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: fs(4)),

            if (hasAddress) ...[
              if (addr1.isNotEmpty)
                Text(
                  addr1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: fs(11.5), color: Colors.black87, height: 1.2),
                ),
              if (addr2.isNotEmpty)
                Text(
                  addr2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: fs(11.5), color: Colors.black87, height: 1.2),
                ),
            ] else if (desc.isNotEmpty) ...[
              Text(
                desc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: fs(11.5), color: Colors.black87, height: 1.25),
              ),
            ] else ...[
              const SizedBox(height: 14),
            ],

            const Spacer(),

            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.orange),
                SizedBox(width: fs(4)),
                Text("5.0", style: TextStyle(fontSize: fs(12.5))),
                SizedBox(width: fs(6)),
                Text("CHURPPY", style: TextStyle(fontSize: fs(11), color: Colors.black54)),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.favorite_border, color: Colors.black54),
                  iconSize: fs(20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Alert Card widget
class _AlertCard extends StatelessWidget {
  final double Function(double) fs;
  final AlertModel alert;
  final VoidCallback onViewNow;

  const _AlertCard({
    required this.fs,
    required this.alert,
    required this.onViewNow,
  });

  @override
  Widget build(BuildContext context) {
    final cover = alert.image.isNotEmpty ? alert.image : alert.businessLogo;
    final title = alert.title.isNotEmpty ? alert.title : alert.businessTitle;
    final desc = alert.description.isNotEmpty
        ? alert.description
        : "truck is serving in your area\nTime is ticking. Place order now!";
    final timeLabel = alert.timeLeft ?? "";

    String _abs(String url) {
      if (url.isEmpty) return url;
      if (url.startsWith('http://') || url.startsWith('https://')) return url;
      const base = 'https://churppy.eurekawebsolutions.com/';
      final cleaned = url.replaceFirst(RegExp(r'^/+'), '');
      return '$base$cleaned';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(fs(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 14,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(fs(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: fs(60),
              width: double.infinity,
              child: Image.network(
                _abs(cover),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Center(child: Icon(Icons.image_not_supported)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(fs(10), fs(8), fs(10), fs(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: fs(12.5),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6C2FA0),
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: fs(4)),
                    Expanded(
                      child: Text(
                        desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fs(11),
                          color: Colors.black87,
                          height: 1.25,
                        ),
                      ),
                    ),
                    SizedBox(height: fs(6)),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: onViewNow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8DC63F),
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                                horizontal: fs(14), vertical: fs(8)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(fs(20)),
                            ),
                          ),
                          child: Text(
                            "VIEW NOW",
                            style: TextStyle(
                              fontSize: fs(11),
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (timeLabel.isNotEmpty)
                          Flexible(
                            child: Text(
                              timeLabel,
                              style: TextStyle(fontSize: fs(10.5), color: Colors.black54),
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ========================= NAVBAR =========================
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
      Icons.chat_bubble_outline,
      Icons.favorite_border,
    ];

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      color: const Color(0xFF804692),
      notchMargin: 10.0,
      child: SizedBox(
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (index) {
            if (index == 2) return const SizedBox(width: 60);

            final iconIndex = index > 2 ? index - 1 : index;
            final isSelected = selectedIndex == index;

            return IconButton(
              onPressed: () => onTap(index),
              icon: Icon(
                icons[iconIndex],
                color: Colors.white,
                size: isSelected ? 28 : 24,
              ),
            );
          }),
        ),
      ),
    );
  }
}