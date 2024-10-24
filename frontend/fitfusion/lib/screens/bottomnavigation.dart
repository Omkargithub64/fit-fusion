import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class BottomNavigation extends StatefulWidget {
  final int selectedPage;
  final Function(int) onPageChanged;

  const BottomNavigation(
      {super.key, required this.selectedPage, required this.onPageChanged});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: GNav(
          selectedIndex: widget.selectedPage,
          onTabChange: widget.onPageChanged,
          color: const Color.fromARGB(102, 81, 92, 197),
          gap: 1,
          activeColor: Theme.of(context).primaryColor,
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          tabBackgroundColor: const Color.fromARGB(255, 124, 126, 235),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(224, 255, 255, 255),
          ),
          tabs: const [
            GButton(
              icon: Icons.home_rounded,
              text: 'Home',
            ),
            GButton(
              icon: Icons.style_rounded,
              text: 'Wardrobe',
            ),
            GButton(
              icon: Icons.generating_tokens,
              text: '',
            ),
            GButton(
              icon: Icons.emoji_events_rounded,
              text: 'Rank',
            ),
            GButton(
              icon: Icons.person_rounded,
              text: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
