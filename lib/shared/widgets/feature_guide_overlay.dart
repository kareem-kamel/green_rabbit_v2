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

  List<Map<String, String>> get _steps {
    switch (widget.type) {
      case GuideType.calculator:
        return [
          {
            'title': 'Stock Calculator',
            'description': 'Search for any stock to calculate potential returns based on share count and expected growth.',
            'icon': 'search',
          },
          {
            'title': 'Standard Calculator',
            'description': 'Plan your general investments by adjusting principal, rates, and time periods.',
            'icon': 'calculate',
          },
          {
            'title': 'Compound Growth',
            'description': 'Visualize how your money grows over time with our detailed projection cards.',
            'icon': 'trending_up',
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
            'description': 'Access the investment calculator from any page. Just swipe from the right edge!',
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

  IconData _getIcon(String iconName) {
    switch (iconName) {
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
      color: Colors.black.withOpacity(0.85),
      child: InkWell(
        onTap: () {
          if (_currentStep < steps.length - 1) {
            setState(() => _currentStep++);
          } else {
            widget.onDismiss();
          }
        },
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Column(
                        key: ValueKey('${widget.type}_$_currentStep'),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primaryPurple.withOpacity(0.5), width: 2),
                            ),
                            child: Icon(
                              _getIcon(steps[_currentStep]['icon']!),
                              color: Colors.white,
                              size: 64,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            steps[_currentStep]['title']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            steps[_currentStep]['description']!,
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
                    const SizedBox(height: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        steps.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == _currentStep ? AppColors.primaryPurple : Colors.white24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  _currentStep == steps.length - 1 ? 'TAP TO FINISH' : 'TAP TO CONTINUE',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
