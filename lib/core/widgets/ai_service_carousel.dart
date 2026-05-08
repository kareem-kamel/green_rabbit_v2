import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AIServiceCarousel extends StatefulWidget {
  final Function(int)? onItemTap;
  const AIServiceCarousel({super.key, this.onItemTap});

  @override
  State<AIServiceCarousel> createState() => _AIServiceCarouselState();
}

class _AIServiceCarouselState extends State<AIServiceCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _items = [
    {
      'title': 'AI Trading Assistant',
      'desc': 'Understand prices, indicators, and news with AI-powered explanations',
      'image': 'assets/component_1.png',
    },
    {
      'title': 'AI News Summaries',
      'desc': 'Turns complex financial news into short, easy-to-read insights',
      'image': 'assets/component_2.png',
    },
    {
      'title': 'Watchlist Insights',
      'desc': 'Summarizes key changes across your tracked assets',
      'image': 'assets/component_3.png',
    },
    {
      'title': 'Market Pattern Detection',
      'desc': 'Identifies repeating patterns and notable market behavior',
      'image': 'assets/component_4.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return GestureDetector(
                onTap: () => widget.onItemTap?.call(index),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 28), // Increased bottom padding for dots
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: Theme.of(context).brightness == Brightness.dark 
                          ? [const Color(0xFF2E246A), const Color(0xFF1B1839)]
                          : [AppColors.primaryPurple, const Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          item['image'],
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'],
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['desc'],
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.4),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_items.length, (index) {
              final bool isActive = _currentIndex == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isActive ? 20 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
