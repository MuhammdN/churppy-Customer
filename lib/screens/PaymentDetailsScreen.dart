import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Screens
import '../widgets/churppy_navbar.dart';
import 'profile.dart';
import 'support.dart';
import 'home_screen.dart' hide ChurppyNavbar;
import 'map_active_alert.dart';
import 'ChurppyAlertsScreen.dart';

class PaymentDetailsScreen extends StatefulWidget {
  const PaymentDetailsScreen({super.key});

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  String? _profileImageUrl;
  int? _userId;
  bool _loading = true;
  List<dynamic> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadUserAndPayments();
  }

  Future<void> _loadUserAndPayments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString("user");
      if (userString != null) {
        final userMap = jsonDecode(userString);
        _userId = userMap['id'];

        // ✅ Fetch user profile
        final profileUrl =
            "https://churppy.eurekawebsolutions.com/api/user.php?id=$_userId";
        final profileResponse = await http.get(Uri.parse(profileUrl));
        if (profileResponse.statusCode == 200) {
          final data = jsonDecode(profileResponse.body);
          if (data['status'] == 'success') {
            setState(() => _profileImageUrl = data['data']['image']);
          }
        }

        // ✅ Fetch payment details from new API
        final paymentUrl =
            "https://churppy.eurekawebsolutions.com/api/customer_payment_details.php?user_id=$_userId";
        final payResponse = await http.get(Uri.parse(paymentUrl));
        if (payResponse.statusCode == 200) {
          final paymentData = jsonDecode(payResponse.body);
          if (paymentData['status'] == 'success') {
            setState(() {
              _payments = paymentData['data'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint("⚠️ Payment load failed: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return Colors.green.shade700;
      case 'pending':
        return Colors.orange.shade600;
      case 'failed':
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade500;
    }
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
            /// 🔰 HEADER
            Column(
              children: [
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: fs(16), vertical: fs(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset('assets/images/logo.png',
                          height: fs(30), fit: BoxFit.contain),
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
                  padding:
                      EdgeInsets.symmetric(horizontal: fs(16), vertical: fs(20)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child:
                            Icon(Icons.arrow_back, color: Colors.black, size: fs(20)),
                      ),
                      Text(
                        'Payment Details',
                        style: TextStyle(
                          color: Colors.black,
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

            /// 📄 TABLE HEADER
            Container(
              color: Colors.grey.shade100,
              padding:
                  EdgeInsets.symmetric(vertical: fs(10), horizontal: fs(15)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      flex: 2,
                      child: Text('Order ID',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: fs(13)))),
                  Expanded(
                      flex: 2,
                      child: Text('Date',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: fs(13)))),
                  Expanded(
                      flex: 2,
                      child: Text('Amount',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: fs(13)))),
                  Expanded(
                      flex: 2,
                      child: Text('Status',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: fs(13)))),
                ],
              ),
            ),

            /// 🧾 PAYMENT DATA
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _payments.isEmpty
                      ? Center(
                          child: Text(
                            "No payments found.",
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: fs(15),
                                fontWeight: FontWeight.w500),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _payments.length,
                          itemBuilder: (context, index) {
                            final p = _payments[index];
                            final orderId = p['order_number'] ?? "—";
                            final date = p['created_at'] ?? "";
                            final amount = p['amount']?.toString() ?? "0";
                            final status =
                                p['payment_status'] ?? "Unknown";

                            return Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: fs(10), horizontal: fs(15)),
                              decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: Colors.grey.shade300, width: 0.5)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                      flex: 2,
                                      child: Text(orderId,
                                          style: TextStyle(fontSize: fs(13)))),
                                  Expanded(
                                      flex: 2,
                                      child: Text(date,
                                          style: TextStyle(fontSize: fs(13)))),
                                  Expanded(
                                      flex: 2,
                                      child: Text("\$$amount",
                                          style: TextStyle(fontSize: fs(13)))),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: fs(8), vertical: fs(4)),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status)
                                            .withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(fs(6)),
                                      ),
                                      child: Text(
                                        status,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _statusColor(status),
                                          fontWeight: FontWeight.w600,
                                          fontSize: fs(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),

            /// 🔘 LOAD MORE
            Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: () => debugPrint('Load More Payments'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: const Text(
                    'Load More',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      /// ➕ Floating Action Button
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

      /// 🔻 Full Bottom Navbar
      bottomNavigationBar: ChurppyNavbar(
        selectedIndex: 2,
        onTap: (int index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()));
              break;
            case 1:
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()));
              break;
            case 2:
              // Already on PaymentDetailsScreen
              break;
            case 3:
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const ContactSupportScreen()));
              break;
            case 4:
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const MapAlertsScreen()));
              break;
          }
        },
      ),
    );
  }
}
