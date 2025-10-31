// lib/services/discount_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class DiscountService {
  static Future<Map<String, dynamic>?> getActiveDiscount(int merchantId) async {
    try {
      final url = Uri.parse(
          "https://churppy.eurekawebsolutions.com/api/discount.php?merchant_id=$merchantId");
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'success' && data['data'] != null) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print("❌ Discount fetch error: $e");
      return null;
    }
  }
}