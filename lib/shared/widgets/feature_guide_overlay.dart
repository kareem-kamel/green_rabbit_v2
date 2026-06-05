import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum GuideType { general, calculator, alerts, ai }

class FeatureGuideOverlay extends StatefulWidget {
  final VoidCallback onDismiss;
  final GuideType type;

  const FeatureGuideOverlay({
    super.key, 
    required this.onDismiss,
    this.type = GuideType.general,
  });

  @override
  State<FeatureGuideOverlay> createState() => _FeatureGuideOverlayState();
}

class _FeatureGuideOverlayState extends State<FeatureGuideOverlay> {
  int _currentStep = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _steps {
    switch (widget.type) {
      case GuideType.calculator:
        return [
          {
            'title': 'Forex Profit Calculator',
            'description': 'Calculate potential profits for Forex trades by entering instrument, prices, and lot size.',
            'icon': 'attach_money',
          },
        ];
      case GuideType.alerts:
        return [
          {
            'title': 'Price Alerts',
            'description': 'Get notified exactly when an asset hits your target buy or sell price.',
            'icon': 'attach_money',
          },
          {
            'title': 'Volatility Alerts',
            'description': 'Use "Charge %" alerts to track sudden market moves and price jumps.',
            'icon': 'bolt',
          },
          {
            'title': 'Volume Tracking',
            'description': 'Monitor unusual trading activity to spot institutional moves early.',
            'icon': 'bar_chart',
          },
        ];
      case GuideType.ai:
        return [
          {
            'title': 'AI Assistant',
            'description': 'Ask questions about any asset, technical indicator, or market news.',
            'icon': 'psychology',
          },
          {
            'title': 'Smart Summaries',
            'description': 'Get instant TL;DRs of complex financial reports and breaking news.',
            'icon': 'summarize',
          },
          {
            'title': 'Pattern Detection',
            'description': 'Our AI identifies repeating market patterns to help you spot opportunities.',
            'icon': 'auto_awesome',
          },
        ];
      case GuideType.general:
      default:
        return [
          {
            'title': 'Global Calculator',
            'description': 'Access the forex profit calculator from any page. Just swipe from the right edge!',
            'icon': 'calculate_outlined',
          },
          {
            'title': 'Smart Price Alerts',
            'description': 'Set alerts for price, percentage changes, or volume. Never miss a move.',
            'icon': 'notifications_active_outlined',
          },
          {
            'title': 'AI Market Insights',
            'description': 'Get summaries and pattern detection powered by AI to trade smarter.',
            'icon': 'psychology_outlined',
          },
        ];
    }
  }

  Widget _buildCalculatorPreview() {
    return SizedBox(
      height: 150,
      width: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Button
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPurple.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.calculate_outlined, color: Colors.white, size: 36),
          ),
          // The Animated Arrow
          const _AnimatedSwipeHint(),
          // Another persistent arrow for clarity
          const Positioned(
            right: 10,
            child: Icon(Icons.arrow_back_ios_rounded, color: Colors.white24, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryPurple.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primaryPurple.withOpacity(0.5)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'swipe': return Icons.swipe_left_rounded;
      case 'search': return Icons.search;
      case 'calculate': return Icons.calculate;
      case 'trending_up': return Icons.trending_up;
      case 'attach_money': return Icons.attach_money;
      case 'bolt': return Icons.bolt;
      case 'bar_chart': return Icons.bar_chart;
      case 'psychology': return Icons.psychology;
      case 'summarize': return Icons.summarize;
      case 'auto_awesome': return Icons.auto_awesome;
      case 'calculate_outlined': return Icons.calculate_outlined;
      case 'notifications_active_outlined': return Icons.notifications_active_outlined;
      case 'psychology_outlined': return Icons.psychology_outlined;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    return Material(
      color: Colors.black.withOpacity(0.9),
      child: Stack(
        children: [
          // Scrollable Content
          PageView.builder(
            controller: _pageController,
            itemCount: steps.length,
            onPageChanged: (index) {
              setState(() => _currentStep = index);
            },
            itemBuilder: (context, index) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_currentStep < steps.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    widget.onDismiss();
                  }
                },
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (steps[index]['icon'] == 'swipe')
                        _buildCalculatorPreview()
                      else
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPurple.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryPurple.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _getIcon(steps[index]['icon']!),
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          steps[index]['title']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          steps[index]['description']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Indicators & Controls
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    steps.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: index == _currentStep ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: index == _currentStep 
                            ? AppColors.primaryPurple 
                            : Colors.white24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_currentStep > 0)
                      _buildNavButton(Icons.chevron_left, () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }),
                    const SizedBox(width: 16),
                    Text(
                      _currentStep == steps.length - 1 
                          ? 'FINISH' 
                          : 'NEXT',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (_currentStep < steps.length - 1)
                      _buildNavButton(Icons.chevron_right, () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _currentStep == 0 ? 'SWIPE TO EXPLORE' : '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Skip Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: TextButton(
              onPressed: widget.onDismiss,
              child: const Text(
                'SKIP',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedSwipeHint extends StatefulWidget {
  const _AnimatedSwipeHint();

  @override
  State<_AnimatedSwipeHint> createState() => _AnimatedSwipeHintState();
}

class _AnimatedSwipeHintState extends State<_AnimatedSwipeHint> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _positionAnimation = Tween<double>(begin: 0.0, end: 30.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          right: 10 + _positionAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "SWIPE", 
                  style: TextStyle(
                    color: AppColors.primaryPurple, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                Icon(Icons.arrow_back_ios_rounded, color: AppColors.primaryPurple, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
