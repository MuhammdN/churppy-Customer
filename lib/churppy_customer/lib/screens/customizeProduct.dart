import 'package:churppy_customer/screens/payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'product_details_screen.dart'; // 👈 is file me MenuItemDetail & Service defined hain

class CustomizeProductScreen extends StatefulWidget {
  final int itemId;
  final int quantity;
  final double totalPrice;

  const CustomizeProductScreen({
    super.key,
    required this.itemId,
    required this.quantity,
    required this.totalPrice,
  });

  @override
  State<CustomizeProductScreen> createState() =>
      _CustomizeProductScreenState();
}

class _CustomizeProductScreenState extends State<CustomizeProductScreen> {
  late int count;
  late double basePrice;
  late double totalPrice;
  double spiceLevel = 0.5;

  int _userId = 0;
  String? _profileImageUrl;

  late Future<MenuItemDetail> futureItem; // 👈 API call future

  @override
  void initState() {
    super.initState();
    count = widget.quantity;
    basePrice = widget.totalPrice / widget.quantity;
    totalPrice = widget.totalPrice;

    futureItem = MenuItemDetailService.fetchItemDetail(widget.itemId);

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
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString("user");

    if (userString != null) {
      final userMap = jsonDecode(userString);
      setState(() {
        _userId = userMap['id'] ?? 0;
      });
    } else {
      setState(() {
        _userId = 0;
      });
    }

    debugPrint(
        "👤 _userId: $_userId, itemId: ${widget.itemId}, qty: $count, price: $totalPrice");
  }

  void _updateTotalPrice() {
    setState(() {
      totalPrice = basePrice * count;
    });
  }

  /// ✅ Helper function: check if slider should show
  bool _shouldShowSpiceSlider(String title) {
    final lower = title.toLowerCase();
    return lower.contains("burger") ||
        lower.contains("pizza") ||
        lower.contains("cake") ||
        lower.contains("fries");
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
              padding:
              EdgeInsets.symmetric(horizontal: fs(16), vertical: fs(12)),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🔰 Top Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back,
                                  color: Colors.black, size: fs(22)),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Image.asset("assets/images/logo.png",
                                height: fs(34)),
                          ],
                        ),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: fs(20),
                              backgroundColor: Colors.grey[300],
                              backgroundImage: _profileImageUrl != null &&
                                  _profileImageUrl!.startsWith("http")
                                  ? NetworkImage(_profileImageUrl!)
                                  : null,
                              child: (_profileImageUrl == null ||
                                  !_profileImageUrl!.startsWith("http"))
                                  ? Icon(
                                Icons.person,
                                size: fs(20),
                                color: Colors.grey[800],
                              )
                                  : null,
                            ),
                            SizedBox(width: fs(10)),
                            Icon(Icons.search,
                                color: Colors.black, size: fs(22)),
                          ],
                        )
                      ],
                    ),

                    SizedBox(height: fs(16)),

                    /// 🔻 Product Image + Right Controls
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// 🍔 Product Image
                        Expanded(
                          flex: 5,
                          child: item.image.isNotEmpty
                              ? Image.network(item.image,
                              height: fs(200), fit: BoxFit.contain)
                              : Image.asset("assets/images/burger.png",
                              height: fs(200), fit: BoxFit.contain),
                        ),

                        SizedBox(width: fs(12)),

                        /// 🔧 Right Side Controls
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: fs(16)),
                              ),
                              SizedBox(height: fs(6)),
                              Text(item.description.isNotEmpty
                                  ? item.description
                                  : "No description available"),
                              SizedBox(height: fs(20)),

                              /// 🔢 Count
                              Text("Count",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: fs(13))),
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
                                    padding: EdgeInsets.symmetric(
                                        horizontal: fs(25)),
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                          fontSize: fs(16),
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  _circleBtn(Icons.add, () {
                                    count++;
                                    _updateTotalPrice();
                                  }),
                                ],
                              ),
                              SizedBox(height: fs(20)),

                              /// 🌶️ Spice Slider (Conditional)
                              if (_shouldShowSpiceSlider(item.title)) ...[
                                Text("Add Our Special Spice",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: fs(13))),
                                Slider(
                                  value: spiceLevel,
                                  onChanged: (value) {
                                    setState(() => spiceLevel = value);
                                  },
                                  activeColor: Colors.green,
                                  inactiveColor: Colors.grey.shade300,
                                ),
                                Padding(
                                  padding:
                                  EdgeInsets.symmetric(horizontal: fs(4)),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Mild",
                                          style: TextStyle(
                                              fontSize: fs(11),
                                              color: Colors.green)),
                                      Text("Hot",
                                          style: TextStyle(
                                              fontSize: fs(11),
                                              color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: fs(24)),

                    /// 🍕 Toppings (placeholder)
                    Text("Toppings",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: fs(13))),
                    SizedBox(height: fs(150)),

                    /// 🍟 Side Options
                    Text("Side options",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: fs(13))),
                    SizedBox(height: fs(8)),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _sideItemCard("assets/images/fries.png", "Fries"),
                          _sideItemCard(
                              "assets/images/coleslaw.png", "Coleslaw"),
                          _sideItemCard("assets/images/salad.png", "Salad"),
                          _sideItemCard("assets/images/tomato.png", "Tomato"),
                        ],
                      ),
                    ),

                    SizedBox(height: fs(24)),

                    /// 💰 Total + Order Now
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                                fontSize: fs(18), color: Colors.black),
                            children: [
                              const TextSpan(
                                text: "Total\n",
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                              ),
                              TextSpan(
                                text:
                                "\$${totalPrice.toStringAsFixed(2)}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 30),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
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
                                builder: (_) => PaymentScreen(
                                  itemId: widget.itemId,
                                  quantity: count,
                                  totalPrice: totalPrice,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(
                                horizontal: fs(24), vertical: fs(12)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text("ORDER NOW",
                              style: TextStyle(
                                  color: Colors.white, fontSize: fs(14))),
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

  /// ⭕ Green Circle Buttons
  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }

  /// 🔧 Side Item Card
  Widget _sideItemCard(String imgPath, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    imgPath,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add,
                        size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
