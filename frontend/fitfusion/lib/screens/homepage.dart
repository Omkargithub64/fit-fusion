import 'package:fitfusion/screens/bottomnavigation.dart';
import 'package:fitfusion/screens/leaderboard.dart';
import 'package:fitfusion/screens/outfitgen.dart';
import 'package:fitfusion/screens/profile/profile.dart';
import 'package:fitfusion/screens/social.dart';
import 'package:fitfusion/screens/wardrobe.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedPage = 0;

  // Pages for Bottom Navigation
  final List<Widget> _pages = [
    const Social(),
    const Wardrobe(),
    const Outfitgen(),
    const LeaderboardScreen(),
    UserImageScreen(),
  ];

  // Helper function for creating smooth transitions
  Widget _buildPageView() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: _pages[_selectedPage],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // AppBar Design
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Fit Fusion',
          style: TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7C7EEB),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.2),
        centerTitle: true,
      ),

      // Display selected page
      body: _buildPageView(),

      // Custom Bottom Navigation Bar
      bottomNavigationBar: BottomNavigation(
        selectedPage: _selectedPage,
        onPageChanged: (index) {
          setState(() {
            _selectedPage = index;
          });
        },
      ),
    );
  }
}
