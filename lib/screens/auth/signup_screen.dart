import 'dart:convert';
import 'package:churppy_customer/screens/home_screen.dart';
import 'package:churppy_customer/screens/otp_verify.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:country_picker/country_picker.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geocoding/geocoding.dart';

import 'login.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool isLoading = false;
  Country? selectedCountry;
  String? userCountryCode;

  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController firstNameCtrl = TextEditingController();
  final TextEditingController lastNameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();

  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    selectedCountry = Country(
      phoneCode: '1',
      countryCode: 'US',
      e164Sc: 0,
      geographic: true,
      level: 1,
      name: 'United States',
      example: '',
      displayName: 'United States',
      displayNameNoCountryCode: 'United States',
      e164Key: '',
    );
    _detectUserCountry();
  }

  /// 🌍 Detect user's country based on GPS
  Future<void> _detectUserCountry() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      List<Placemark> placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);

      if (placemarks.isNotEmpty) {
        final countryCode = placemarks.first.isoCountryCode ?? "US";
        final countryName = placemarks.first.country ?? "United States";

        setState(() {
          userCountryCode = countryCode;
          selectedCountry = Country.tryParse(countryCode);
        });

        debugPrint("🌎 Detected Country: $countryName ($countryCode)");
      }
    } catch (e) {
      debugPrint("⚠️ Country detection failed: $e");
    }
  }

  /// 🧭 Fetch address suggestions from OpenStreetMap, filtered by user country
  Future<List<Map<String, dynamic>>> fetchSuggestions(String query) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (query.isEmpty) return [];

    String countryFilter =
        (userCountryCode != null) ? "&countrycodes=${userCountryCode!.toLowerCase()}" : "";

    final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=6$countryFilter');

    final resp = await http.get(uri, headers: {
      'User-Agent': 'ChurppyApp/1.0 (support@churppy.com)',
    });

    if (resp.statusCode == 200) {
      final List data = json.decode(resp.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      return [];
    }
  }

  /// 📍 Use current location and fill in address
  Future<void> useCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Location permissions are permanently denied')),
      );
      return;
    }

    Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    List<Placemark> placemarks =
        await placemarkFromCoordinates(pos.latitude, pos.longitude);

    if (placemarks.isNotEmpty) {
      final address = placemarks.first;
      final readableAddress =
          "${address.street ?? ''}, ${address.locality ?? ''}, ${address.administrativeArea ?? ''}, ${address.postalCode ?? ''}";

      setState(() {
        addressCtrl.text = readableAddress;
        userCountryCode = address.isoCountryCode ?? "US";
      });
    }

    debugPrint("📍 Current Location: ${pos.latitude},${pos.longitude}");
  }

  bool _validateInputs() {
    _errors.clear();

    if (firstNameCtrl.text.trim().isEmpty) {
      _errors['firstName'] = "First name is required";
    }
    if (lastNameCtrl.text.trim().isEmpty) {
      _errors['lastName'] = "Last name is required";
    }
    if (emailCtrl.text.trim().isEmpty) {
      _errors['email'] = "Email is required";
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailCtrl.text.trim())) {
      _errors['email'] = "Enter a valid email";
    }
    if (passwordCtrl.text.trim().isEmpty) {
      _errors['password'] = "Password is required";
    } else if (passwordCtrl.text.trim().length < 6) {
      _errors['password'] = "Password must be at least 6 characters";
    }
    if (addressCtrl.text.trim().isEmpty) {
      _errors['address'] = "Address is required";
    }
    if (phoneCtrl.text.trim().isEmpty) {
      _errors['phone'] = "Phone number is required";
    }

    setState(() {});
    return _errors.isEmpty;
  }

  /// 🔐 Signup + Session handling + Redirect to HomeScreen
  Future<void> _signup() async {
  if (!_validateInputs()) return;

  setState(() => isLoading = true);

  final url = Uri.parse("https://churppy.eurekawebsolutions.com/api/send_otp.php");

  // ✅ CORRECTED FIELD NAMES TO MATCH PHP
  final requestBody = {
    "firstname": firstNameCtrl.text.trim(),
    "lastname": lastNameCtrl.text.trim(),
    "email": emailCtrl.text.trim(),
    "password": passwordCtrl.text.trim(),
    "user_phone": "+${selectedCountry?.phoneCode ?? '1'}${phoneCtrl.text.trim()}", // ✅ CHANGED: phone → user_phone
    "address": addressCtrl.text.trim(),
  };

  try {
    final response = await http.post(url, body: requestBody);
    final result = json.decode(response.body);

    print("📩 SEND OTP Request Body: $requestBody");
    print("📩 SEND OTP Response: ${response.body}");

    if (result['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ OTP sent to your email")),
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OTPVerifyScreen(
            firstname: firstNameCtrl.text.trim(),
            lastname: lastNameCtrl.text.trim(),
            phone: "+${selectedCountry?.phoneCode ?? '1'}${phoneCtrl.text.trim()}",
            email: emailCtrl.text.trim(),
            password: passwordCtrl.text.trim(),
            address: addressCtrl.text.trim(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ ${result['message']}")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("⚠️ Error: $e")),
    );
  } finally {
    setState(() => isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final maxCardW = w.clamp(320.0, 440.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxCardW),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: maxCardW * 0.5,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _field("First Name", firstNameCtrl,
                                error: _errors['firstName']),
                            _field("Last Name", lastNameCtrl,
                                error: _errors['lastName']),
                            _field("Email", emailCtrl, error: _errors['email']),
                            _field("Password", passwordCtrl,
                                obscure: true, error: _errors['password']),

                            // 🏠 Address field (shortened suggestions)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TypeAheadField<Map<String, dynamic>>(
                                controller: addressCtrl,
                                suggestionsCallback: fetchSuggestions,
                                builder: (context, controller, focusNode) {
                                  return TextField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    decoration: InputDecoration(
                                      hintText: 'Enter Address',
                                      errorText: _errors['address'],
                                      suffixIcon: IconButton(
                                        icon:
                                            const Icon(Icons.my_location_rounded),
                                        onPressed: useCurrentLocation,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 12),
                                    ),
                                  );
                                },

                                // ✅ Simplified address display
                                itemBuilder: (context, suggestion) {
                                  final address = suggestion['address'] ?? {};
                                  final parts = [
                                    address['road'],
                                    address['city'],
                                    address['state'],
                                    address['postcode'],
                                  ].where((e) =>
                                      e != null &&
                                      e.toString().trim().isNotEmpty).toList();

                                  final shortAddress = parts.join(", ");

                                  return ListTile(
                                    title: Text(
                                      shortAddress.isNotEmpty
                                          ? shortAddress
                                          : (suggestion['display_name'] ??
                                              ''),
                                    ),
                                  );
                                },
                                onSelected: (suggestion) {
                                  final address = suggestion['address'] ?? {};
                                  final parts = [
                                    address['road'],
                                    address['city'],
                                    address['state'],
                                    address['postcode'],
                                  ].where((e) =>
                                      e != null &&
                                      e.toString().trim().isNotEmpty).toList();
                                  addressCtrl.text = parts.join(", ");
                                },
                                emptyBuilder: (context) =>
                                    const ListTile(
                                        title: Text('No results found')),
                              ),
                            ),

                            const Text(
                              'Enter your mobile number',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),

                            // 📱 Phone field
                            Row(
                              children: [
                                InkWell(
                                  onTap: () => _showCountryPicker(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: const Color(0xFFBDBDBD)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(selectedCountry?.flagEmoji ?? '🌎',
                                            style:
                                                const TextStyle(fontSize: 20)),
                                        const SizedBox(width: 6),
                                        Text(
                                          '+${selectedCountry?.phoneCode ?? ''}',
                                          style:
                                              const TextStyle(fontSize: 14),
                                        ),
                                        const Icon(Icons.arrow_drop_down,
                                            size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: phoneCtrl,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      hintText: 'Phone Number',
                                      errorText: _errors['phone'],
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Continue + login
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 48,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF804692),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: isLoading ? null : _signup,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child:
                                          CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Continue'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: const [
                              Expanded(child: Divider(color: Colors.grey)),
                              Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 8),
                                child: Text('or',
                                    style:
                                        TextStyle(color: Colors.black54)),
                              ),
                              Expanded(child: Divider(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const LoginScreen()),
                                );
                              },
                              child: const Text.rich(
                                TextSpan(
                                  text:
                                      'If you already have an account, ',
                                  style:
                                      TextStyle(color: Colors.black87),
                                  children: [
                                    TextSpan(
                                      text: 'login.',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          decoration: TextDecoration
                                              .underline),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 10,
              bottom: 42,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE0E0E0),
                  ),
                  child: const Icon(Icons.arrow_back, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String hint, TextEditingController ctrl,
      {bool obscure = false, String? error}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          errorText: error,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  void _showCountryPicker(BuildContext context) {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (Country country) {
        setState(() => selectedCountry = country);
      },
    );
  }
}