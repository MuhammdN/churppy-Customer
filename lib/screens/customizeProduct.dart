import 'package:churppy_customer/screens/payment_screen.dart';
import 'package:churppy_customer/screens/profile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'product_details_screen.dart';

/// ========================= MODEL =========================
class MenuItemModel {
  final int id;
  final String title;
  final String image;
  final String description;
  final double price;

  MenuItemModel({
    required this.id,
    required this.title,
    required this.image,
    required this.description,
    required this.price,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      image: json['image'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] != null)
          ? double.tryParse(json['price'].toString()) ?? 0.0
          : 0.0,
    );
  }
}

class MenuItemDetail {
  final int id;
  final String title;
  final String description;
  final String image;
  final double price;

  MenuItemDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.price,
  });

  factory MenuItemDetail.fromJson(Map<String, dynamic> json) {
    return MenuItemDetail(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      price: (json['price'] != null)
          ? double.tryParse(json['price'].toString()) ?? 0.0
          : 0.0,
    );
  }
}

/// ========================= SERVICES =========================
class MenuItemDetailService {
  static Future<MenuItemDetail> fetchItemDetail(int itemId) async {
    final response = await http.get(
      Uri.parse("https://churppy.eurekawebsolutions.com/api/menu_item_detail.php?id=$itemId"),
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body['status'] == 'success') {
        return MenuItemDetail.fromJson(body['data']);
      } else {
        throw Exception(body['message'] ?? "Unexpected API response");
      }
    } else {
      throw Exception("Server error: ${response.statusCode}");
    }
  }

  static Future<List<MenuItemModel>> fetchOtherItems(int merchantId, int excludeId) async {
    final response = await http.get(
      Uri.parse("https://churppy.eurekawebsolutions.com/api/menu_items.php?merchant_id=$merchantId&exclude_id=$excludeId"),
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body['status'] == 'success') {
        final List data = body['data'];
        return data.map((e) => MenuItemModel.fromJson(e)).toList();
      } else {
        throw Exception(body['message'] ?? "Unexpected API response");
      }
    } else {
      throw Exception("Server error: ${response.statusCode}");
    }
  }
}

/// ========================= SCREEN =========================
class CustomizeProductScreen extends StatefulWidget {
  final int itemId;
  final int quantity;
  final double totalPrice;
  final int merchantId;

  const CustomizeProductScreen({
    super.key,
    required this.itemId,
    required this.quantity,
    required this.totalPrice,
    required this.merchantId
  });

  @override
  State<CustomizeProductScreen> createState() => _CustomizeProductScreenState();
}

class _CustomizeProductScreenState extends State<CustomizeProductScreen> {
  late int count;
  late double basePrice;
  late double totalPrice;
  double spiceLevel = 0.5;

  int _userId = 0;
  String? _profileImageUrl;

  late Future<MenuItemDetail> futureItem;
  late Future<List<MenuItemModel>> futureOtherItems;

  @override
  void initState() {
    super.initState();
    count = widget.quantity;
    basePrice = widget.totalPrice / widget.quantity;
    totalPrice = widget.totalPrice;

    futureItem = MenuItemDetailService.fetchItemDetail(widget.itemId);
    futureOtherItems = MenuItemDetailService.fetchOtherItems(widget.merchantId, widget.itemId);

    _loadUserId();
    _loadUserProfile();
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
            setState(() {
              _profileImageUrl = data['data']['image'];
            });
          }
        }
      }
    }
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString("user");
    if (userString != null) {
      final userMap = jsonDecode(userString);
      setState(() => _userId = userMap['id'] ?? 0);
    }
  }

  void _updateTotalPrice() {
    setState(() {
      totalPrice = basePrice * count;
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final scale = (w / 390).clamp(0.85, 1.25);
    double fs(double x) => x * scale;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<MenuItemDetail>(
          future: futureItem,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData) {
              return const Center(child: Text("No item found"));
            }

            final item = snapshot.data!;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: fs(16), vertical: fs(12)),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back, color: Colors.black, size: fs(22)),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Image.asset("assets/images/logo.png", height: fs(34)),
                          ],
                        ),
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
        ? Icon(
            Icons.person,
            size: fs(20),
            color: Colors.grey[800],
          )
        : null,
  ),
)

                      ],
                    ),
                    SizedBox(height: fs(16)),

                    /// Product Image + Controls
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: item.image.isNotEmpty
                              ? Image.network(item.image, height: fs(200), fit: BoxFit.contain)
                              : Image.asset("assets/images/burger.png", height: fs(200), fit: BoxFit.contain),
                        ),
                        SizedBox(width: fs(12)),
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: fs(16))),
                              SizedBox(height: fs(6)),
                              Text(item.description.isNotEmpty ? item.description : "No description available"),
                              SizedBox(height: fs(20)),

                              Text("Count", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fs(13))),
                              SizedBox(height: fs(6)),
                              Row(
                                children: [
                                  _circleBtn(Icons.remove, () {
                                    if (count > 1) {
                                      count--;
                                      _updateTotalPrice();
                                    }
                                  }),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: fs(25)),
                                    child: Text('$count', style: TextStyle(fontSize: fs(16), fontWeight: FontWeight.bold)),
                                  ),
                                  _circleBtn(Icons.add, () {
                                    count++;
                                    _updateTotalPrice();
                                  }),
                                ],
                              ),
                              SizedBox(height: fs(20)),

                              /// 🌶️ Spice Slider (ALWAYS VISIBLE)
                              Text("Add Our Special Spice", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fs(13))),
                              Slider(
                                value: spiceLevel,
                                onChanged: (value) => setState(() => spiceLevel = value),
                                activeColor: Colors.green,
                                inactiveColor: Colors.grey.shade300,
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: fs(4)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Mild", style: TextStyle(fontSize: fs(11), color: Colors.green)),
                                    Text("Hot", style: TextStyle(fontSize: fs(11), color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: fs(24)),

                    /// Side Options
                    Text("Side options", style: TextStyle(fontWeight: FontWeight.bold, fontSize: fs(13))),
                    SizedBox(height: fs(8)),

                    FutureBuilder<List<MenuItemModel>>(
                      future: futureOtherItems,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snap.hasError) {
                          return Text("Error: ${snap.error}");
                        } else if (!snap.hasData || snap.data!.isEmpty) {
                          return const Text("No other products available");
                        }

                        final others = snap.data!;
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: others.map((p) => _sideItemCard(p, fs)).toList(),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: fs(24)),

                    /// Total + Order Now
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: fs(18), color: Colors.black),
                            children: [
                              const TextSpan(text: "Total\n", style: TextStyle(fontSize: 16, color: Colors.black)),
                              TextSpan(text: "\$${totalPrice.toStringAsFixed(2)}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (_userId == 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("⚠️ User not logged in")),
                              );
                              return;
                            }
                            Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => PaymentScreen(
      itemId: widget.itemId,
      merchantId: widget.merchantId,   // ✅ YE LINE ADD KARO
      quantity: count,
      totalPrice: totalPrice,
      title:item.title
    ),
  ),
);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1CC019),
                            padding: EdgeInsets.symmetric(horizontal: fs(24), vertical: fs(12)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text("ORDER NOW", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: fs(14))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Circle Button
  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }

  /// Side Item Card (Same Style ✅)
  Widget _sideItemCard(MenuItemModel item, double Function(double) fs) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomizeProductScreen(
                itemId: item.id,
                quantity: 1,
                totalPrice: item.price,
                merchantId: widget.merchantId,
              ),
            ),
          );
        },
        child: Column(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: item.image.isNotEmpty
                        ? Image.network(item.image, width: 90, height: 90, fit: BoxFit.cover)
                        : Image.asset("assets/images/burger.png", width: 90, height: 90, fit: BoxFit.cover),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.add, size: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 90,
              child: Text(item.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}
