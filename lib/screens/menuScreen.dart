import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:churppy_customer/screens/support.dart';
import 'package:churppy_customer/screens/product_details_screen.dart';
import 'package:churppy_customer/screens/profile.dart';
import 'package:churppy_customer/screens/home_screen.dart';
import 'ChurppyAlertsScreen.dart';
import 'map_active_alert.dart';

/// ========================= MENU ITEM MODEL =========================
class MenuItemModel {
  final int id;
  final String title;
  final String image;
  final String description;
  final double price;
  final String category; // API me agar cat_name aaye to use hota rahe

  MenuItemModel({
    required this.id,
    required this.title,
    required this.image,
    required this.description,
    required this.price,
    required this.category,
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
      category: json['cat_name'] ?? 'All',
    );
  }
}

/// ========================= CATEGORY MODEL =========================
class CategoryModel {
  final int id;
  final int merchantId;
  final String title;

  CategoryModel({
    required this.id,
    required this.merchantId,
    required this.title,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? 0,
      merchantId: json['merchant_id'] ?? 0,
      title: json['title'] ?? '',
    );
  }
}

/// ========================= SERVICES =========================
class MenuItemService {
  static Future<List<MenuItemModel>> fetchMenuItems(int merchantId) async {
    try {
      final response = await http.get(
        Uri.parse(
            "https://churppy.eurekawebsolutions.com/api/menu_items.php?merchant_id=$merchantId"),
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
    } catch (e) {
      throw Exception("Failed to fetch menu items: $e");
    }
  }
}

class CategoryService {
  static Future<List<CategoryModel>> fetchCategories(int merchantId) async {
    final response = await http.get(
      Uri.parse(
          "https://churppy.eurekawebsolutions.com/api/menu_categories.php?merchant_id=$merchantId"),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['status'] == 'success') {
        final List data = body['data'];
        return data.map((e) => CategoryModel.fromJson(e)).toList();
      } else {
        throw Exception(body['message']);
      }
    } else {
      throw Exception("Server error: ${response.statusCode}");
    }
  }
}

/// ========================= SCREEN =========================
class MenuScreen extends StatefulWidget {
  final int merchantId;
  final int? categoryId;
  final String? title;
  final String? image;
  final String? description;

  const MenuScreen({
    super.key,
    required this.merchantId,
    this.categoryId,
    this.title,
    this.image,
    this.description,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late Future<List<MenuItemModel>> futureMenuItems;
  late Future<List<CategoryModel>> futureCategories;

  String selectedCategory = "All";
  List<MenuItemModel> allItems = [];
  int? userId;
  Set<int> favoriteItems = {};
  String? _profileImageUrl;
  int? _userId;

  @override
  void initState() {
    super.initState();
    futureMenuItems = MenuItemService.fetchMenuItems(widget.merchantId);
    futureCategories = CategoryService.fetchCategories(widget.merchantId);
    _loadUserId();
    _loadFavorites();
    print("✅ Merchant ID received: ${widget.merchantId}");
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
        userId = userMap['id'];
      });
    }
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesString = prefs.getString('favorites_$userId');
    if (favoritesString != null) {
      final List<dynamic> favoritesList = jsonDecode(favoritesString);
      setState(() {
        favoriteItems = Set<int>.from(favoritesList.map((id) => id as int));
      });
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesList = favoriteItems.toList();
    await prefs.setString('favorites_$userId', jsonEncode(favoritesList));
  }

  void _toggleFavorite(int itemId) {
    setState(() {
      if (favoriteItems.contains(itemId)) {
        favoriteItems.remove(itemId);
      } else {
        favoriteItems.add(itemId);
      }
    });
    _saveFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final scale = (w / 390).clamp(0.85, 1.25);
    double fs(double x) => x * scale;
    final gridAspect = w <= 360 ? 0.78 : 0.72;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: fs(16), vertical: fs(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset("assets/images/logo.png", height: fs(34)),
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
              SizedBox(height: fs(16)),

              /// Restaurant Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(fs(10)),
                    child: Image.network(
                      widget.image ?? '',
                      height: fs(60),
                      width: fs(60),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                          "assets/images/tees_tasty_logo.png",
                          height: fs(60),
                          width: fs(60),
                          fit: BoxFit.cover),
                    ),
                  ),
                  SizedBox(width: fs(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title ?? "Business",
                            style: TextStyle(
                                fontSize: fs(14), fontWeight: FontWeight.bold)),
                        SizedBox(height: fs(2)),
                        Text(widget.description ?? "No description available",
                            style: TextStyle(fontSize: fs(12), height: 1.3),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: fs(16)),

              /// Dynamic Filter Buttons
              FutureBuilder<List<CategoryModel>>(
                future: futureCategories,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text("No categories available");
                  }

                  final categories = snapshot.data!;

                  /// ✅ Debug print to console
                  print("✅ Filters for Merchant ID: ${widget.merchantId}");
                  for (var c in categories) {
                    print(" - ${c.title}");
                  }

                  return SizedBox(
                    height: fs(36),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => SizedBox(width: fs(10)),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final selected = selectedCategory == category.title;
                        return ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedCategory = category.title;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: selected
                                ? const Color(0xFF8DC63F)
                                : const Color(0xFFF3F3F3),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(category.title,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: selected ? Colors.white : Colors.black)),
                        );
                      },
                    ),
                  );
                },
              ),

              SizedBox(height: fs(16)),

              /// Menu Items Grid
              FutureBuilder<List<MenuItemModel>>(
                future: futureMenuItems,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text("No menu items available");
                  }

                  allItems = snapshot.data!;

                  /// ✅ Filter now based on item.title (not category)
                  final filteredItems = selectedCategory == "All"
                      ? allItems
                      : allItems
                          .where((item) =>
                              item.title.toLowerCase() ==
                              selectedCategory.toLowerCase())
                          .toList();

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredItems.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: fs(16),
                      crossAxisSpacing: fs(16),
                      childAspectRatio: gridAspect,
                    ),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return _productCard(
                        context,
                        fs,
                        item: item,
                        isFavorite: favoriteItems.contains(item.id),
                        onFavoriteTap: () => _toggleFavorite(item.id),
                      );
                    },
                  );
                },
              ),
              SizedBox(height: fs(80)),
            ],
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
    padding: const EdgeInsets.all(10), // adjust for centering
    child: Image.asset(
      'assets/images/alert1.png', // 👈 your image file path
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

  /// ================= PRODUCT CARD =================
  Widget _productCard(
    BuildContext context,
    double Function(double) fs, {
    required MenuItemModel item,
    required bool isFavorite,
    required VoidCallback onFavoriteTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailsScreen(
                      itemId: item.id,
                      merchantId: widget.merchantId,
                    ),
                  ),
                );
              },
              child: item.image.isNotEmpty
                  ? Image.network(item.image,
                      height: fs(130),
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                          "assets/images/burger.png",
                          height: fs(130),
                          width: double.infinity,
                          fit: BoxFit.cover))
                  : Image.asset("assets/images/burger.png",
                      height: fs(130),
                      width: double.infinity,
                      fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(fs(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${item.title} • ${item.price.toStringAsFixed(2)}",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: fs(12), fontWeight: FontWeight.bold)),
                SizedBox(height: fs(6)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        SizedBox(width: fs(4)),
                        Text("5.0", style: TextStyle(fontSize: fs(12))),
                      ],
                    ),
                    InkWell(
                      onTap: onFavoriteTap,
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: isFavorite ? Colors.red : Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ================= NAVBAR =================
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
      notchMargin: 8.0,
      child: SizedBox(
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (index) {
            if (index == 2) return const SizedBox(width: 40);
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
