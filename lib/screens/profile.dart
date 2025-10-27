import 'dart:convert';
import 'dart:io';
import 'package:churppy_customer/screens/OrderDetailScreen.dart';
import 'package:churppy_customer/screens/PaymentDetailsScreen.dart';
import 'package:churppy_customer/screens/contactUsScreen.dart';
import 'package:churppy_customer/screens/orders_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/login.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _firstName = "";
  String _lastName = "";
  String _email = "";
  String _address = "";
  String _phoneNumber = "";
  String _profileImage = "";
  File? _selectedImage;
  bool _isEditing = false;
  bool _isLoading = false;
  int? _userId;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController =
      TextEditingController(text: "●●●●●●●●");

  final Color _purple = const Color(0xFF804692);
  final Color _green = const Color(0xFF6DC24B);
  final Color _chipBg = const Color(0xFFF6F6F6);

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchData();
  }

  Future<void> _loadUserIdAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString("user");
    if (userString != null) {
      try {
        final userMap = jsonDecode(userString);
        setState(() {
          _userId = userMap['id'];
          _profileImage = userMap['image'] ?? "";
        });
        if (_userId != null) {
          await _fetchUserDataFromServer(_userId!);
        }
      } catch (e) {
        debugPrint("Prefs decode error: $e");
      }
    }
  }

  Future<void> _fetchUserDataFromServer(int userId) async {
    setState(() => _isLoading = true);
    try {
      final url =
          'https://churppy.eurekawebsolutions.com/api/user.php?id=$userId';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          final user = responseData['data'];
          setState(() {
            _firstName = user['first_name'] ?? "";
            _lastName = user['last_name'] ?? "";
            _email = user['email'] ?? "";
            _address = user['address'] ?? "";
            _phoneNumber = user['phone_number'] ?? "";
            _profileImage = user['image'] ?? "";

            _firstNameController.text = _firstName;
            _lastNameController.text = _lastName;
            _emailController.text = _email;
            _addressController.text = _address;
            _phoneController.text = _phoneNumber;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading profile: $e")),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      debugPrint("Pick error: $e");
    }
  }

  Future<void> _saveUserData() async {
    if (_userId == null) return;
    setState(() => _isLoading = true);
    try {
      final url =
          Uri.parse('https://churppy.eurekawebsolutions.com/api/user.php');
      final req = http.MultipartRequest('POST', url);
      req.fields['id'] = _userId.toString();
      req.fields['first_name'] = _firstNameController.text;
      req.fields['last_name'] = _lastNameController.text;
      req.fields['email'] = _emailController.text;
      req.fields['address'] = _addressController.text;
      req.fields['phone_number'] = _phoneController.text;

      if (_passwordController.text.isNotEmpty &&
          _passwordController.text != "●●●●●●●●") {
        req.fields['password'] = _passwordController.text;
      }

      if (_selectedImage != null) {
        req.files.add(
            await http.MultipartFile.fromPath('image', _selectedImage!.path));
      }

      final res = await req.send();
      final body = await res.stream.bytesToString();
      final jsonRes = jsonDecode(body);

      if (res.statusCode == 200 && jsonRes['status'] == 'success') {
        setState(() {
          _profileImage = jsonRes['image'] ?? _profileImage;
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
      }
    } catch (e) {
      debugPrint("Save error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: _green),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _purple,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                       IconButton(
  icon: const Icon(Icons.settings, color: Colors.white, size: 22),
  onPressed: () {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.settings, color: Color(0xFF804692), size: 40),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                "Settings",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF804692),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Privacy Policy
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined,
                  color: Colors.black87),
              title: const Text("Privacy Policy"),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    title: const Text("Privacy Policy",
                        style: TextStyle(
                            color: Color(0xFF804692),
                            fontWeight: FontWeight.bold)),
                    content: const Text(
                      "We value your privacy. Your personal data such as name, "
                      "email, and location are used only for improving your "
                      "Churppy experience. We do not share your information with "
                      "any third party. For detailed terms, please visit our "
                      "Privacy Policy section in the app settings.",
                      style: TextStyle(fontSize: 14, height: 1.4),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          "OK",
                          style: TextStyle(
                              color: Color(0xFF804692),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // About App
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.black87),
              title: const Text("About App"),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    title: const Text("About Churppy",
                        style: TextStyle(
                            color: Color(0xFF804692),
                            fontWeight: FontWeight.bold)),
                    content: const Text(
                      "Churppy is your trusted food discovery app — helping you "
                      "find nearby food trucks, restaurants, cafés, and deals. "
                      "We aim to connect customers with the best local dining "
                      "experiences, ensuring freshness, convenience, and joy.\n\n"
                      "Version: 1.0.0\n© 2025 Churppy.",
                      style: TextStyle(fontSize: 14, height: 1.4),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          "Close",
                          style: TextStyle(
                              color: Color(0xFF804692),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          
            ListTile(
              leading: const Icon(Icons.contact_support_outlined, 
                  color: Colors.black87),
              title: const Text("Contact Us"),
              onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => ContactUsScreen()),
  );
},

            ),

            const SizedBox(height: 10),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF804692),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                icon: const Icon(Icons.check, color: Colors.white),
                label:
                    const Text("Done", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  },
),

                      ],
                    ),
                  ),

                  // profile image
                  GestureDetector(
                    onTap: _isEditing ? _pickImage : null,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _green, width: 3),
                        boxShadow: [
                          BoxShadow(
                              color: _green.withOpacity(0.5),
                              blurRadius: 14,
                              spreadRadius: 1),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundImage: _getProfileImage(),
                        backgroundColor: Colors.grey[300],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Text(
                    "${_firstName.trim()} ${_lastName.trim()}",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(_email,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14)),

                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _labeledField("Name",
                                controller: _firstNameController, hint: "Name"),
                            _labeledField("Email",
                                controller: _emailController,
                                hint: "email@churppy.com"),
                            _labeledField("Address",
                                controller: _addressController,
                                hint: "Your address"),
                            _passwordField(),
                            const SizedBox(height: 6),
                            const Divider(),
                            _sectionHeader(
                                title: "CHURPPY CREDITS + DETAILS",
                                color: _purple),
                            const SizedBox(height: 6),

                            _listButton("Payment Details", Icons.credit_card),
                            _listButton("Order History", Icons.receipt_long,
                                isOrderHistory: true),

                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      if (_isEditing) {
                                        _saveUserData();
                                      } else {
                                        setState(() => _isEditing = true);
                                      }
                                    },
                                    icon: Icon(
                                        _isEditing ? Icons.save : Icons.edit,
                                        size: 18),
                                    label: Text(
                                        _isEditing ? "Save" : "Edit Profile"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _purple,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14, horizontal: 16),
                                      shape: const StadiumBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _confirmLogout,
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: _green, width: 2),
                                      shape: const StadiumBorder(),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14, horizontal: 16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text("Log out",
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: _green,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 18,
                                              color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (_selectedImage != null) return FileImage(_selectedImage!);
    if (_profileImage.isNotEmpty && _profileImage.startsWith("http")) {
      return NetworkImage(_profileImage);
    }
    return null;
  }

  Widget _labeledField(String label,
      {required TextEditingController controller, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            enabled: _isEditing,
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              filled: true,
              fillColor: _chipBg,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Password",
              style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordController,
            enabled: _isEditing,
            obscureText: true,
            decoration: InputDecoration(
              hintText:
                  _isEditing ? "Enter new password (optional)" : "●●●●●●●●",
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              filled: true,
              fillColor: _chipBg,
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({required String title, Color? color}) {
    return Row(
      children: [
        Expanded(
          child: Text(title,
              style: TextStyle(
                  color: color ?? Colors.black87,
                  fontWeight: FontWeight.w800)),
        ),
        Icon(Icons.chevron_right, color: color ?? Colors.black87, size: 22),
      ],
    );
  }

  Widget _listButton(String title, IconData icon,
      {bool isOrderHistory = false}) {
    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: _purple, size: 20),
          title: Text(title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          trailing:
              const Icon(Icons.chevron_right, size: 20, color: Colors.black54),
          onTap: () {
            if (isOrderHistory) {
              Navigator.push(context, MaterialPageRoute(builder: (context)=>OrdersHistoryScreen()),);
              
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PaymentDetailsScreen()),
              );
            }
          },
        ),
        const Divider(height: 0),
      ],
    );
  }
}
