import 'dart:convert';
import 'package:churppy_customer/screens/profile.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'customizeProduct.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ========================= MODEL =========================
class MenuItemDetail {
  final int id;
  final String title;
  final String image;
  final String description;
  final double price;

  MenuItemDetail({
    required this.id,
    required this.title,
    required this.image,
    required this.description,
    required this.price,
  });

  factory MenuItemDetail.fromJson(Map<String, dynamic> json) {
    return MenuItemDetail(
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

/// ========================= SERVICE =========================
class MenuItemDetailService {
  static Future<MenuItemDetail> fetchItemDetail(int itemId) async {
    final response = await http.get(
      Uri.parse(
          "https://churppy.eurekawebsolutions.com/api/menu_item_detail.php?id=$itemId"),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['status'] == 'success') {
        return MenuItemDetail.fromJson(body['data']);
      } else {
        throw Exception(body['message']);
      }
    } else {
      throw Exception("Server error: ${response.statusCode}");
    }
  }
}

/// ========================= SCREEN =========================
class ProductDetailsScreen extends StatefulWidget {
  final int itemId;
  final int merchantId; 

  const ProductDetailsScreen({super.key, required this.itemId,required this.merchantId,});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late Future<MenuItemDetail> futureItem;
  int count = 1;

  String? _profileImageUrl;
  int? _userId=0;

  @override
  void initState() {
    super.initState();
    futureItem = MenuItemDetailService.fetchItemDetail(widget.itemId);
    _loadUserId();
    debugPrint("🟢 ProductDetailsScreen opened with itemId: ${widget.itemId}");
    _loadUserProfile();
  }
  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString("user");

    if (userString != null) {
      final userMap = jsonDecode(userString);
      _userId = userMap['id'];

      debugPrint("🟢 User ID from prefs: $_userId");

      if (_userId != null) {
        final url = "https://churppy.eurekawebsolutions.com/api/user.php?id=$_userId";
        debugPrint("🌍 Fetching user profile from $url");

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
    final userString = prefs.getString("user"); // 👈 correct key

    if (userString != null) {
      final userMap = jsonDecode(userString);
      setState(() {
        _userId = userMap['id'] ?? 0;
      });
    } else {
      setState(() {
        _userId= 0;
      });
    }

    debugPrint("👤 Loaded user_id in ProductDetailsScreen: $_userId");
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final scale = (w / 390).clamp(0.85, 1.25);
    double fs(double x) => x * scale;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset("assets/images/logo.png", height: fs(34)),
        centerTitle: true,
      actions: [
  Padding(
    padding: EdgeInsets.only(right: fs(12)),
    child: GestureDetector(
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
    ),
  ),
],

      ),
      body: FutureBuilder<MenuItemDetail>(
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
          double totalPrice = item.price * count; // ✅ runtime total

          return Padding(
            padding: EdgeInsets.all(fs(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🍔 Product Image
                Center(
                  child: item.image.isNotEmpty
                      ? Image.network(
                    item.image,
                    height: fs(230),
                    fit: BoxFit.contain,
                  )
                      : Image.asset(
                    'assets/images/burger.png',
                    height: fs(230),
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: fs(16)),

                /// 🏷 Name + Price (base price only)
                Text(
                  "${item.title}  \$${item.price.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: fs(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: fs(6)),

                /// ⭐ Rating & time (Static for now)
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 16),
                    SizedBox(width: fs(4)),
                    Text("5.0", style: TextStyle(fontSize: fs(12))),
                    SizedBox(width: fs(8)),
                    const Text("–", style: TextStyle(fontSize: 12)),
                    SizedBox(width: fs(8)),
                    const Icon(Icons.timer_outlined,
                        size: 16, color: Colors.black54),
                    SizedBox(width: fs(4)),
                    Text("26 mins", style: TextStyle(fontSize: fs(12))),
                  ],
                ),
                SizedBox(height: fs(12)),

                /// 📖 Description
                Text(
                  item.description.isNotEmpty
                      ? item.description
                      : "No description available.",
                  style: TextStyle(
                    fontSize: fs(13),
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: fs(20)),

                /// ➕➖ Count control
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => setState(() {
                        if (count > 1) count--;
                      }),
                      icon: const Icon(Icons.remove_circle,
                          color: Color(0xFF8DC63F),),
                    ),
                    Text(
                      '$count',
                      style: TextStyle(
                          fontSize: fs(14), fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        count++;
                      }),
                      icon: const Icon(Icons.add_circle, color: const Color(0xFF8DC63F),),
                    ),
                  ],
                ),
               
                SizedBox(height: fs(200)),
                /// 💰 Buttons Row
                Row(
                  children: [
                    /// Price Button
                    Expanded(
                      child: Container(
                        height: fs(52),
                        decoration: BoxDecoration(
                          color: const Color(0xFF804692),
                          borderRadius: BorderRadius.circular(fs(12)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "\$${totalPrice.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: fs(14),
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: fs(12)),

                    /// Customize Button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_userId == 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("⚠️ User not logged in"),
                              ),
                            );
                            return;
                          }

                          Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => CustomizeProductScreen(
      itemId: item.id,
      merchantId: widget.merchantId,   // ✅ merchant_id forward kar diya
      quantity: count,
      totalPrice: totalPrice,
    ),
  ),
);

                        },
                        child: Container(
                          height: fs(52),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8DC63F),
                            borderRadius: BorderRadius.circular(fs(12)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "CUSTOMIZE",
                            style: TextStyle(
                              fontSize: fs(14),
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
