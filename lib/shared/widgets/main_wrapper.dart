import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';
import 'package:green_rabbit/features/chatbot/presentation/screens/chatbot_screen.dart';
import 'package:green_rabbit/features/news/presentation/screens/news_screen.dart';
import '../../features/market/presentation/pages/market_page.dart';
import '../../features/watchlist/presentation/pages/watchlist_page.dart';

// Provider to manage the current bottom nav index
final navigationIndexProvider = StateProvider<int>((ref) => 0);

class MainWrapper extends ConsumerWidget {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);

    final pages = [
      const MarketPage(),
      const WatchlistPage(),
      const ChatBotScreen(), // Placeholder for FAB action
      const NewsScreen(),
      const Center(child: Text('Calendar')),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          if (index == 2) return; // Central FAB handling
          ref.read(navigationIndexProvider.notifier).state = index;
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).cardColor,
        selectedItemColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : AppColors.primaryPurple,
        unselectedItemColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey
            : Colors.black45,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12, // Match font size for consistency
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : AppColors.primaryPurple,
        ),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            label: 'Watchlist',
          ),
          BottomNavigationBarItem(icon: SizedBox.shrink(), label: ''),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            label: 'News',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Calendar',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatBotScreen(startEmpty: true),
            ),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
          ),
          child: Image.asset('assets/ai.png', fit: BoxFit.contain),
        ),
      ),
      floatingActionButtonLocation: const _FixedCenterDockedFabLocation(),
    );
  }
}

class _FixedCenterDockedFabLocation extends FloatingActionButtonLocation {
  const _FixedCenterDockedFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = (scaffoldGeometry.scaffoldSize.width - scaffoldGeometry.floatingActionButtonSize.width) / 2.0;
    
    // We use a fixed estimate for the navigation bar height (usually ~80 with labels)
    // to avoid using the undefined bottomNavigationBarSize getter.
    final double fabHeight = scaffoldGeometry.floatingActionButtonSize.height;
    final double bottomPadding = scaffoldGeometry.minInsets.bottom;
    
    // 56 is the standard BottomNavigationBar height, plus the bottom padding (safe area)
    final double y = scaffoldGeometry.scaffoldSize.height - (56.0 + bottomPadding);
    
    return Offset(fabX, y - (fabHeight / 2));
  }
}
