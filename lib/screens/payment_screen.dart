import 'dart:convert';
import 'package:churppy_customer/screens/discount_service.dart';
import 'package:churppy_customer/screens/popupScreen.dart';
import 'package:churppy_customer/screens/profile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:geocoding/geocoding.dart';

class PaymentScreen extends StatefulWidget {
  final int itemId;
  final int merchantId;
  final int quantity;
  final double totalPrice;
  final String title;

  const PaymentScreen({
    super.key,
    required this.itemId,
    required this.merchantId,
    required this.quantity,
    required this.totalPrice,
    required this.title,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool isLoading = false;
  int _userId = 0;
  String? _profileImageUrl;
  
  // Discount related variables
  Map<String, dynamic>? _activeDiscount;
  double _discountAmount = 0.0;
  bool _isLoadingDiscount = true;

  // --- Form Fields ---
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  String paymentType = "card"; // default

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _loadUserProfile();
    _fetchActiveDiscount(); // Fetch discount on screen load
  }

  // Fetch active discount for merchant
  Future<void> _fetchActiveDiscount() async {
    try {
      setState(() => _isLoadingDiscount = true);
      
      final discount = await DiscountService.getActiveDiscount(widget.merchantId);
      
      if (discount != null && mounted) {
        setState(() {
          _activeDiscount = discount;
          // Calculate discount amount
          final discountPercentage = double.tryParse(discount['discount'].toString()) ?? 0.0;
          _discountAmount = (widget.totalPrice * discountPercentage) / 100;
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching discount: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingDiscount = false);
      }
    }
  }

  Future<String> _getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        
        // Complete address 
        String address = '';
        if (place.street != null && place.street!.isNotEmpty) {
          address += place.street!;
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.locality!;
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.administrativeArea!;
        }
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          if (address.isNotEmpty) address += ' - ';
          address += place.postalCode!;
        }
        if (place.country != null && place.country!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.country!;
        }
        
        return address.isNotEmpty ? address : 'Address not found';
      }
      return 'Address not found';
    } catch (e) {
      debugPrint("❌ Geocoding error: $e");
      return 'Failed to get address';
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString("user");
      if (userString == null) return;

      final userMap = jsonDecode(userString);
      _userId = userMap['id'] ?? 0;
      if (_userId == 0) return;

      final url = "https://churppy.eurekawebsolutions.com/api/user.php?id=$_userId";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final user = data['data'];
          
          String address = '';
          
          // Check if address contains coordinates
          if (user['address'] != null && user['address'].toString().contains(',')) {
            final addressParts = user['address'].toString().split(',');
            if (addressParts.length >= 2) {
              try {
                final double lat = double.parse(addressParts[0].trim());
                final double lng = double.parse(addressParts[1].trim());
                
                // Convert coordinates to address
                address = await _getAddressFromLatLng(lat, lng);
              } catch (e) {
                // If parsing fails, use original address
                address = user['address'] ?? '';
                debugPrint("❌ Coordinate parsing error: $e");
              }
            } else {
              address = user['address'] ?? '';
            }
          } else {
            address = user['address'] ?? '';
          }
          
          setState(() {
            _profileImageUrl = user['image'];
            nameCtrl.text = "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}".trim();
            emailCtrl.text = user['email'] ?? '';
            phoneCtrl.text = user['phone_number'] ?? '';
            addressCtrl.text = address; // Converted address
          });
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching user: $e");
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
    }
  }

  Future<Map<String, dynamic>?> _createPaymentIntent(double amount) async {
    try {
      final url = Uri.parse(
          "https://churppy.eurekawebsolutions.com/api/create_payment_intent.php");
      final body =
          jsonEncode({"amount": (amount * 100).toInt(), "currency": "usd"});
      final response = await http.post(url,
          headers: {"Content-Type": "application/json"}, body: body);
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint("❌ Exception creating PaymentIntent: $e");
    }
    return null;
  }

  Future<void> _saveOrderToDatabase({
    String? chargeId,
    String? orderId,
  }) async {
    try {
      final url = Uri.parse(
          "https://churppy.eurekawebsolutions.com/api/insert_order.php");
      
      // Calculate final amounts with discount
      final subtotal = widget.totalPrice;
      final discountAmount = _discountAmount;
      final totalAfterDiscount = subtotal - discountAmount;
      
      final Map<String, dynamic> payload = {
        "merchant_id": widget.merchantId,
        "user_id": _userId,
        "name": nameCtrl.text,
        "email": emailCtrl.text,
        "contact_no": phoneCtrl.text,
        "address": addressCtrl.text,
        "note_for_rider": noteCtrl.text,
        "payment_type": paymentType,
        "payment_status": paymentType == "card" ? "paid" : "pending",
        "order_date": DateTime.now().toString().split(" ").first,
        "order_time": TimeOfDay.now().format(context),
        "coupon_id": 0,
        "item_id": widget.itemId,
        "item_name": widget.title,
        "quantity": widget.quantity,
        "price": totalAfterDiscount, // Send discounted price
        "charge_id": chargeId ?? "0",
        "stripe_order_id": orderId ?? "",
        "discount_amount": discountAmount,
        "discount_percentage": _activeDiscount != null ? _activeDiscount!['discount'] : 0,
      };
      
      debugPrint("📤 Sending JSON Order Data: $payload");
      final response = await http.post(url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(payload));
      debugPrint("📦 Order Insert Response: ${response.body}");
    } catch (e) {
      debugPrint("❌ Failed to save order: $e");
    }
  }

  // Check if error is due to user cancellation
  bool _isUserCancellation(String error) {
    final errorLower = error.toLowerCase();
    return errorLower.contains('cancel') ||
           errorLower.contains('dismiss') ||
           errorLower.contains('abort') ||
           errorLower.contains('back') ||
           errorLower.contains('sheet');
  }

  // User-friendly cancellation message
  void _showCancellationMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange[100], size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Payment cancelled. You can try again anytime.",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[700],
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Payment error message
  void _showPaymentError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[100], size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                error.length > 100 ? 'Payment failed. Please try again.' : error,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _handleCardPayment(double grandTotal) async {
    setState(() => isLoading = true);
    final intentData = await _createPaymentIntent(grandTotal);
    if (intentData == null || intentData["client_secret"] == null) {
      setState(() => isLoading = false);
      _showPaymentError("Payment setup failed. Please try again.");
      return;
    }

    final clientSecret = intentData["client_secret"];
    final paymentIntentId = intentData["payment_intent_id"];
    
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Churppy',
          style: ThemeMode.light,
        ),
      );
      
      await Stripe.instance.presentPaymentSheet();
      
      // Payment successful
      await _saveOrderToDatabase(
          chargeId: clientSecret, orderId: paymentIntentId);
      setState(() => isLoading = false);
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      
      final errorMessage = e.toString();
      
      if (_isUserCancellation(errorMessage)) {
        _showCancellationMessage();
      } else {
        _showPaymentError("Payment failed. Please try again.");
      }
    }
  }

  Future<void> _handleCashOnDelivery() async {
    setState(() => isLoading = true);
    await _saveOrderToDatabase();
    setState(() => isLoading = false);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PaymentSuccessScreen()),
      );
    }
  }

  void _processOrder(double total) {
    if (_userId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⚠️ User not logged in"),
          backgroundColor: Colors.orange[700],
        ),
      );
      return;
    }
    if (nameCtrl.text.isEmpty ||
        phoneCtrl.text.isEmpty ||
        addressCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill required fields (*)"),
          backgroundColor: Colors.orange[700],
        ),
      );
      return;
    }
    
    // Use discounted total for payment
    if (paymentType == "card") {
      _handleCardPayment(total);
    } else {
      _handleCashOnDelivery();
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final scale = (w / 390).clamp(0.85, 1.25);
    double fs(double x) => x * scale;
    
    // Calculate totals
    final subtotal = widget.totalPrice;
    final taxes = subtotal * 0.1;
    final delivery = 1.50;
    final discount = _discountAmount;
    final totalAfterDiscount = subtotal - discount;
    final finalGrandTotal = totalAfterDiscount + taxes + delivery;

    return Scaffold(
      backgroundColor: const Color(0xfff9f9f9),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(fs),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    EdgeInsets.symmetric(horizontal: fs(16), vertical: fs(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderSummaryCard(
                        subtotal, taxes, delivery, finalGrandTotal, fs),
                    SizedBox(height: fs(24)),
                    _buildDeliveryInfoCard(fs),
                    SizedBox(height: fs(24)),
                    _buildPaymentMethodCard(fs),
                    SizedBox(height: fs(40)),
                  ],
                ),
              ),
            ),
            _buildBottomButton(finalGrandTotal, fs),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double Function(double) fs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      padding: EdgeInsets.symmetric(horizontal: fs(16), vertical: fs(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, size: fs(20), color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            SizedBox(width: fs(12)),
            Image.asset("assets/images/logo.png", height: fs(32)),
          ]),
          GestureDetector(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()));
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
                  ? Icon(Icons.person, size: fs(20), color: Colors.grey[800])
                  : null,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(double subtotal, double taxes, double delivery,
      double grandTotal, double Function(double) fs) {
        
    // Calculate totals with discount
    final discount = _discountAmount;
    final totalAfterDiscount = subtotal - discount;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(fs(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.receipt_long, color: Color(0xFF8DC63F), size: fs(18)),
            SizedBox(width: fs(8)),
            Text("Order Summary",
                style: TextStyle(
                    fontSize: fs(16),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
          ]),
          
          // Discount Banner - Show loading or discount info
          if (_isLoadingDiscount) ...[
            SizedBox(height: fs(12)),
            Container(
              padding: EdgeInsets.all(fs(12)),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: fs(16),
                    height: fs(16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: fs(8)),
                  Text(
                    "Checking for discounts...",
                    style: TextStyle(
                      fontSize: fs(14),
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_activeDiscount != null) ...[
            SizedBox(height: fs(12)),
            Container(
              padding: EdgeInsets.all(fs(12)),
              decoration: BoxDecoration(
                color: Color(0xFFE8F5E8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFF8DC63F), width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_offer, color: Color(0xFF8DC63F), size: fs(16)),
                  SizedBox(width: fs(8)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _activeDiscount!['title'] ?? 'Discount Applied',
                          style: TextStyle(
                            fontSize: fs(14),
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (_activeDiscount!['description'] != null)
                          Text(
                            _activeDiscount!['description'],
                            style: TextStyle(
                              fontSize: fs(12),
                              color: Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Text(
                    "${_activeDiscount!['discount']}% OFF",
                    style: TextStyle(
                      fontSize: fs(14),
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8DC63F),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          SizedBox(height: fs(16)),
          _buildSummaryItem(
              "Subtotal (${widget.quantity} items)",
              "\$${subtotal.toStringAsFixed(2)}",
              fs),
          
          // Discount Row
          if (_activeDiscount != null) ...[
            _buildSummaryItem(
              "Discount (${_activeDiscount!['discount']}%)",
              "-\$${discount.toStringAsFixed(2)}",
              fs,
              isDiscount: true,
            ),
            _buildSummaryItem(
              "Subtotal after discount",
              "\$${totalAfterDiscount.toStringAsFixed(2)}",
              fs,
            ),
          ],
          
          _buildSummaryItem(
              "Taxes (10%)", "\$${taxes.toStringAsFixed(2)}", fs),
          _buildSummaryItem(
              "Delivery Fee", "\$${delivery.toStringAsFixed(2)}", fs),
          Divider(height: fs(20)),
          _buildSummaryItem(
            "Total Amount", 
            "\$${grandTotal.toStringAsFixed(2)}", 
            fs,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value,
      double Function(double) fs,
      {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: fs(6)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: fs(14),
                  color: isTotal ? Colors.black : Colors.grey[700],
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: fs(14),
                  color: isDiscount 
                      ? Colors.red 
                      : isTotal ? Color(0xFF8DC63F) : Colors.grey[700],
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfoCard(double Function(double) fs) {
    return Container(
      padding: EdgeInsets.all(fs(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.person_pin_circle, color: Color(0xFF8DC63F), size: fs(18)),
          SizedBox(width: fs(8)),
          Text("Delivery & Contact Info",
              style: TextStyle(
                  fontSize: fs(16),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87))
        ]),
        SizedBox(height: fs(16)),
        _buildCustomField("Full Name *", nameCtrl, fs, Icons.person_outline),
        SizedBox(height: fs(12)),
        _buildCustomField("Email (optional)", emailCtrl, fs, Icons.email_outlined),
        SizedBox(height: fs(12)),
        _buildCustomField("Contact No *", phoneCtrl, fs,
            Icons.phone_iphone_outlined,
            keyboard: TextInputType.phone),
        SizedBox(height: fs(12)),
        _buildCustomField("Complete Address *", addressCtrl, fs,
            Icons.home_outlined,
            maxLines: 2),
        SizedBox(height: fs(12)),
        _buildCustomField("Note for rider (optional)", noteCtrl, fs,
            Icons.note_outlined,
            maxLines: 2),
      ]),
    );
  }

  Widget _buildPaymentMethodCard(double Function(double) fs) {
    return Container(
      padding: EdgeInsets.all(fs(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.payment, color: Color(0xFF8DC63F), size: fs(18)),
          SizedBox(width: fs(8)),
          Text("Payment Method",
              style: TextStyle(
                  fontSize: fs(16),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87))
        ]),
        SizedBox(height: fs(16)),
        DropdownButtonFormField<String>(
          value: paymentType,
          decoration: InputDecoration(border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(
              value: "card",
              child: Row(children: [
                Icon(Icons.credit_card, color: Colors.blue),
                SizedBox(width: 8),
                Text("Credit/Debit Card")
              ]),
            ),
            DropdownMenuItem(
              value: "cash_on_delivery",
              child: Row(children: [
                Icon(Icons.money, color: Color(0xFF8DC63F)),
                SizedBox(width: 8),
                Text("Cash on Delivery")
              ]),
            ),
          ],
          onChanged: (val) => setState(() => paymentType = val ?? "card"),
        )
      ]),
    );
  }

  Widget _buildCustomField(String label, TextEditingController c,
      double Function(double) fs, IconData icon,
      {TextInputType keyboard = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: c,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildBottomButton(double grandTotal, double Function(double) fs) {
    return Container(
      padding: EdgeInsets.all(fs(16)),
      decoration: BoxDecoration(
          color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12)]),
      child: Row(children: [
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text("Total Amount",
                  style: TextStyle(fontSize: fs(12), color: Colors.grey[600])),
              Text("\$${grandTotal.toStringAsFixed(2)}",
                  style: TextStyle(
                      fontSize: fs(22),
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8DC63F)))
            ])),
        SizedBox(
          width: fs(160),
          child: ElevatedButton(
            onPressed: isLoading ? null : () => _processOrder(grandTotal),
            style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8DC63F),
                padding: EdgeInsets.symmetric(vertical: fs(14)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: isLoading
                ? SizedBox(
                    height: fs(20),
                    width: fs(20),
                    child:
                        CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(
                    paymentType == "card"
                        ? Icons.payment
                        : Icons.shopping_cart_checkout,
                    size: fs(16),
                    color: Colors.white,
                  ),
                  SizedBox(width: 6),
                  Text(
                    paymentType == "card" ? "Pay Now" : "Confirm Order",
                    style: GoogleFonts.roboto(
                      fontSize: fs(14),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  ]),
          ),
        )
      ]),
    );
  }
}