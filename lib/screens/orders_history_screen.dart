import 'dart:convert';
import 'package:churppy_customer/screens/OrderDetailScreen.dart';
import 'package:churppy_customer/screens/profile.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({super.key});

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  int? _userId;
  String? _profileImageUrl;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 10;

  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadUserAndData();
  }

  Future<void> _loadUserAndData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString("user");

      if (userString != null) {
        final userMap = jsonDecode(userString);
        _userId = userMap["id"];

        // ✅ Profile Image
        final profileUrl =
            "https://churppy.eurekawebsolutions.com/api/user.php?id=$_userId";
        final profileResponse = await http.get(Uri.parse(profileUrl));
        if (profileResponse.statusCode == 200) {
          final data = jsonDecode(profileResponse.body);
          if (data["status"] == "success") {
            _profileImageUrl = data["data"]["image"];
          }
        }

        await _fetchOrders(reset: true);
      }
    } catch (e) {
      debugPrint("⚠️ Orders fetch failed: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchOrders({bool reset = false}) async {
    if (_userId == null) return;
    if (!reset && !_hasMore) return;

    setState(() {
      if (reset) _loading = true;
      else _loadingMore = true;
    });

    try {
      final url =
          "https://churppy.eurekawebsolutions.com/api/customer_orders.php?user_id=$_userId&limit=$_limit&offset=$_offset";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result["status"] == "success") {
          final List<dynamic> newOrders = result["data"] ?? [];

          setState(() {
            if (reset) {
              _orders = newOrders;
              _offset = newOrders.length;
            } else {
              _orders.addAll(newOrders);
              _offset += newOrders.length;
            }

            _hasMore = newOrders.length == _limit;
          });
        }
      }
    } catch (e) {
      debugPrint("⚠️ Load more error: $e");
    } finally {
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange.shade700;
      case "delivered":
        return const Color(0xFF804692);
      case "cancel":
      case "cancelled":
        return Colors.red.shade700;
      case "success":
        return Colors.green.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  String _normalizeStatus(dynamic status) {
    if (status == null) return "Unknown";
    final s = status.toString().toLowerCase();
    if (s.contains("pend")) return "Pending";
    if (s.contains("deliver")) return "Delivered";
    if (s.contains("cancel")) return "Cancel";
    if (s.contains("success")) return "Success";
    return status.toString();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final scale = (w / 390).clamp(0.85, 1.25);
    double fs(double x) => x * scale;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  /// 🔰 Header (Logo + Profile)
                  Container(
                    color: Colors.white,
                    padding:
                        EdgeInsets.symmetric(horizontal: fs(16), vertical: fs(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset("assets/images/logo.png",
                            height: fs(34), fit: BoxFit.contain),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ProfileScreen()),
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

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Divider(color: Colors.purple, thickness: 2),
                  ),

                  /// 🔰 Title
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: fs(16), vertical: fs(12)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom:
                            BorderSide(color: Colors.grey.shade300, width: 0.8),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: fs(18),
                          backgroundColor: Colors.grey.shade200,
                          child: IconButton(
                            icon: Icon(Icons.arrow_back,
                                color: Colors.black, size: fs(18)),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text("Orders History",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: fs(17))),
                      ],
                    ),
                  ),

                  /// 🟫 Table Header
                  Container(
                    color: Colors.grey.shade100,
                    padding:
                        EdgeInsets.symmetric(vertical: fs(10), horizontal: fs(15)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _headerCell("Order No", flex: 2),
                        _headerCell("Date", flex: 2),
                        _headerCell("Amount", flex: 2),
                        _headerCell("Detail", flex: 2),
                      ],
                    ),
                  ),

                  /// 🧾 Order List
                  Expanded(
                    child: _orders.isEmpty
                        ? Center(
                            child: Text("No orders found.",
                                style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: fs(15),
                                    fontWeight: FontWeight.w500)),
                          )
                        : ListView.builder(
                            itemCount: _orders.length,
                            itemBuilder: (context, index) {
                              final order = _orders[index];
                              final orderId = order["id"]?.toString() ?? ""; // ✅ sending this
                              final orderNo =
                                  order["order_number"]?.toString() ?? "—";
                              final date =
                                  order["order_date"]?.toString() ?? "—";
                              final amount =
                                  order["payment_type"]?.toString() ?? "—";

                              return Container(
                                color: index.isEven
                                    ? Colors.grey.shade50
                                    : Colors.grey.shade100,
                                padding: EdgeInsets.symmetric(
                                    vertical: fs(10), horizontal: fs(15)),
                                child: Row(
                                  children: [
                                    Expanded(
                                        flex: 2,
                                        child: Text(orderNo,
                                            style: TextStyle(fontSize: fs(13)))),
                                    Expanded(
                                        flex: 2,
                                        child: Text(date,
                                            style: TextStyle(fontSize: fs(11)))),
                                    Expanded(
                                        flex: 2,
                                        child: Text(amount,
                                            style: TextStyle(fontSize: fs(13)))),
                                    Expanded(
                                      flex: 2,
                                      child: InkWell(
                                        onTap: () {
                                          if (orderId.isNotEmpty) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    OrderDetailScreen(orderId: orderId),
                                              ),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      "Order ID not found")),
                                            );
                                          }
                                        },
                                        child: Text(
                                          "View",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                              fontSize: fs(13)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  /// 🔘 Load More Button
                  if (_hasMore)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: GestureDetector(
                        onTap: _loadingMore ? null : () => _fetchOrders(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 40),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: _loadingMore
                              ? const CircularProgressIndicator()
                              : const Text("Load More",
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _headerCell(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}
