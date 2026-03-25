import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'news/news_screen.dart';
import 'news/chatbot_screen.dart'; // Ensure this import is here

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 2; // Default to News tab

  final List<Widget> _screens = [
    const Center(child: Text("Market Screen", style: TextStyle(color: Colors.white))),
    const Center(child: Text("Watchlist Screen", style: TextStyle(color: Colors.white))),
    const NewsScreen(),
    const Center(child: Text("Calendar Screen", style: TextStyle(color: Colors.white))),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: _screens[_selectedIndex],

      // 1. ADD THE PURPLE AI BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatBotScreen()),
          );
        },
        backgroundColor: const Color(0xFF8B5CF6), // Your purple color
        shape: const CircleBorder(),
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),

      // 2. CENTER THE BUTTON
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.navBarBg,
          border: Border(
            top: BorderSide(color: Colors.white10, width: 0.5),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.bar_chart_outlined, "Market", 0),
                _buildNavItem(Icons.bookmark_border, "Watchlist", 1),
                
                // 3. THE GAP FOR THE BUTTON
                const SizedBox(width: 48), 
                
                _buildNavItem(Icons.newspaper_outlined, "News", 2),
                _buildNavItem(Icons.calendar_today_outlined, "Calendar", 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? Colors.white : AppColors.textGrey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.textGrey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}