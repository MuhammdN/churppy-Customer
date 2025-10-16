import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Screens (already in your project)
import 'package:churppy_customer/screens/support.dart';
import 'package:churppy_customer/screens/profile.dart';
import 'package:churppy_customer/screens/menuScreen.dart';
import 'ChurppyAlertsScreen.dart';
import 'map_active_alert.dart';

/// ========================= MODELS =========================

// Alerts model -> csdp_merchant_alerts + csdp_business_infos join (PHP given)
class AlertModel {
  final int id;
  final int merchantId;

  final String title;        // ma.title
  final String description;  // ma.description
  final String image;        // ma.image (absolute URL via PHP/normalized)
  final String startDate;    // ma.start_date
  final String expiryDate;   // ma.expiry_date

  final String businessLogo;   // b.business_logo (absolute URL via PHP/normalized)
  final String businessTitle;  // b.about_us AS business_title

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
    );
  }
}

// ✅ Businesses model (robust): API chahe `business_logo` de ya `image`, dono support
class BusinessModel {
  final int id;
  final int merchantId;
  final String title;        // proper business/category name
  final String image;        // absolute image url (business_logo OR image)
  final String description;  // address/desc (split karke lines bana rahe)

  BusinessModel({
    required this.id,
    required this.merchantId,
    required this.title,
    required this.image,
    required this.description,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    final img = (json['business_logo'] ?? json['image'] ?? '').toString();
    return BusinessModel(
      id: json['id'] ?? 0,
      merchantId: json['merchant_id'] ?? 0,
      title: (json['title'] ?? '').toString(),
      image: img,
      description: (json['description'] ?? '').toString(),
    );
  }
}

/// ========================= SERVICES =========================
class AlertsService {
  // parse helper
  static DateTime? _parse(String s) {
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s.replaceFirst(' ', 'T'));
    } catch (_) {
      return null;
    }
  }

  // only active alerts (not expired). If start is future, hide until it starts.
  static bool _isActive(AlertModel a) {
    final start = _parse(a.startDate);
    final end = _parse(a.expiryDate);
    final now = DateTime.now();

    if (start != null && start.isAfter(now)) return false; // scheduled, not started yet
    if (end == null) return true;
    return end.isAfter(now);
  }

  static Future<List<AlertModel>> fetchAlerts() async {
    try {
      final res = await http.get(
        Uri.parse("https://churppy.eurekawebsolutions.com/api/alerts.php"),
      );
      if (res.statusCode != 200) {
        throw Exception("Server error: ${res.statusCode}");
      }
      final body = json.decode(res.body);
      if (body['status'] != 'success') {
        throw Exception(body['message'] ?? "Unexpected API response");
      }
      final List data = body['data'] ?? [];
      final list = data.map((e) => AlertModel.fromJson(e)).toList();

      // filter: only active
      final active = list.where(_isActive).toList();
      return active;
    } catch (e) {
      throw Exception("Failed to fetch alerts: $e");
    }
  }
}

class BusinessService {
  static Future<List<BusinessModel>> fetchBusinesses() async {
    try {
      final response = await http.get(
        Uri.parse("https://churppy.eurekawebsolutions.com/api/businesses.php"),
      );

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
    futureAlerts = AlertsService.fetchAlerts();
    futureBusinesses = BusinessService.fetchBusinesses();
    _loadUserProfile();
    _searchController.addListener(_onSearchChanged);
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
    const base = 'https://churppy.eurekawebsolutions.com/'; // apna domain
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
            a.businessTitle.toLowerCase().contains(query);
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
    final h = MediaQuery.of(context).size.height;
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
                    CircleAvatar(
                      radius: fs(20),
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _profileImageUrl != null && _profileImageUrl!.startsWith("http")
                          ? NetworkImage(_profileImageUrl!)
                          : null,
                      child: (_profileImageUrl == null || !_profileImageUrl!.startsWith("http"))
                          ? Icon(Icons.person, size: fs(20), color: Colors.grey[800])
                          : null,
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
                  padding: EdgeInsets.symmetric(horizontal: fs(16), vertical: fs(12)),
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
                  Text(
                    "Active Churppy Alerts",
                    style: TextStyle(fontSize: fs(16), fontWeight: FontWeight.bold),
                  ),
                if (!_isSearching || filteredAlerts.isNotEmpty) SizedBox(height: fs(10)),

                // Alerts carousel
                if (!_isSearching || filteredAlerts.isNotEmpty) _buildAlertsSection(fs),

                if (!_isSearching || filteredAlerts.isNotEmpty) SizedBox(height: fs(30)),

                // Businesses Section
                if (!_isSearching || filteredBusinesses.isNotEmpty)
                  Text(
                    'Businesses, Services and Offers',
                    style: TextStyle(fontSize: fs(16), fontWeight: FontWeight.bold),
                  ),
                if (!_isSearching || filteredBusinesses.isNotEmpty) SizedBox(height: fs(12)),
                if (!_isSearching) _categoryFilters(fs),
                if (!_isSearching || filteredBusinesses.isNotEmpty) SizedBox(height: fs(16)),

                FutureBuilder<List<BusinessModel>>(
                  future: futureBusinesses,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    }

                    final businesses = _isSearching ? filteredBusinesses : (snapshot.data ?? []);

                    if (businesses.isEmpty) {
                      if (_isSearching) {
                        return Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: fs(40)),
                            child: Text(
                              "No results found for '${_searchController.text}'",
                              style: TextStyle(fontSize: fs(16), color: Colors.grey),
                            ),
                          ),
                        );
                      } else {
                        return const Text("No businesses available");
                      }
                    }

                    // ✅ Responsive grid: dynamic columns + height
                    return LayoutBuilder(
                      builder: (ctx, cons) {
                        final width = cons.maxWidth;
                        int cols;
                        if (width >= 1100) {
                          cols = 4;
                        } else if (width >= 800) {
                          cols = 3;
                        } else {
                          cols = 2; // phones / small tablets
                        }

                        final horizontalPad = fs(16) * 2;
                        final spacing = fs(12) * (cols - 1);
                        final tileWidth = (width - horizontalPad - spacing) / cols;

                        double tileHeight = fs(252); // balanced height for your layout
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
                          itemCount: businesses.length,
                          itemBuilder: (context, index) {
                            final b = businesses[index];
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
        backgroundColor: const Color(0xFF6C2FA0),
        shape: const CircleBorder(),
        elevation: 6,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
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
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) return Text("Error: ${snap.error}");
        final all = snap.data ?? [];
        final alerts = _isSearching ? filteredAlerts : all;
        if (alerts.isEmpty) return const Text("No alerts available");

        return SizedBox(
          height: fs(220),
          child: PageView.builder(
            controller: _pageController,
            padEnds: false,
            itemCount: alerts.length,
            itemBuilder: (context, i) => Padding(
              padding: EdgeInsets.only(right: fs(20)),
              child: _AlertCard(
                fs: fs,
                alert: alerts[i],
                onViewNow: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MenuScreen(merchantId: alerts[i].merchantId),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // Time label using start/expiry
  String _timeLabel({required String start, required String end}) {
    DateTime? parse(String s) {
      if (s.isEmpty) return null;
      try {
        return DateTime.parse(s.replaceFirst(' ', 'T'));
      } catch (_) {
        return null;
      }
    }

    final now = DateTime.now();
    final startDt = parse(start);
    final endDt = parse(end);

    Duration? diff;
    String suffix = " Left";

    if (startDt != null && startDt.isAfter(now)) {
      diff = startDt.difference(now);
      suffix = " to Start";
    } else if (endDt != null) {
      diff = endDt.difference(now);
      if (diff.isNegative) return "Expired";
    } else {
      return "";
    }

    final days = diff.inDays;
    final hours = diff.inHours % 24;
    final mins = diff.inMinutes % 60;

    if (days > 0 && hours > 0) return "$days Days & $hours Hours$suffix";
    if (days > 0) return "$days Days$suffix";
    if (hours > 0 && mins > 0) return "$hours Hours $mins Min$suffix";
    if (hours > 0) return "$hours Hours$suffix";
    return "$mins Min$suffix";
  }

  /// Chip Filters (UI only)
  Widget _categoryFilters(double Function(double) fs) {
    final filters = ['All', 'Restaurants', 'Laundry Pick Up', 'Specials'];
    return Wrap(
      spacing: fs(10),
      children: filters.map((label) {
        final bool isSelected = selectedFilter == label;
        return InkWell(
          onTap: () => setState(() => selectedFilter = label),
          child: Chip(
            backgroundColor: isSelected ? const Color(0xFF6DC24B) : const Color(0xFFE0E0E0),
            label: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// ===== Helpers for Business card =====

  /// about_us/description se Name + Address split
  Map<String, String> _splitNameAndAddress(String about) {
    final s = about.trim();
    if (s.isEmpty) return {"name": "Business", "addr1": "", "addr2": ""};

    int idx = -1;

    // first digit
    final m = RegExp(r'\d').firstMatch(s);
    if (m != null) idx = m.start;

    // fallback: newline
    if (idx == -1 && s.contains('\n')) idx = s.indexOf('\n');

    // fallback: comma (avoid very early commas in brand names)
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

    // no clear split -> name only
    return {"name": s, "addr1": "", "addr2": ""};
  }

  /// Screenshot-style business card
  /// Screenshot-style business card
  Widget _businessCardLikeScreenshot(double Function(double) fs, BusinessModel b) {
    // Parse name/address from description (optional)
    final parsed = _splitNameAndAddress(b.description);
    final name   = (b.title.isNotEmpty ? b.title : (parsed["name"] ?? "Business"));
    final addr1  = parsed["addr1"] ?? "";
    final addr2  = parsed["addr2"] ?? "";

    // Clean 2-line description snippet (title prefix waghera hata dein)
    String _descSnippet() {
      var s = (b.description ?? '').trim();
      if (s.isEmpty) return '';
      // remove leading title if duplicated at start
      if (b.title.isNotEmpty &&
          s.toLowerCase().startsWith(b.title.toLowerCase())) {
        s = s.substring(b.title.length).trim();
      }
      // remove leading punctuation like ", - | :"
      s = s.replaceAll(RegExp(r'^[,\-\–\|\:\. ]+'), '').trim();
      return s;
    }

    final hasAddress = addr1.isNotEmpty || addr2.isNotEmpty;
    final desc = _descSnippet();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MenuScreen(merchantId: b.merchantId)),
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
            // top category chip — show title (single line)
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

            // image
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

            // name
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

            // Prefer address if we could parse it, otherwise show description snippet
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
              // nothing to show — keep spacing stable
              const SizedBox(height: 14),
            ],

            const Spacer(),

            // bottom row
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.orange),
                SizedBox(width: fs(4)),
                Text("4.8", style: TextStyle(fontSize: fs(12.5))),
                SizedBox(width: fs(6)),
                Text("CHURPPY", style: TextStyle(fontSize: fs(11), color: Colors.black54)),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    // TODO: favorite toggle
                  },
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

  /// ===== Old vendor card (kept to avoid breaking anything elsewhere) =====
  Widget _vendorCard(
      double Function(double) fs,
      String image,
      String title,
      String address,
      String rating,
      int merchantId,
      ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MenuScreen(merchantId: merchantId)),
        );
      },
      borderRadius: BorderRadius.circular(fs(16)),
      child: Container(
        padding: EdgeInsets.all(fs(14)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(fs(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            image.startsWith("http")
                ? Image.network(image, width: fs(70), height: fs(70))
                : Image.asset(image, width: fs(70), height: fs(70)),
            SizedBox(height: fs(10)),
            Flexible(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: fs(10)),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            SizedBox(height: fs(6)),
            Flexible(
              child: Text(
                address,
                style: TextStyle(fontSize: fs(12), color: Colors.black54),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: fs(10)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.orange, size: 18),
                SizedBox(width: fs(4)),
                Text(rating, style: TextStyle(fontSize: fs(13))),
                SizedBox(width: fs(10)),
                const Icon(Icons.favorite_border, size: 18, color: Colors.grey),
              ],
            )
          ],
        ),
      ),
    );
  }
}

/// Alert Card widget (separate class for clarity)
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
    final timeLabel = (context.findAncestorStateOfType<_HomeScreenState>())
        ?._timeLabel(start: alert.startDate, end: alert.expiryDate) ??
        "";

    // Local helper to normalize URL
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
            // top image
            SizedBox(
              height: fs(90),
              width: double.infinity,
              child: Image.network(
                _abs(cover),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                const Center(child: Icon(Icons.image_not_supported)),
              ),
            ),
            // text + actions
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(fs(12), fs(10), fs(12), fs(10)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: fs(13),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6C2FA0),
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: fs(6)),
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: fs(11.5),
                        color: Colors.black87,
                        height: 1.25,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: onViewNow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6DC24B),
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                                horizontal: fs(16), vertical: fs(10)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(fs(24)),
                            ),
                          ),
                          child: Text(
                            "VIEW NOW",
                            style: TextStyle(
                              fontSize: fs(12),
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (timeLabel.isNotEmpty)
                          Text(
                            timeLabel,
                            style:
                            TextStyle(fontSize: fs(11.5), color: Colors.black54),
                            textAlign: TextAlign.right,
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
      Icons.receipt_long_outlined,
      Icons.favorite_border,
    ];

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      color: const Color(0xFF6C2FA0),
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
