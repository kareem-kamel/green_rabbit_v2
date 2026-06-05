import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../main.dart'; // To access globalNavigatorKey
import '../../features/market/presentation/providers/market_providers.dart';
import '../../features/market/data/models/market_instrument.dart';

import 'package:green_rabbit/shared/widgets/feature_guide_overlay.dart';

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

class GlobalCalculatorOverlay extends StatefulWidget {
  const GlobalCalculatorOverlay({super.key});

  @override
  State<GlobalCalculatorOverlay> createState() => _GlobalCalculatorOverlayState();
}

class _GlobalCalculatorOverlayState extends State<GlobalCalculatorOverlay> {
  double _xOffset = 42.0;
  bool _isHidden = true;
  bool _isPageOpen = false;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    // Ensure it starts hidden
    _xOffset = 42.0;
    _isHidden = true;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _openCalculator() async {
    if (_isHidden) {
      setState(() {
        _isHidden = false;
        _xOffset = 0.0;
        _hasInteracted = true;
      });
      return;
    }

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
        // Keep it revealed after coming back so user can easily open it again or swipe it away
        _isHidden = false;
        _xOffset = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isPageOpen) return const SizedBox.shrink();

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      bottom: 60,
      right: -_xOffset + 16,
      child: SafeArea(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isHidden && !_hasInteracted)
              const _AnimatedSwipeHint(),
            const SizedBox(width: 8),
            GestureDetector(
              onPanUpdate: (details) {
                if (_isHidden) {
                  // If hidden, only allow horizontal pulling to reveal
                  if (details.delta.dx.abs() > details.delta.dy.abs()) {
                    setState(() {
                      _xOffset -= details.delta.dx;
                      if (_xOffset < 0) _xOffset = 0;
                      if (_xOffset > 42) _xOffset = 42;
                    });
                  }
                } else {
                  // If revealed, ANY significant movement in ANY direction closes it
                  if (details.delta.dx.abs() > 2 || details.delta.dy.abs() > 2) {
                    setState(() {
                      _xOffset = 42;
                      _isHidden = true;
                    });
                  }
                }
              },
              onPanEnd: (details) {
                if (_isHidden) {
                  setState(() {
                    if (_xOffset > 20) {
                      _xOffset = 42;
                      _isHidden = true;
                    } else {
                      _xOffset = 0;
                      _isHidden = false;
                      _hasInteracted = true;
                    }
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
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
                          alignment: _isHidden ? Alignment.centerLeft : Alignment.center,
                          child: Padding(
                            padding: EdgeInsets.only(left: _isHidden ? 6.0 : 0),
                            child: Icon(
                              _isHidden ? Icons.chevron_left : Icons.calculate_outlined,
                              color: Colors.white,
                              size: _isHidden ? 20 : 28,
                            ),
                          ),
                        ),
                        if (_isHidden)
                          Positioned(
                            right: 8,
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
          ],
        ),
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
        builder: (_, scrollController) => Container(
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
                    Text(
                      "Select Instrument",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
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
                  child: StatefulBuilder(
                    builder: (context, setLocalState) => TextField(
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: const InputDecoration(
                        hintText: "Search instruments...",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: Colors.grey),
                      ),
                      onChanged: (val) {
                        setLocalState(() {
                          // Trigger local rebuild of the list
                        });
                        _debouncedSearch(val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // List
              Expanded(
                child: _InstrumentSearchList(
                  scrollController: scrollController,
                  isDark: isDark,
                  onSelected: (instrument) {
                    setState(() {
                      _globalForexInstrument = instrument;
                      _globalForexOpenPrice = instrument.price ?? 0.0;
                      _forexOpenPriceController.text = _globalForexOpenPrice.toString();
                    });
                    Navigator.pop(context);
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
      if (from == "EUR") amountInUSD = amount * (rates['EURUSD'] ?? 1.08);
      else if (from == "GBP") amountInUSD = amount * (rates['GBPUSD'] ?? 1.27);
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

// Searchable List for the Picker
final _instrumentSearchQueryProvider = StateProvider.autoDispose<String>((ref) => "");

final _instrumentSearchResultsProvider = FutureProvider.autoDispose<List<MarketInstrument>>((ref) async {
  final query = ref.watch(_instrumentSearchQueryProvider);
  final repo = ref.watch(marketRepositoryProvider);
  
  if (query.isEmpty) {
    return repo.getTrendingInstruments();
  } else {
    return repo.searchInstruments(query);
  }
});

class _InstrumentSearchList extends ConsumerWidget {
  final ScrollController scrollController;
  final bool isDark;
  final Function(MarketInstrument) onSelected;

  const _InstrumentSearchList({
    required this.scrollController,
    required this.isDark,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(_instrumentSearchResultsProvider);

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
          controller: scrollController,
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: instruments.length,
          itemBuilder: (context, index) {
            final instrument = instruments[index];
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
                          errorBuilder: (_, __, ___) => Icon(Icons.show_chart, color: isDark ? Colors.white24 : Colors.black26),
                        )
                      : Icon(Icons.show_chart, color: isDark ? Colors.white24 : Colors.black26),
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
              trailing: Text(
                "\$${instrument.price?.toStringAsFixed(instrument.type.toLowerCase() == 'forex' ? 5 : 2)}",
                style: const TextStyle(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => onSelected(instrument),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text(
          "Error loading instruments",
          style: TextStyle(color: isDark ? Colors.redAccent : Colors.red),
        ),
      ),
    );
  }
}
