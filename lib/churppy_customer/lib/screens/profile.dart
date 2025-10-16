import 'dart:convert';
import 'dart:io';
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
  // Data
  String _firstName = "";
  String _lastName = "";
  String _email = "";
  String _address = "";
  String _phoneNumber = "";
  String _password = "●●●●●●●●"; // display only
  String _profileImage = "";
  File? _selectedImage;
  bool _isEditing = false;
  bool _isLoading = false;
  int? _userId;

  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController =
  TextEditingController(text: "●●●●●●●●"); // static look

  // Theme tokens
  final Color _purple = const Color(0xFF804692);
  final Color _green = const Color(0xFF6DC24B);
  final Color _chipBg = const Color(0xFFF6F6F6);

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchData();
  }

  /// ✅ Load userId then fetch profile
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

  /// ✅ Fetch from backend
  Future<void> _fetchUserDataFromServer(int userId) async {
    setState(() => _isLoading = true);
    try {
      final url = 'https://churppy.eurekawebsolutions.com/api/user.php?id=$userId';
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

  /// ✅ Pick + Upload image
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
        await _uploadImageToServer(_selectedImage!);
      }
    } catch (e) {
      debugPrint("Pick error: $e");
    }
  }

  Future<void> _uploadImageToServer(File imageFile) async {
    if (_userId == null) return;
    setState(() => _isLoading = true);
    try {
      final req = http.MultipartRequest(
        'POST',
        Uri.parse('https://churppy.eurekawebsolutions.com/api/user.php'),
      );
      req.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      req.fields['id'] = _userId.toString();

      final res = await req.send();
      final body = await res.stream.bytesToString();
      final jsonRes = jsonDecode(body);

      if (res.statusCode == 200 && jsonRes['status'] == 'success') {
        setState(() => _profileImage = jsonRes['imageUrl']);
      }
    } catch (e) {
      debugPrint("Upload error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ✅ Save (multipart)
  Future<void> _saveUserData() async {
    if (_userId == null) return;
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse('https://churppy.eurekawebsolutions.com/api/user.php');
      final req = http.MultipartRequest('POST', url);
      req.fields['id'] = _userId.toString();
      req.fields['first_name'] = _firstNameController.text;
      req.fields['last_name'] = _lastNameController.text;
      req.fields['email'] = _emailController.text;
      req.fields['address'] = _addressController.text;
      req.fields['phone_number'] = _phoneController.text;

      if (_selectedImage != null) {
        req.files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));
      }

      final res = await req.send();
      final body = await res.stream.bytesToString();
      final jsonRes = jsonDecode(body);

      if (res.statusCode == 200 && jsonRes['status'] == 'success') {
        setState(() {
          _profileImage = jsonRes['image'] ?? _profileImage;
          _isEditing = false;
        });
      } else {
        debugPrint("Update failed: ${jsonRes['message']}");
      }
    } catch (e) {
      debugPrint("Save error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ✅ Logout
  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
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

  /// ===== UI =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _purple,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white, size: 20),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Profile image with neon-green border/glow
            GestureDetector(
              onTap: _isEditing ? _pickImage : null,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _green, width: 3),
                  boxShadow: [
                    BoxShadow(color: _green.withOpacity(0.5), blurRadius: 14, spreadRadius: 1),
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
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(_email, style: const TextStyle(color: Colors.white, fontSize: 14)),

            // Card body
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30), topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Fields — styled like screenshot
                      _labeledField("Name",
                          controller: _firstNameController,
                          hint: "Name",
                          trailing: _lastNameController.text.isNotEmpty
                              ? null
                              : null,
                          // combine visually: show first name; keep last name value appended on save
                          onChanged: (v) {}),
                      _labeledField("Email",
                          controller: _emailController, hint: "email@churppy.com"),
                      _labeledField("Delivery address",
                          controller: _addressController, hint: "Your address"),
                      _passwordField(),

                      const SizedBox(height: 6),
                      const Divider(),

                      // ===== Static section (as requested) =====
                      _sectionHeader(
                        title: "CHURPPY CREDITS + DETAILS",
                        color: _purple,
                      ),
                      const SizedBox(height: 6),
                      _staticRow("Payment Details"),
                      _staticRow("Order history"),
                      // ========================================

                      const SizedBox(height: 14),

                      // Bottom two buttons – functional and styled
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (_isEditing) {
                                  // If you keep separate last name field internally, append before save:
                                  _firstNameController.text =
                                      _firstNameController.text.trim();
                                  _lastNameController.text =
                                      _lastNameController.text.trim();
                                  _saveUserData();
                                } else {
                                  setState(() => _isEditing = true);
                                }
                              },
                              icon: Icon(_isEditing ? Icons.save : Icons.edit, size: 18),
                              label: Text(_isEditing ? "Save" : "Edit Profile"),
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
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.arrow_forward_rounded,
                                        size: 18, color: Colors.white),
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

  /// ===== Helpers =====

  ImageProvider _getProfileImage() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    } else if (_profileImage.isNotEmpty && _profileImage.startsWith("http")) {
      return NetworkImage(_profileImage);
    } else {
      return const AssetImage("assets/images/profile_pic.png");
    }
  }

  // Label + rounded filled TextField (screenshot style)
  Widget _labeledField(
      String label, {
        required TextEditingController controller,
        String? hint,
        Widget? trailing,
        void Function(String)? onChanged,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: _isEditing,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    hintText: hint,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                    filled: true,
                    fillColor: _chipBg,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ]
            ],
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
              style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextField(
            controller: _passwordController,
            enabled: false, // static for now
            obscureText: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outlined, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
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
          child: Text(
            title,
            style: TextStyle(
              color: color ?? Colors.black87,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Icon(Icons.chevron_right, color: color ?? Colors.black87, size: 22),
      ],
    );
  }

  Widget _staticRow(String title) {
    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(title, style: const TextStyle(fontSize: 14)),
          trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.black54),
          // onTap: () {}, // static for now
        ),
        const Divider(height: 0),
      ],
    );
  }
}
