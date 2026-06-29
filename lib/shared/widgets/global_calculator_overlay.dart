import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../main.dart'; // To access globalNavigatorKey
import '../../features/market/presentation/providers/market_providers.dart';
import '../../features/market/data/models/market_instrument.dart';
import '../../features/market/data/repositories/market_repository_impl.dart';

import 'package:green_rabbit/shared/widgets/feature_guide_overlay.dart';
import 'package:green_rabbit/shared/widgets/main_wrapper.dart';

// Persistent state for Standard Calculator
double _globalPrincipal = 1000.0;
double _globalAnnualRate = 10.0;
int _globalMonths = 12;
bool _globalStandardIsAnnual = true;

// Persistent state for Stock Calculator
MarketInstrument? _globalSelectedStock;
double _globalStockShares = 10;
double _globalStockAnnualRate = 15.0;
int _globalStockMonths = 60;
bool _globalStockIsAnnual = true;

// Persistent state for Forex Profit Calculator
MarketInstrument? _globalForexInstrument;
bool _globalForexIsBuy = true;
double _globalForexOpenPrice = 0.0;
double _globalForexClosePrice = 0.0;
double _globalForexLots = 1.0;
String _globalForexCurrency = "USD";
double _globalForexBalance = 10000.0;

final _exchangeRatesProvider = FutureProvider<Map<String, double>>((ref) async {
  final repo = ref.watch(marketRepositoryProvider);
  final pairs = ['EURUSD', 'GBPUSD', 'USDJPY', 'USDCHF', 'AUDUSD', 'USDCAD'];
  final Map<String, double> rates = {};
  
  // Set some sensible defaults in case of network issues
  rates['EURUSD'] = 1.08;
  rates['GBPUSD'] = 1.27;
  rates['USDJPY'] = 150.0;
  rates['USDCHF'] = 0.90;
  rates['AUDUSD'] = 0.66;
  rates['USDCAD'] = 1.36;

  for (final pair in pairs) {
    try {
      final results = await repo.searchInstruments(pair);
      if (results.isNotEmpty) {
        // Try to find an exact match first
        final match = results.firstWhere(
          (element) => element.symbol.replaceAll('/', '').replaceAll('_', '').toUpperCase() == pair,
          orElse: () => results.first,
        );
        if (match.price != null) {
          rates[pair] = match.price!;
        }
      }
    } catch (e) {
      debugPrint('Error fetching rate for $pair: $e');
    }
  }
  return rates;
});

class _ContractDetails {
  final double multiplier;
  final String label;
  const _ContractDetails(this.multiplier, this.label);
}

class CalculatorRouteObserver extends NavigatorObserver {
  final List<VoidCallback> _listeners = [];
  
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }
  
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notify() {
    for (final listener in _listeners) {
      listener();
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _notify();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _notify();
  }
}

final calculatorRouteObserver = CalculatorRouteObserver();

class GlobalCalculatorOverlay extends ConsumerStatefulWidget {
  const GlobalCalculatorOverlay({super.key});

  @override
  ConsumerState<GlobalCalculatorOverlay> createState() => _GlobalCalculatorOverlayState();
}

class _GlobalCalculatorOverlayState extends ConsumerState<GlobalCalculatorOverlay> {
  double _buttonPositionX = 0.0; // X position from left (always absolute)
  double _buttonPositionY = 60.0; // Y position from bottom
  bool _isMinimized = true;
  bool _isPageOpen = false;
  bool _hasInteracted = false;
  bool _isDragging = false;
  bool _isOnLeftSide = false; // Whether button is on left or right edge
  bool _isLoaded = false; // Whether saved position has been loaded
  
  static const double _snapThreshold = 30.0;
  static const double _minimizedOffset = 20.0; // How much to tuck in when minimized
  static const double _gestureSafeMargin = 0.0; // Avoid system gesture areas
  static const String _prefsKeyX = 'calculator_button_x';
  static const String _prefsKeyY = 'calculator_button_y';
  static const String _prefsKeyMinimized = 'calculator_button_minimized';
  static const String _prefsKeyLeftSide = 'calculator_button_left_side';

  @override
  void initState() {
    super.initState();
    _loadSavedPosition();
    calculatorRouteObserver.addListener(_onRouteChanged);
  }

  Future<void> _loadSavedPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedX = prefs.getDouble(_prefsKeyX);
      final savedLeftSide = prefs.getBool(_prefsKeyLeftSide);
      
      setState(() {
        // For backward compatibility, if we have old saved data, we'll initialize properly
        if (savedX != null && savedLeftSide != null) {
          _buttonPositionX = savedX; // Always use absolute saved X
        }
        _buttonPositionY = prefs.getDouble(_prefsKeyY) ?? 60.0;
        _isMinimized = prefs.getBool(_prefsKeyMinimized) ?? true;
        _isOnLeftSide = savedLeftSide ?? false;
        _isLoaded = true;
      });
    } catch (e) {
      debugPrint('Error loading button position: $e');
      setState(() {
        _isLoaded = true;
      });
    }
  }

  Future<void> _savePosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Always save absolute left position
      await prefs.setDouble(_prefsKeyX, _buttonPositionX);
      await prefs.setDouble(_prefsKeyY, _buttonPositionY);
      await prefs.setBool(_prefsKeyMinimized, _isMinimized);
      await prefs.setBool(_prefsKeyLeftSide, _isOnLeftSide);
    } catch (e) {
        debugPrint('Error saving button position: $e');
    }
  }

  @override
  void dispose() {
    calculatorRouteObserver.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    if (mounted && !_isMinimized && !_isPageOpen) {
      // If the button is pulled out and we navigate, tuck it back in.
      setState(() {
        _isMinimized = true;
      });
    }
  }

  void _openCalculator() async {
    if (_isDragging) return;
    
    final context = globalNavigatorKey.currentContext;
    if (context == null) return;
    
    setState(() {
      _isPageOpen = true;
    });

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InvestmentCalculatorPage(),
      ),
    );

    // This runs after the page is popped
    if (mounted) {
      setState(() {
        _isPageOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(navigationIndexProvider, (previous, next) {
      if (previous != next && _isPageOpen) {
        final ctx = globalNavigatorKey.currentContext;
        if (ctx != null && Navigator.canPop(ctx)) {
          Navigator.pop(ctx);
        }
      }
    });

    if (_isPageOpen) return const SizedBox.shrink();

    final size = MediaQuery.of(context).size;
    final safePadding = MediaQuery.of(context).padding;
    final maxX = size.width - 72; // 56 button + 16 padding
    final maxY = size.height - safePadding.top - safePadding.bottom - 72;
    
    // Initialize position if not set (first run) - only after saved data is loaded
    if (_isLoaded && !_isDragging && _buttonPositionX == 0.0) {
      _buttonPositionX = _isOnLeftSide ? 0.0 : maxX;
    }

    // Calculate effective position with left/right side support
    Widget positionedChild = SafeArea(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Swap the swipe hint direction if on left side
          if (_isMinimized && !_hasInteracted)
            const _AnimatedSwipeHint(),
          const SizedBox(width: 8),
          GestureDetector(
            onPanStart: (_) {
              setState(() {
                _isDragging = true;
                if (_isMinimized) {
                  _isMinimized = false;
                  _hasInteracted = true;
                }
              });
            },
            onPanUpdate: (details) {
              setState(() {
                // Always update with absolute coordinates from left
                _buttonPositionX += details.delta.dx;
                _buttonPositionY -= details.delta.dy;
                
                // Constrain to screen bounds (with gesture safe margins)
                if (_buttonPositionX < _gestureSafeMargin) {
                  _buttonPositionX = _gestureSafeMargin;
                }
                if (_buttonPositionX > maxX - _gestureSafeMargin) {
                  _buttonPositionX = maxX - _gestureSafeMargin;
                }
                if (_buttonPositionY < 0) _buttonPositionY = 0;
                if (_buttonPositionY > maxY) _buttonPositionY = maxY;
              });
            },
            onPanEnd: (details) async {
              // Determine which side is closer based on absolute position
              bool newIsOnLeftSide = _buttonPositionX < maxX / 2;
              double newX = _buttonPositionX;
              bool shouldMinimize = false;
              
              // Check if should minimize to edge
              if (newIsOnLeftSide) {
                // Check distance to left edge
                if (_buttonPositionX < _snapThreshold + _gestureSafeMargin) {
                  shouldMinimize = true;
                  newX = _gestureSafeMargin;
                }
              } else {
                // Check distance to right edge
                if ((maxX - _buttonPositionX) < _snapThreshold + _gestureSafeMargin) {
                  shouldMinimize = true;
                  newX = maxX;
                }
              }
              
              // Snap Y to top/bottom edges
              final snapY = _calculateSnapY(size, safePadding);
              
              // Haptic feedback
              if (snapY != _buttonPositionY || shouldMinimize || newIsOnLeftSide != _isOnLeftSide) {
                HapticFeedback.lightImpact();
              }
              
              setState(() {
                _isOnLeftSide = newIsOnLeftSide;
                _buttonPositionX = newX;
                _buttonPositionY = snapY;
                _isMinimized = shouldMinimize;
                _isDragging = false;
              });
              
              await _savePosition();
            },
            child: AnimatedScale(
              scale: _isDragging ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(_isDragging ? 0.4 : 0.2),
                      blurRadius: _isDragging ? 15 : 10,
                      offset: Offset(0, _isDragging ? 6 : 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: _openCalculator,
                    child: Stack(
                      children: [
                        Align(
                          alignment: _isMinimized 
                              ? (_isOnLeftSide ? Alignment.centerRight : Alignment.centerLeft) 
                              : Alignment.center,
                          child: Padding(
                            padding: _isMinimized 
                                ? EdgeInsets.only(right: _isOnLeftSide ? 6.0 : 0, left: _isOnLeftSide ? 0 : 6.0) 
                                : EdgeInsets.zero,
                            child: Icon(
                              _isMinimized 
                                  ? (_isOnLeftSide ? Icons.chevron_right : Icons.chevron_left) 
                                  : Icons.calculate_outlined,
                              color: Colors.white,
                              size: _isMinimized ? 20 : 28,
                            ),
                          ),
                        ),
                        if (_isMinimized)
                          Positioned(
                            left: _isOnLeftSide ? null : 8,
                            right: _isOnLeftSide ? 8 : null,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: Container(
                                width: 2,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Position using either left or right depending on which side we're on
    if (_isOnLeftSide) {
      final effectiveLeft = _isMinimized ? -_minimizedOffset : _buttonPositionX;
      return AnimatedPositioned(
        duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        bottom: _buttonPositionY,
        left: effectiveLeft,
        child: positionedChild,
      );
    } else {
      // Calculate effective right position from absolute left coordinate
      final effectiveRight = _isMinimized 
          ? -_minimizedOffset 
          : maxX - _buttonPositionX;
      return AnimatedPositioned(
        duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        bottom: _buttonPositionY,
        right: effectiveRight,
        child: positionedChild,
      );
    }
  }

  double _calculateSnapY(Size size, EdgeInsets safePadding) {
    final maxY = size.height - safePadding.top - safePadding.bottom - 72;
    final distanceTop = maxY - _buttonPositionY;
    final distanceBottom = _buttonPositionY;
    
    if (distanceTop < _snapThreshold) return maxY;
    if (distanceBottom < _snapThreshold) return 0.0;
    return _buttonPositionY;
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
        return Transform.translate(
          offset: Offset(-_positionAnimation.value, 0),
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: const Material(
              color: Colors.transparent,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "SWIPE", 
                    style: TextStyle(
                      color: AppColors.primaryPurple, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 12,
                      letterSpacing: 1,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  Icon(Icons.arrow_back_ios_rounded, color: AppColors.primaryPurple, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class InvestmentCalculatorPage extends ConsumerStatefulWidget {
  const InvestmentCalculatorPage({super.key});

  @override
  ConsumerState<InvestmentCalculatorPage> createState() => _InvestmentCalculatorPageState();
}

class _InvestmentCalculatorPageState extends ConsumerState<InvestmentCalculatorPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _principalController;
  late TextEditingController _rateController;
  late TextEditingController _sharesController;
  late TextEditingController _stockRateController;

  // Forex Calculator Controllers
  late TextEditingController _forexOpenPriceController;
  late TextEditingController _forexClosePriceController;
  late TextEditingController _forexLotsController;
  late TextEditingController _forexBalanceController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _principalController = TextEditingController(text: _globalPrincipal.toInt().toString());
    _rateController = TextEditingController(text: _globalAnnualRate.toInt().toString());
    _sharesController = TextEditingController(text: _globalStockShares.toInt().toString());
    _stockRateController = TextEditingController(text: _globalStockAnnualRate.toInt().toString());

    _forexOpenPriceController = TextEditingController(text: _globalForexOpenPrice == 0 ? "" : _globalForexOpenPrice.toString());
    _forexClosePriceController = TextEditingController(text: _globalForexClosePrice == 0 ? "" : _globalForexClosePrice.toString());
    _forexLotsController = TextEditingController(text: "1");
    _forexBalanceController = TextEditingController(text: _globalForexBalance.toInt().toString());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _principalController.dispose();
    _rateController.dispose();
    _sharesController.dispose();
    _stockRateController.dispose();
    _forexOpenPriceController.dispose();
    _forexClosePriceController.dispose();
    _forexLotsController.dispose();
    _forexBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F111A) : Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.calculate, color: AppColors.primaryPurple),
            const SizedBox(width: 8),
            Text(
              "Forex Profit Calculator",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white70 : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: isDark ? Colors.white70 : Colors.black87),
            onPressed: () {
              showDialog(
                 context: context,
                 builder: (context) => FeatureGuideOverlay(
                   type: GuideType.calculator,
                   onDismiss: () => Navigator.pop(context),
                 ),
               );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: 10,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /*
              // Tab Bar
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primaryPurple,
                labelColor: AppColors.primaryPurple,
                unselectedLabelColor: Colors.grey,
                onTap: (index) => setState(() {}),
                tabs: const [
                  Tab(text: "Stock Calculator"),
                  Tab(text: "Standard Calculator"),
                ],
              ),
              const SizedBox(height: 24),

              // Tab Content
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _tabController.index == 0 ? _buildStockTab(isDark) : _buildStandardTab(isDark),
              ),
              */

              Text(
                "Forex Profit Calculator",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              _buildForexTab(isDark),
            ],
          ),
        ),
      ),
    );
  }

  void _showInstrumentPicker(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, sheetScrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131517) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Select Instrument",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Consumer(
                          builder: (context, ref, _) {
                            final sort = ref.watch(_instrumentSortProvider);
                            final sortLabels = {
                              'alphabetical': 'A-Z',
                              'price_high': 'Price High',
                              'price_low': 'Price Low',
                            };
                            return PopupMenuButton<String>(
                              onSelected: (value) {
                                final notifier = ref.read(calculatorSearchProvider.notifier);
                                final category = ref.read(_instrumentSearchCategoryProvider);
                                final query = ref.read(_instrumentSearchQueryProvider);
                                ref.read(_instrumentSortProvider.notifier).state = value;
                                notifier.refresh(category, query, value);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'alphabetical',
                                  child: Text('A-Z (Alphabetical)'),
                                ),
                                const PopupMenuItem(
                                  value: 'price_high',
                                  child: Text('Price: High to Low'),
                                ),
                                const PopupMenuItem(
                                  value: 'price_low',
                                  child: Text('Price: Low to High'),
                                ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.sort, color: isDark ? Colors.white70 : Colors.black87),
                                    const SizedBox(width: 6),
                                    Text(
                                      sortLabels[sort] ?? 'Sort',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white70 : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: const InputDecoration(
                      hintText: "Search instruments...",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.grey),
                    ),
                    onChanged: (val) {
                      Future.microtask(() {
                        final notifier = ref.read(calculatorSearchProvider.notifier);
                        final category = ref.read(_instrumentSearchCategoryProvider);
                        final sort = ref.read(_instrumentSortProvider);
                        ref.read(_instrumentSearchQueryProvider.notifier).state = val;
                        notifier.refresh(category, val, sort);
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Categories
              Container(
                height: 40,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: ["All", "Favorites", "Forex", "Crypto", "Stock", "ETF", "Commodities"].map((cat) {
                    return Consumer(builder: (context, ref, _) {
                      final selectedCategory = ref.watch(_instrumentSearchCategoryProvider);
                      final isSelected = selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              ref.read(_instrumentSearchCategoryProvider.notifier).state = cat;
                              final query = ref.read(_instrumentSearchQueryProvider);
                              final sort = ref.read(_instrumentSortProvider);
                              ref.read(calculatorSearchProvider.notifier).refresh(cat, query, sort);
                            }
                          },
                          selectedColor: AppColors.primaryPurple,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                          backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                          showCheckmark: false,
                        ),
                      );
                    });
                  }).toList(),
                ),
              ),
              
              // List
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final resultsAsync = ref.watch(calculatorSearchProvider);
                    final notifier = ref.read(calculatorSearchProvider.notifier);
                    
                    return resultsAsync.when(
                      data: (instruments) {
                        if (instruments.isEmpty) {
                          return Center(
                            child: Text(
                              "No instruments found",
                              style: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                            ),
                          );
                        }
                        return ListView.builder(
                          controller: sheetScrollController,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          itemCount: instruments.length + ((notifier.hasNext && !notifier.isLoadingMore) ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == instruments.length) {
                              if (!notifier.isLoadingMore) {
                                Future.microtask(() {
                                  notifier.loadMore();
                                });
                              }
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            
                            final instrument = instruments[index];
                            
                            return Consumer(
                              builder: (context, favoritesRef, _) {
                                final isFavorite = favoritesRef.watch(
                                  isCalculatorFavoriteProvider(instrument.id)
                                );
                                
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: instrument.logoUrl != null
                                          ? Image.network(
                                              instrument.logoUrl!,
                                              width: 24,
                                              height: 24,
                                              errorBuilder: (_, __, ___) => Icon(Icons.show_chart, color: isDark ? Colors.white.withOpacity(0.24) : Colors.black.withOpacity(0.24)),
                                            )
                                          : Icon(Icons.show_chart, color: isDark ? Colors.white.withOpacity(0.24) : Colors.black.withOpacity(0.24)),
                                    ),
                                  ),
                                  title: Text(
                                    instrument.symbol,
                                    style: TextStyle(
                                      color: isDark ? Colors.white : Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    instrument.name,
                                    style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Favorite icon (calculator-specific!)
                                      GestureDetector(
                                        onTap: () {
                                          // Toggle calculator favorite without selecting the instrument
                                          favoritesRef.read(calculatorFavoritesProvider.notifier).toggleFavorite(instrument.id);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 12.0),
                                          child: Icon(
                                            isFavorite ? Icons.star : Icons.star_border,
                                            color: isFavorite ? Colors.amber : (isDark ? Colors.white38 : Colors.black38),
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      // Price
                                      Text(
                                        instrument.price != null && instrument.price! > 0
                                            ? '\$${instrument.price!.toStringAsFixed(instrument.type.toLowerCase() == 'forex' ? 5 : 2)}'
                                            : '--',
                                        style: const TextStyle(
                                          color: AppColors.primaryPurple,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () async {
                                    setState(() {
                                      _globalForexInstrument = instrument;
                                      _globalForexOpenPrice = instrument.price ?? 0.0;
                                      _forexOpenPriceController.text = _globalForexOpenPrice.toString();
                                      
                                      // Reset close price when instrument changes
                                      _globalForexClosePrice = 0.0;
                                      _forexClosePriceController.text = '';
                                    });
                                    
                                    // Fetch full details to ensure we have the most accurate price
                                    try {
                                      final detail = await ref.read(marketRepositoryProvider).getInstrumentDetails(instrument.id);
                                      if (detail.price.current != null) {
                                        setState(() {
                                          _globalForexOpenPrice = detail.price.current!;
                                          _forexOpenPriceController.text = _globalForexOpenPrice.toString();
                                        });
                                      }
                                    } catch (e) {
                                      debugPrint('Error fetching accurate price: $e');
                                    }
                                    
                                    if (mounted) Navigator.pop(context);
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error loading instruments: $e'),
                            TextButton(
                              onPressed: () {
                                final category = ref.read(_instrumentSearchCategoryProvider);
                                final query = ref.read(_instrumentSearchQueryProvider);
                                final sort = ref.read(_instrumentSortProvider);
                                ref.read(calculatorSearchProvider.notifier).refresh(category, query, sort);
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Timer? _searchDebounce;
  void _debouncedSearch(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(_instrumentSearchQueryProvider.notifier).state = query;
    });
  }

  Widget _buildForexTab(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Instrument Search (Dropdown-like)
        Text(
          "Select Instrument",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showInstrumentPicker(isDark),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1F26) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _globalForexInstrument != null
                        ? "${_globalForexInstrument!.name} (${_globalForexInstrument!.symbol})"
                        : "e.g. EUR/USD, GBP/JPY",
                    style: TextStyle(
                      color: _globalForexInstrument != null 
                          ? (isDark ? Colors.white : Colors.black) 
                          : Colors.grey,
                    ),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white54 : Colors.black54),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Balance
        _buildInputField(
          label: "Balance",
          controller: _forexBalanceController,
          onChanged: (val) => setState(() => _globalForexBalance = double.tryParse(val) ?? 0.0),
          isDark: isDark,
        ),
        const SizedBox(height: 16),

        // Buy/Sell Side
        Text(
          "Side",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1F26) : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(2),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _globalForexIsBuy = true),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _globalForexIsBuy ? AppColors.profitGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "Buy",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _globalForexIsBuy ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _globalForexIsBuy = false),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: !_globalForexIsBuy ? AppColors.lossRed : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "Sell",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: !_globalForexIsBuy ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Prices Row
        Row(
          children: [
            Expanded(
              child: _buildInputField(
                label: "Open Price",
                controller: _forexOpenPriceController,
                onChanged: (val) => setState(() => _globalForexOpenPrice = double.tryParse(val) ?? 0.0),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInputField(
                label: "Close Price",
                controller: _forexClosePriceController,
                onChanged: (val) => setState(() => _globalForexClosePrice = double.tryParse(val) ?? 0.0),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Lots and Currency Row
        Row(
          children: [
            Expanded(
              child: _buildInputField(
                label: "Trade Size (Lots)",
                controller: _forexLotsController,
                onChanged: (val) => setState(() => _globalForexLots = double.tryParse(val) ?? 0.0),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Deposit Currency",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1F26) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _globalForexCurrency,
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF1C1F26) : Colors.white,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                        items: ["USD", "EUR", "GBP", "JPY", "CHF", "AUD", "CAD"].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _globalForexCurrency = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Results
        Consumer(
          builder: (context, ref, child) {
            // If Close Price is empty, show 0 profit
            if (_forexClosePriceController.text.trim().isEmpty || _globalForexClosePrice <= 0.0) {
              return _buildForexResultCard(0.0, isDark, _getContractDetails(_globalForexInstrument).label);
            }

            final diff = _globalForexIsBuy 
                ? (_globalForexClosePrice - _globalForexOpenPrice)
                : (_globalForexOpenPrice - _globalForexClosePrice);
            
            final contractData = _getContractDetails(_globalForexInstrument);
            double profit = diff * _globalForexLots * contractData.multiplier;
            
            // Perform Currency Conversion
            final ratesAsync = ref.watch(_exchangeRatesProvider);
            final quoteCurrency = _getQuoteCurrency(_globalForexInstrument);
            
            if (quoteCurrency != _globalForexCurrency) {
              final rates = ratesAsync.valueOrNull ?? {};
              profit = _convertCurrency(profit, quoteCurrency, _globalForexCurrency, rates);
            }
            
            return _buildForexResultCard(profit, isDark, contractData.label);
          },
        ),
      ],
    );
  }

  String _getQuoteCurrency(MarketInstrument? instrument) {
    if (instrument == null) return "USD";
    if (instrument.currency != null) return instrument.currency!.toUpperCase();
    
    final symbol = instrument.symbol.toUpperCase();
    if (symbol.contains('/')) {
      return symbol.split('/').last;
    }
    
    // Fallback: common symbols often end with the quote currency
    if (symbol.endsWith('USD')) return "USD";
    if (symbol.endsWith('EUR')) return "EUR";
    if (symbol.endsWith('GBP')) return "GBP";
    if (symbol.endsWith('JPY')) return "JPY";
    
    return "USD"; // Default to USD
  }

  double _convertCurrency(double amount, String from, String to, Map<String, double> rates) {
    if (from == to) return amount;
    
    // 1. Convert 'from' to USD
    double amountInUSD = amount;
    if (from != "USD") {
      if (from == "EUR") {
        amountInUSD = amount * (rates['EURUSD'] ?? 1.08);
      } else if (from == "GBP") amountInUSD = amount * (rates['GBPUSD'] ?? 1.27);
      else if (from == "JPY") amountInUSD = amount / (rates['USDJPY'] ?? 150.0);
      else if (from == "CHF") amountInUSD = amount / (rates['USDCHF'] ?? 0.90);
      else if (from == "AUD") amountInUSD = amount * (rates['AUDUSD'] ?? 0.66);
      else if (from == "CAD") amountInUSD = amount / (rates['USDCAD'] ?? 1.36);
    }
    
    // 2. Convert 'USD' to 'to'
    if (to == "USD") return amountInUSD;
    if (to == "EUR") return amountInUSD / (rates['EURUSD'] ?? 1.08);
    if (to == "GBP") return amountInUSD / (rates['GBPUSD'] ?? 1.27);
    if (to == "JPY") return amountInUSD * (rates['USDJPY'] ?? 150.0);
    if (to == "CHF") return amountInUSD * (rates['USDCHF'] ?? 0.90);
    if (to == "AUD") return amountInUSD / (rates['AUDUSD'] ?? 0.66);
    if (to == "CAD") return amountInUSD * (rates['USDCAD'] ?? 1.36);
    
    return amountInUSD;
  }

  // Robust Contract Size Engine
  _ContractDetails _getContractDetails(MarketInstrument? instrument) {
    if (instrument == null) return const _ContractDetails(1.0, "1 unit");

    final type = instrument.type.toLowerCase();
    final rawSymbol = instrument.symbol.toUpperCase();
    final symbol = rawSymbol.replaceAll('/', '').replaceAll('.', '').replaceAll('-', '').replaceAll('_', '');
    final name = instrument.name.toUpperCase();

    // List of standard fiat currencies to identify REAL Forex pairs
    const fiatCurrencies = ['USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD', 'CHF', 'NZD', 'ZAR', 'CNY', 'HKD', 'SGD', 'TRY', 'MXN'];

    // 1. SPECIFIC CRYPTO MAPPING (Highest Priority)
    // We check for common crypto symbols first to avoid them being mistaken for Forex
    if (symbol.contains('BTC')) return const _ContractDetails(1.0, "1 unit");
    if (symbol.contains('ETH') || name.contains('ETHEREUM')) return const _ContractDetails(5.0, "5 units");
    if (symbol.contains('BNB')) return const _ContractDetails(30.0, "30 units");
    if (symbol.contains('SOL') || symbol.contains('AVAX') || symbol.contains('AVALANCHE') || symbol.contains('DOT')) {
      return const _ContractDetails(10.0, "10 units");
    }
    if (symbol.contains('LTC') || symbol.contains('LINK') || symbol.contains('UNI')) {
      return const _ContractDetails(100.0, "100 units");
    }
    if (symbol.contains('XRP') || symbol.contains('ADA') || symbol.contains('MATIC')) {
      return const _ContractDetails(1000.0, "1,000 units");
    }
    if (symbol.contains('DOGE')) return const _ContractDetails(10000.0, "10,000 units");
    if (symbol.contains('SHIB')) return const _ContractDetails(1000000.0, "1,000,000 units");

    // 2. COMMODITIES
    if (symbol.contains('XAU') || name.contains('GOLD')) return const _ContractDetails(100.0, "100 oz");
    if (symbol.contains('XAG') || name.contains('SILVER')) return const _ContractDetails(5000.0, "5,000 oz");
    if (symbol.contains('XPT') || name.contains('PLATINUM')) return const _ContractDetails(100.0, "100 oz");
    if (symbol.contains('XPD') || name.contains('PALLADIUM')) return const _ContractDetails(100.0, "100 oz");
    if (symbol.contains('WTI') || symbol.contains('BRENT') || name.contains('OIL') || symbol.contains('CL')) return const _ContractDetails(1000.0, "1,000 barrels");
    if (symbol.contains('NG') || name.contains('GAS')) return const _ContractDetails(10000.0, "10,000 MMBtu");

    // 3. STRICT FOREX CHECK (100k Lot)
    // A pair gets 100,000 ONLY if it's exactly 6 characters and BOTH are fiat currencies.
    // This prevents "AVAXUSD" (7 chars) from ever hitting this rule.
    if (symbol.length == 6) {
      final base = symbol.substring(0, 3);
      final quote = symbol.substring(3, 6);
      if (fiatCurrencies.contains(base) && fiatCurrencies.contains(quote)) {
        return const _ContractDetails(100000.0, "100,000 units");
      }
    }

    // 4. GENERAL CATEGORY FALLBACKS
    if (type == 'crypto' || name.contains('COIN') || name.contains('TOKEN')) {
      return const _ContractDetails(1.0, "1 unit");
    }
    
    // Indices detection
    if (type == 'index' || name.contains('INDEX') || symbol.contains('US30') || 
        symbol.contains('NAS100') || symbol.contains('SPX') || symbol.contains('GER') ||
        symbol.contains('HK50') || symbol.contains('UK100')) {
      return const _ContractDetails(1.0, "1 unit");
    }

    // 5. FINAL SAFETY FALLBACK
    // If we've reached here, we DON'T trust the backend 'forex' type.
    // We default to 1.0 to avoid the "millions of dollars" error.
    return const _ContractDetails(1.0, "1 unit");
  }

  Widget _buildForexResultCard(double profit, bool isDark, String contractSize) {
    final newBalance = _globalForexBalance + profit;
    
    // Calculate risk percentage (using absolute value of profit)
    double riskPercentage = 0.0;
    if (_globalForexBalance > 0) {
      riskPercentage = (profit.abs() / _globalForexBalance) * 100;
    }
    
    // Determine risk stage (5 stages, each ~20%)
    Color riskColor;
    String riskMessage;
    
    if (riskPercentage < 20) {
      riskColor = const Color(0xFF2E7D32); // Dark green (Material)
      riskMessage = "Very Low Risk";
    } else if (riskPercentage < 40) {
      riskColor = const Color(0xFF66BB6A); // Light green (Material)
      riskMessage = "Low Risk";
    } else if (riskPercentage < 60) {
      riskColor = const Color(0xFFFFEB3B); // Yellow (Material)
      riskMessage = "Medium Risk";
    } else if (riskPercentage < 80) {
      riskColor = const Color(0xFFFF9800); // Orange (Material)
      riskMessage = "High Risk";
    } else {
      riskColor = const Color(0xFFF44336); // Red (Material)
      riskMessage = "Very High Risk";
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            profit >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            AppColors.primaryPurple.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: profit >= 0 ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            "Estimated Profit",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${profit >= 0 ? '+' : ''}${profit.toStringAsFixed(2)} $_globalForexCurrency",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: profit >= 0 ? AppColors.profitGreen : AppColors.lossRed,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            "New Balance",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${newBalance.toStringAsFixed(2)} $_globalForexCurrency",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: riskColor.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    riskMessage,
                    style: TextStyle(
                      color: riskColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: [
                      // Debug: Show percentage
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: riskColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${riskPercentage.toStringAsFixed(1)}% of Balance",
                        style: TextStyle(
                          color: riskColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Contract size: $contractSize per lot",
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardTab(bool isDark) {
    double futureValue = _globalPrincipal *
        pow(1 + (_globalStandardIsAnnual ? (_globalAnnualRate / 1200) : (_globalAnnualRate / 100)), _globalMonths);
    double profit = futureValue - _globalPrincipal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputField(
          label: "Initial Investment (\$)",
          controller: _principalController,
          onChanged: (val) {
            setState(() {
              _globalPrincipal = double.tryParse(val) ?? 0.0;
            });
          },
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _buildReturnTypeToggle(
          isAnnual: _globalStandardIsAnnual,
          onChanged: (val) {
            setState(() {
              _globalStandardIsAnnual = val;
            });
          },
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _buildInputField(
          label: _globalStandardIsAnnual ? "Expected Annual Return (%)" : "Expected Monthly Return (%)",
          controller: _rateController,
          onChanged: (val) {
            setState(() {
              _globalAnnualRate = double.tryParse(val) ?? 0.0;
            });
          },
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Duration: ${_formatDuration(_globalMonths)}",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            Row(
              children: [
                _buildAdjustButton(
                  icon: Icons.remove,
                  onPressed: () {
                    if (_globalMonths > 1) {
                      setState(() => _globalMonths--);
                    }
                  },
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildAdjustButton(
                  icon: Icons.add,
                  onPressed: () {
                    if (_globalMonths < 180) {
                      setState(() => _globalMonths++);
                    }
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
        Slider(
          value: _globalMonths.toDouble(),
          min: 1,
          max: 180,
          divisions: 179,
          activeColor: AppColors.primaryPurple,
          onChanged: (val) {
            setState(() {
              _globalMonths = val.toInt();
            });
          },
        ),
        const SizedBox(height: 16),
        _buildResultCard(futureValue, profit, isDark),
      ],
    );
  }

  Widget _buildStockTab(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Autocomplete<MarketInstrument>(
          displayStringForOption: (option) => "${option.name} (${option.symbol})",
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<MarketInstrument>.empty();
            }
            try {
              return await ref.read(marketRepositoryProvider).searchInstruments(textEditingValue.text);
            } catch (e) {
              return const Iterable<MarketInstrument>.empty();
            }
          },
          onSelected: (MarketInstrument selection) {
            setState(() {
              _globalSelectedStock = selection;
            });
            FocusScope.of(context).unfocus(); // Close keyboard
          },
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            if (_globalSelectedStock != null && textEditingController.text.isEmpty) {
              textEditingController.text = "${_globalSelectedStock!.name} (${_globalSelectedStock!.symbol})";
            }
            return _buildRawInputField(
              label: "Search Stock",
              controller: textEditingController,
              focusNode: focusNode,
              isDark: isDark,
              hint: "e.g. Apple or AAPL",
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                color: isDark ? const Color(0xFF1C1F26) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200, maxWidth: 320),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text("${option.name} (${option.symbol})", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                        subtitle: Text("\$${option.price?.toStringAsFixed(2)}", style: const TextStyle(color: AppColors.primaryPurple)),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        if (_globalSelectedStock != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryPurple.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Current Price", style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                Text("\$${_globalSelectedStock!.price?.toStringAsFixed(2)}", 
                    style: const TextStyle(color: AppColors.primaryPurple, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildInputField(
            label: "Number of Shares",
            controller: _sharesController,
            onChanged: (val) {
              setState(() {
                _globalStockShares = double.tryParse(val) ?? 0.0;
              });
            },
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildReturnTypeToggle(
            isAnnual: _globalStockIsAnnual,
            onChanged: (val) {
              setState(() {
                _globalStockIsAnnual = val;
              });
            },
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildInputField(
            label: _globalStockIsAnnual ? "Expected Annual Return (%)" : "Expected Monthly Return (%)",
            controller: _stockRateController,
            onChanged: (val) {
              setState(() {
                _globalStockAnnualRate = double.tryParse(val) ?? 0.0;
              });
            },
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Duration: ${_formatDuration(_globalStockMonths)}",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              Row(
                children: [
                  _buildAdjustButton(
                    icon: Icons.remove,
                    onPressed: () {
                      if (_globalStockMonths > 1) {
                        setState(() => _globalStockMonths--);
                      }
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildAdjustButton(
                    icon: Icons.add,
                    onPressed: () {
                      if (_globalStockMonths < 180) {
                        setState(() => _globalStockMonths++);
                      }
                    },
                    isDark: isDark,
                  ),
                ],
              ),
            ],
          ),
          Slider(
            value: _globalStockMonths.toDouble(),
            min: 1,
            max: 180,
            divisions: 179,
            activeColor: AppColors.primaryPurple,
            onChanged: (val) {
              setState(() {
                _globalStockMonths = val.toInt();
              });
            },
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final double stockPrice = _globalSelectedStock!.price ?? 0.0;
              double initialInvestment = _globalStockShares * stockPrice;
              double futureValue = initialInvestment *
                  pow(1 + (_globalStockIsAnnual ? (_globalStockAnnualRate / 1200) : (_globalStockAnnualRate / 100)), _globalStockMonths);
              double profit = futureValue - initialInvestment;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Initial Investment: \$${initialInvestment.toStringAsFixed(2)}", 
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13)),
                  const SizedBox(height: 8),
                  _buildResultCard(futureValue, profit, isDark),
                ],
              );
            }
          ),
        ] else ...[
          const SizedBox(height: 40),
          const Center(child: Text("Please search and select a stock to begin", style: TextStyle(color: Colors.grey))),
        ],
      ],
    );
  }

  String _formatDuration(int totalMonths) {
    if (totalMonths < 12) {
      return "$totalMonths ${totalMonths == 1 ? 'Month' : 'Months'}";
    }
    final years = totalMonths ~/ 12;
    final months = totalMonths % 12;
    final yearStr = "$years ${years == 1 ? 'Year' : 'Years'}";
    if (months == 0) {
      return yearStr;
    }
    final monthStr = "$months ${months == 1 ? 'Month' : 'Months'}";
    return "$yearStr / $monthStr";
  }

  Widget _buildResultCard(double futureValue, double profit, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryPurple.withOpacity(0.1), AppColors.secondaryBlue.withOpacity(0.1)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Est. Future Value", style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
              Text("\$${futureValue.toStringAsFixed(2)}", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total Profit", style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
              Text("+\$${profit.toStringAsFixed(2)}", 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.profitGreen)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
    required bool isDark,
  }) {
    return _buildRawInputField(
      label: label,
      controller: controller,
      onChanged: onChanged,
      isDark: isDark,
    );
  }

  Widget _buildRawInputField({
    required String label,
    required TextEditingController controller,
    FocusNode? focusNode,
    Function(String)? onChanged,
    required bool isDark,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1F26) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: onChanged != null ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            onChanged: onChanged,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdjustButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1F26) : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 18, color: isDark ? Colors.white70 : Colors.black87),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildReturnTypeToggle({
    required bool isAnnual,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1F26) : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(true),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isAnnual 
                      ? (isDark ? AppColors.primaryPurple : Colors.white) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "Annual Return",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isAnnual 
                        ? (isDark ? Colors.white : Colors.black) 
                        : (isDark ? Colors.white54 : Colors.black54),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(false),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: !isAnnual 
                      ? (isDark ? AppColors.primaryPurple : Colors.white) 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "Monthly Return",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: !isAnnual 
                        ? (isDark ? Colors.white : Colors.black) 
                        : (isDark ? Colors.white54 : Colors.black54),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Instrument Search Notifier ---
class CalculatorSearchNotifier extends StateNotifier<AsyncValue<List<MarketInstrument>>> {
  final MarketRepository _repository;
  final Ref _ref;
  
  int _currentPage = 1;
  bool _hasNext = true;
  bool _isLoadingMore = false;
  List<MarketInstrument> _allInstruments = []; // Store all loaded instruments for favorites tab
  List<MarketInstrument> _instruments = [];
  ProviderSubscription? _livePricesSubscription;
  ProviderSubscription? _calculatorFavoritesSubscription;
  String _lastCategory = "All";
  String _lastQuery = "";
  String _lastSort = "alphabetical";
  
  // Expose hasNext and isLoadingMore as getters
  bool get hasNext => _hasNext;
  bool get isLoadingMore => _isLoadingMore;

  CalculatorSearchNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    _loadInstruments("All", "", "alphabetical");
    
    // Subscribe to calculatorFavoritesProvider to reload favorites when it changes!
    _calculatorFavoritesSubscription = _ref.listen<Set<String>>(
      calculatorFavoritesProvider,
      (previous, next) {
        if (_lastCategory == "Favorites") {
          _loadInstruments(_lastCategory, _lastQuery, _lastSort);
        }
      },
    );
  }

  @override
  void dispose() {
    _livePricesSubscription?.close();
    _calculatorFavoritesSubscription?.close();
    super.dispose();
  }

  Future<void> _loadInstruments(String category, String query, String sort) async {
    _lastCategory = category;
    _lastQuery = query;
    _lastSort = sort;
    _currentPage = 1;
    // No pagination for Favorites or All category
    _hasNext = category != "All" && category != "Favorites";
    _instruments = [];
    state = const AsyncValue.loading();

    try {
      if (category == "Favorites") {
        // Load calculator favorites!
        final favoriteIds = _ref.read(calculatorFavoritesProvider);
        debugPrint('🎯 Loading calculator favorites! Favorite IDs: $favoriteIds');
        
        // Filter _allInstruments to find favorites (if available)
        if (_allInstruments.isNotEmpty) {
          _instruments = _allInstruments.where((inst) => favoriteIds.contains(inst.id)).toList();
          debugPrint('✅ Loaded ${_instruments.length} favorites from cache!');
        } else {
          // If we don't have cached instruments yet, load all first!
          await _loadAllInstrumentsForFavorites();
          _instruments = _allInstruments.where((inst) => favoriteIds.contains(inst.id)).toList();
          debugPrint('✅ Loaded ${_instruments.length} favorites!');
        }
        
        // Apply search filter
        if (query.isNotEmpty) {
          final lowerQuery = query.toLowerCase();
          _instruments = _instruments.where((inst) {
            final symbol = inst.symbol.toLowerCase();
            final name = inst.name.toLowerCase();
            return symbol.contains(lowerQuery) || name.contains(lowerQuery);
          }).toList();
        }
      } else {
        // Load from trending or search
        String? apiType = category == "All" ? null : category.toLowerCase();
        if (apiType == 'stock') apiType = 'stocks';

        if (query.isEmpty) {
          if (apiType != null) {
            try {
              _instruments = await _repository.getTrendingInstruments(type: apiType);
              _hasNext = false; // No pagination for trending
            } catch (e) {
              debugPrint('Fallback to market overview for $apiType due to: $e');
              try {
                final overview = await _repository.getMarketOverview(apiType);
                _instruments = overview.instruments;
                _hasNext = overview.meta.hasNext; // Enable pagination for market overview!
              } catch (e2) {
                _instruments = [];
                _hasNext = false;
              }
            }
          } else {
            // All category: combine trending instruments from all types!
            final futures = [
              _repository.getTrendingInstruments(type: 'stocks'),
              _repository.getTrendingInstruments(type: 'crypto'),
              _repository.getTrendingInstruments(type: 'forex'),
              _repository.getTrendingInstruments(type: 'etf'),
              _repository.getTrendingInstruments(type: 'commodities'),
            ];
            final results = await Future.wait(futures);
            _instruments = results.expand((x) => x).toList();
            
            // Remove duplicates by instrument ID
            final seenIds = <String>{};
            _instruments = _instruments.where((instrument) {
              if (seenIds.contains(instrument.id)) return false;
              seenIds.add(instrument.id);
              return true;
            }).toList();
          }
        } else {
          // If there's a search query, use search endpoint
          _instruments = await _repository.searchInstruments(query);
          
          // Apply category filter if needed
          if (category != "All") {
            _instruments = _instruments.where((inst) {
              final type = inst.type.toLowerCase();
              final cat = category.toLowerCase();
              if (cat == 'stock' && (type == 'stock' || type == 'stocks' || type == 'equity')) return true;
              if (cat == 'crypto' && (type == 'crypto' || type == 'cryptocurrency')) return true;
              if (cat == 'forex' && (type == 'forex' || type == 'currency' || type == 'fx')) return true;
              if (cat == 'etf' && (type == 'etf' || type == 'etfs')) return true;
              if (cat == 'commodities' && (type == 'commodity' || type == 'commodities')) return true;
              return type == cat;
            }).toList();
          }
        }

        // Store all loaded instruments in _allInstruments for later favorite lookup!
        _addToAllInstruments(_instruments);
      }

      // First, set visible instruments so SSE stream starts updating prices!
      if (_instruments.isNotEmpty) {
        _ref.read(visibleInstrumentsProvider.notifier).state = _instruments.take(5).map((inst) => inst.id).toList();
      }

      // Check globalLivePricesProvider for cached prices first, then fetch details!
      final cachedPrices = _ref.read(globalLivePricesProvider);
      _instruments = await Future.wait(_instruments.map((inst) async {
        final cleanId = inst.id.contains(':') ? inst.id.split(':')[1] : inst.id;
        
        // Check if we have a cached price!
        if (cachedPrices[cleanId] != null) {
          final cached = cachedPrices[cleanId]!;
          return inst.copyWith(
            price: cached.price,
            change: cached.change,
            changePercent: cached.changePercent,
          );
        }
        
        // If we have a price from the API, keep it!
        if (inst.price != null && inst.price! > 0.0) return inst;
        
        // Otherwise, fetch details!
        try {
          final detail = await _repository.getInstrumentDetails(inst.id);
          if (detail.price.current != null && detail.price.current! > 0.0) {
            return inst.copyWith(
              price: detail.price.current,
              change: detail.price.change,
              changePercent: detail.price.changePercent,
            );
          }
          return inst;
        } catch (e) {
          debugPrint('Error fetching price for ${inst.symbol} during initial load: $e');
          return inst;
        }
      }));

      // Update _allInstruments with price data
      _addToAllInstruments(_instruments);

      // Apply sorting
      _applySorting(sort);
      
      state = AsyncValue.data(List.of(_instruments));
      _updateLivePricesSubscription();
    } catch (e, stack) {
      debugPrint('Error loading instruments: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _loadAllInstrumentsForFavorites() async {
    // Load all trending instruments so we have them cached for favorites!
    final futures = [
      _repository.getTrendingInstruments(type: 'stocks'),
      _repository.getTrendingInstruments(type: 'crypto'),
      _repository.getTrendingInstruments(type: 'forex'),
      _repository.getTrendingInstruments(type: 'etf'),
      _repository.getTrendingInstruments(type: 'commodities'),
    ];
    final results = await Future.wait(futures);
    _allInstruments = results.expand((x) => x).toList();
    
    // Remove duplicates by instrument ID
    final seenIds = <String>{};
    _allInstruments = _allInstruments.where((instrument) {
      if (seenIds.contains(instrument.id)) return false;
      seenIds.add(instrument.id);
      return true;
    }).toList();
  }

  void _addToAllInstruments(List<MarketInstrument> instruments) {
    // Add or update instruments in _allInstruments
    for (final inst in instruments) {
      // Find index if exists
      final index = _allInstruments.indexWhere((i) => i.id == inst.id);
      if (index != -1) {
        // Update existing
        _allInstruments[index] = inst;
      } else {
        // Add new
        _allInstruments.add(inst);
      }
    }
  }

  Future<void> loadMore() async {
    // Load more only for market overview endpoints, not for trending or search
    if (_isLoadingMore || !_hasNext || _lastCategory == "Favorites" || _lastQuery.isNotEmpty || _lastCategory == "All") return;
    
    _isLoadingMore = true;
    try {
      String? apiType = _lastCategory == "All" ? null : _lastCategory.toLowerCase();
      if (apiType == 'stock') apiType = 'stocks';
      
      // Only try to load more if we actually have pageable data
      if (apiType == null) return;
      
      final response = await _repository.getMarketOverview(
        apiType,
        search: _lastQuery.isNotEmpty ? _lastQuery : null,
        page: _currentPage + 1,
        limit: 50,
      );
      
      _currentPage++;
      _hasNext = response.meta.hasNext;
      
      // Fetch prices for new instruments
      final newInstruments = await Future.wait(response.instruments.map((inst) async {
        if (inst.price != null && inst.price! > 0.0) return inst;
        try {
          final detail = await _repository.getInstrumentDetails(inst.id);
          if (detail.price.current != null && detail.price.current! > 0.0) {
            return inst.copyWith(price: detail.price.current);
          }
          return inst;
        } catch (e) {
          debugPrint('Error fetching price for ${inst.symbol} during load more: $e');
          return inst;
        }
      }));
      
      _instruments.addAll(newInstruments);
      
      // Re-apply sorting after adding new instruments
      _applySorting(_lastSort);
      
      state = AsyncValue.data(List.of(_instruments));
      _updateLivePricesSubscription();
    } catch (e) {
      debugPrint('Error loading more instruments: $e');
    } finally {
      _isLoadingMore = false;
    }
  }

  void _applySorting(String sortBy) {
    switch (sortBy) {
      case 'price_high':
        _instruments.sort((a, b) {
          final priceA = a.price ?? 0.0;
          final priceB = b.price ?? 0.0;
          return priceB.compareTo(priceA);
        });
        break;
      case 'price_low':
        _instruments.sort((a, b) {
          final priceA = a.price ?? 0.0;
          final priceB = b.price ?? 0.0;
          return priceA.compareTo(priceB);
        });
        break;
      case 'alphabetical':
      default:
        _instruments.sort((a, b) {
          return a.symbol.toLowerCase().compareTo(b.symbol.toLowerCase());
        });
        break;
    }
  }

  void refresh(String category, String query, String sort) {
    _loadInstruments(category, query, sort);
  }

  void _updateLivePricesSubscription() {
    _livePricesSubscription?.close();
    _livePricesSubscription = null;

    _livePricesSubscription = _ref.listen<Map<String, LivePriceUpdate>>(
      globalLivePricesProvider,
      (previous, next) {
        bool updated = false;
        _instruments = _instruments.map((instrument) {
          final cleanInstId = instrument.id.contains(':') ? instrument.id.split(':')[1] : instrument.id;
          final update = next[cleanInstId];
          if (update != null) {
            if (update.price != instrument.price ||
                update.change != instrument.change ||
                update.changePercent != instrument.changePercent) {
              updated = true;
              return instrument.copyWith(
                price: update.price,
                change: update.change,
                changePercent: update.changePercent,
              );
            }
          }
          return instrument;
        }).toList();

        if (updated) {
          state = AsyncValue.data(List.of(_instruments));
        }
      },
      fireImmediately: true,
    );
  }
}

final calculatorSearchProvider = StateNotifierProvider.autoDispose<CalculatorSearchNotifier, AsyncValue<List<MarketInstrument>>>((ref) {
  final repository = ref.watch(marketRepositoryProvider);
  return CalculatorSearchNotifier(repository, ref);
});

// --- Calculator Favorites Provider ---
final calculatorFavoritesProvider = StateNotifierProvider<CalculatorFavoritesNotifier, Set<String>>((ref) {
  return CalculatorFavoritesNotifier();
});

class CalculatorFavoritesNotifier extends StateNotifier<Set<String>> {
  static const String _prefsKey = 'calculator_favorites';

  CalculatorFavoritesNotifier() : super({}) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesList = prefs.getStringList(_prefsKey) ?? [];
      state = Set.from(favoritesList);
    } catch (e) {
      debugPrint('Error loading calculator favorites: $e');
    }
  }

  Future<void> toggleFavorite(String instrumentId) async {
    final newFavorites = Set<String>.from(state);
    if (newFavorites.contains(instrumentId)) {
      newFavorites.remove(instrumentId);
    } else {
      newFavorites.add(instrumentId);
    }
    state = newFavorites;

    // Save to SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, newFavorites.toList());
    } catch (e) {
      debugPrint('Error saving calculator favorites: $e');
    }
  }

  bool isFavorite(String instrumentId) {
    return state.contains(instrumentId);
  }
}

// Provider to check if an instrument is a calculator favorite
final isCalculatorFavoriteProvider = Provider.family<bool, String>((ref, instrumentId) {
  final favorites = ref.watch(calculatorFavoritesProvider);
  return favorites.contains(instrumentId);
});

// --- End Instrument Search Notifier ---

// Searchable List for the Picker
final _instrumentSearchQueryProvider = StateProvider.autoDispose<String>((ref) => "");
final _instrumentSearchCategoryProvider = StateProvider.autoDispose<String>((ref) => "All");
final _instrumentSortProvider = StateProvider.autoDispose<String>((ref) => "alphabetical"); // options: alphabetical, price_high, price_low
