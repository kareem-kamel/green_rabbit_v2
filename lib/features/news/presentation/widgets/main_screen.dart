import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../screens/news_screen.dart';
import '../../../chatbot/presentation/screens/chatbot_screen.dart';
import '../../../../core/widgets/bottom_nav_bar.dart';

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
    // Dedicated Chat tab (selected via the center Rabbit button)
    const ChatBotScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: _screens[_selectedIndex],

      floatingActionButton: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatBotScreen(startEmpty: true),
            ),
          );
        },
        child: Transform.translate(
          offset: const Offset(0, -1), // push slightly downward
          child: SizedBox(
            width: 72,
            height: 72,
            child: Center(
              child: Image.asset(
                'assets/icons/rabbiticonAI.png',
                width: 68,
                height: 68,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        items: buildBottomNavAssets(const [
          ('assets/icons/market.png', 'Market'),
          ('assets/icons/watchlist.png', 'Watchlist'),
          ('assets/icons/news.png', 'News'),
          ('assets/icons/Calendar.png', 'Calendar'),
        ]),
        fabGapWidth: 64,
      ),
    );
  }

  // Removed local _buildNavItem in favor of reusable BottomNavBar
}