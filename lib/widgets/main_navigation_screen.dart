import 'package:flutter/material.dart';
import 'churppy_navbar.dart';
import 'package:churppy_customer/screens/home_screen.dart';
import 'package:churppy_customer/screens/profile.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const ProfileScreen(),
    // const OrdersScreen(),
    // const FavoritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_currentIndex],



      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6C2FA0),
        onPressed: () {
          // FAB pressed logic
          showDialog(
            context: context,
            builder: (_) => const AlertDialog(
              title: Text("FAB Pressed"),
              content: Text("You tapped the center button!"),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}