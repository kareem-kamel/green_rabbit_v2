import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../main.dart'; // To access globalNavigatorKey
import '../../features/market/presentation/providers/market_providers.dart';
import '../../features/market/data/models/market_instrument.dart';

// Global flag to control visibility
final ValueNotifier<bool> showGlobalCalculator = ValueNotifier<bool>(false);

// Persistent state for Standard Calculator
double _globalPrincipal = 1000.0;
double _globalAnnualRate = 10.0;
int _globalMonths = 12;

// Persistent state for Stock Calculator
MarketInstrument? _globalSelectedStock;
double _globalStockShares = 10;
double _globalStockAnnualRate = 15.0;
int _globalStockMonths = 60;

class GlobalCalculatorOverlay extends StatefulWidget {
  const GlobalCalculatorOverlay({super.key});

  @override
  State<GlobalCalculatorOverlay> createState() => _GlobalCalculatorOverlayState();
}

class _GlobalCalculatorOverlayState extends State<GlobalCalculatorOverlay> {
  double _xOffset = 0.0;
  bool _isHidden = false;
  bool _isBottomSheetOpen = false;

  void _openCalculator() async {
    if (_isHidden) {
      setState(() {
        _isHidden = false;
        _xOffset = 0.0;
      });
      return;
    }

    final context = globalNavigatorKey.currentContext;
    if (context == null) return;
    
    setState(() {
      _isBottomSheetOpen = true;
    });

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _InvestmentCalculatorSheet(),
    );

    // This runs after the bottom sheet is closed
    if (mounted) {
      setState(() {
        _isBottomSheetOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: showGlobalCalculator,
      builder: (context, show, child) {
        if (!show || _isBottomSheetOpen) return const SizedBox.shrink();

        return Positioned(
          bottom: 80, // Above bottom nav bar
          right: -_xOffset + 16,
          child: SafeArea(
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _xOffset -= details.delta.dx;
                  if (_xOffset < 0) _xOffset = 0;
                  if (_xOffset > 42) _xOffset = 42; // Max hide offset
                });
              },
              onHorizontalDragEnd: (details) {
                setState(() {
                  if (_xOffset > 20) {
                    _xOffset = 42;
                    _isHidden = true;
                  } else {
                    _xOffset = 0;
                    _isHidden = false;
                  }
                });
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
                    child: Align(
                      alignment: _isHidden ? Alignment.centerLeft : Alignment.center,
                      child: Padding(
                        padding: EdgeInsets.only(left: _isHidden ? 6.0 : 0),
                        child: Icon(
                          _isHidden ? Icons.arrow_back_ios_new : Icons.calculate_outlined,
                          color: Colors.white,
                          size: _isHidden ? 16 : 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InvestmentCalculatorSheet extends ConsumerStatefulWidget {
  const _InvestmentCalculatorSheet();

  @override
  ConsumerState<_InvestmentCalculatorSheet> createState() => _InvestmentCalculatorSheetState();
}

class _InvestmentCalculatorSheetState extends ConsumerState<_InvestmentCalculatorSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _principalController;
  late TextEditingController _rateController;
  late TextEditingController _sharesController;
  late TextEditingController _stockRateController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _principalController = TextEditingController(text: _globalPrincipal.toInt().toString());
    _rateController = TextEditingController(text: _globalAnnualRate.toInt().toString());
    _sharesController = TextEditingController(text: _globalStockShares.toInt().toString());
    _stockRateController = TextEditingController(text: _globalStockAnnualRate.toInt().toString());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _principalController.dispose();
    _rateController.dispose();
    _sharesController.dispose();
    _stockRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20, // Handles keyboard
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calculate, color: AppColors.primaryPurple),
                    const SizedBox(width: 8),
                    Text(
                      "Investment Calc",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Tab Bar
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primaryPurple,
              labelColor: AppColors.primaryPurple,
              unselectedLabelColor: Colors.grey,
              onTap: (index) => setState(() {}),
              tabs: const [
                Tab(text: "Standard Calc"),
                Tab(text: "Stock Calc"),
              ],
            ),
            const SizedBox(height: 24),

            // Tab Content
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _tabController.index == 0 ? _buildStandardTab(isDark) : _buildStockTab(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardTab(bool isDark) {
    double futureValue = _globalPrincipal * pow((1 + (_globalAnnualRate / 100)), _globalMonths / 12);
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
        _buildInputField(
          label: "Expected Annual Return (%)",
          controller: _rateController,
          onChanged: (val) {
            setState(() {
              _globalAnnualRate = double.tryParse(val) ?? 0.0;
            });
          },
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        Text(
          "Duration: ${_globalMonths < 12 ? '$_globalMonths Months' : '${(_globalMonths / 12).toStringAsFixed(1)} Years'}",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        Slider(
          value: _globalMonths.toDouble(),
          min: 1,
          max: 120,
          divisions: 119,
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
    final marketAsync = ref.watch(marketOverviewProvider('stocks'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        marketAsync.when(
          data: (stocks) {
            return Autocomplete<MarketInstrument>(
              displayStringForOption: (option) => "${option.name} (${option.symbol})",
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<MarketInstrument>.empty();
                }
                return stocks.where((stock) {
                  return stock.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                         stock.symbol.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
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
                            subtitle: Text("\$${option.price.toStringAsFixed(2)}", style: const TextStyle(color: AppColors.primaryPurple)),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text("Error loading stocks", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
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
                Text("\$${_globalSelectedStock!.price.toStringAsFixed(2)}", 
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
          _buildInputField(
            label: "Expected Annual Return (%)",
            controller: _stockRateController,
            onChanged: (val) {
              setState(() {
                _globalStockAnnualRate = double.tryParse(val) ?? 0.0;
              });
            },
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          Text(
            "Duration: ${_globalStockMonths < 12 ? '$_globalStockMonths Months' : '${(_globalStockMonths / 12).toStringAsFixed(1)} Years'}",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          Slider(
            value: _globalStockMonths.toDouble(),
            min: 1,
            max: 120,
            divisions: 119,
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
              double initialInvestment = _globalStockShares * _globalSelectedStock!.price;
              double futureValue = initialInvestment * pow((1 + (_globalStockAnnualRate / 100)), _globalStockMonths / 12);
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
}
