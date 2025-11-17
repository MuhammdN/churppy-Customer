import 'dart:convert';
import 'package:churppy_customer/screens/profile.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class OrderDetailScreen extends StatefulWidget {
  final String orderId; // order_id from csdp_orders

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _loading = true;
  String? _profileImageUrl;
  int? _userId;
  Map<String, dynamic>? _orderData;

  @override
  void initState() {
    super.initState();
    _loadUserProfileAndOrder();
  }

  /// ✅ Load user profile + fetch order details
  Future<void> _loadUserProfileAndOrder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString("user");

      if (userString != null) {
        final userMap = jsonDecode(userString);
        _userId = userMap["id"];

        // ✅ Fetch user profile image
        final profileUrl =
            "https://churppy.eurekawebsolutions.com/api/user.php?id=$_userId";
        final profileResponse = await http.get(Uri.parse(profileUrl));

        if (profileResponse.statusCode == 200) {
          final data = jsonDecode(profileResponse.body);
          if (data["status"] == "success") {
            _profileImageUrl = data["data"]["image"];
          }
        }
      }

      // ✅ Fetch order details (dynamic)
      final url =
          "https://churppy.eurekawebsolutions.com/api/customer_order_detail.php?order_id=${widget.orderId}";
      final res = await http.get(Uri.parse(url));

      if (res.statusCode == 200) {
        final result = jsonDecode(res.body);
        if (result["status"] == "success") {
          setState(() {
            _orderData = result["data"];
          });
        } else {
          debugPrint("❌ ${result["message"]}");
        }
      }
    } catch (e) {
      debugPrint("⚠️ Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  /// ✅ Status mapper
  String _mapStatus(dynamic status) {
    if (status == null) return "Unknown";
    switch (status.toString()) {
      case "0":
        return "Pending";
      case "1":
        return "Delivered";
      case "2":
        return "Cancelled";
      default:
        return status.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final scale = (w / 390).clamp(0.85, 1.25);
    double fs(double x) => x * scale;

    final order = _orderData;
    final items = (order != null && order['items'] is List)
        ? List<Map<String, dynamic>>.from(order['items'])
        : [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : order == null
                ? const Center(child: Text("Order details not found"))
                : Column(
                    children: [
                      /// 🔰 HEADER
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: fs(16), vertical: fs(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Image.asset('assets/images/logo.png',
                                height: fs(30), fit: BoxFit.contain),

                            /// ✅ Tapable profile image
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ProfileScreen()),
                              ),
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

                      /// 🟣 Title Bar
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: fs(16), vertical: fs(20)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              child: Icon(Icons.arrow_back,
                                  color: Colors.black, size: fs(20)),
                            ),
                            Text(
                              'Order Details',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: fs(16),
                              ),
                            ),
                            SizedBox(width: fs(36)),
                          ],
                        ),
                      ),

                      /// 🧾 MAIN CONTENT
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                              horizontal: fs(16), vertical: fs(10)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Basic Info
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      "Order No: ${order['order_number'] ?? '—'}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      "Date: ${order['order_date'] ?? ''} ${order['order_time'] ?? ''}",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              Text("Customer Name: ${order['name'] ?? '—'}"),
                              Text("Email: ${order['email'] ?? '—'}"),
                              Text("Phone: ${order['contact_no'] ?? '—'}"),
                              Text("Address: ${order['address'] ?? '—'}"),
                              Text("City: ${order['city'] ?? '—'}"),
                              Text("Area: ${order['area'] ?? '—'}"),
                              Text("Street: ${order['street'] ?? '—'}"),
                              const Divider(height: 30),

                              /// Dynamic Item Section
                              const Text(
                                "ORDER ITEMS DETAIL",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF804692)),
                              ),
                              const SizedBox(height: 14),

                              const Row(
                                children: [
                                  Expanded(
                                      flex: 4,
                                      child: Text("Item Name",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  Expanded(
                                      flex: 1,
                                      child: Text("Qty",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  Expanded(
                                      flex: 2,
                                      child: Text("Amount",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold))),
                                ],
                              ),
                              const Divider(),

                              /// 🟢 Loop through real items
                              for (final item in items)
                                _buildOrderRow(
                                  item['item_name'] ?? '-',
                                  item['quantity'].toString(),
                                  "\$${item['price'] ?? '0'}",
                                ),

                              const Divider(),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  "Total: \$${order['total'] ?? '—'}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 20),

                              /// Status Row
                              Row(
                                children: [
                                  const Expanded(
                                      child: Text("Order Status",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF804692),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _mapStatus(order['status']),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500),
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

  /// 🔁 Order Row Builder
  static Widget _buildOrderRow(String item, String qty, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(item)),
          Expanded(flex: 1, child: Text(qty)),
          Expanded(flex: 2, child: Text(amount)),
        ],
      ),
    );
  }
}
