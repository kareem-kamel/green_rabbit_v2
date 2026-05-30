import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../main.dart'; // To access globalNavigatorKey
import '../../features/market/presentation/providers/market_providers.dart';
import '../../features/market/data/models/market_instrument.dart';

import 'package:green_rabbit/shared/widgets/feature_guide_overlay.dart';

// Global flag to control visibility
final ValueNotifier<bool> showGlobalCalculator = ValueNotifier<bool>(false);

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

class GlobalCalculatorOverlay extends StatefulWidget {
  const GlobalCalculatorOverlay({super.key});

  @override
  State<GlobalCalculatorOverlay> createState() => _GlobalCalculatorOverlayState();
}

class _GlobalCalculatorOverlayState extends State<GlobalCalculatorOverlay> {
  double _xOffset = 42.0;
  bool _isHidden = true;
  bool _isPageOpen = false;

  @override
  void initState() {
    super.initState();
    // Ensure it starts hidden
    _xOffset = 42.0;
    _isHidden = true;
  }

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
    return ValueListenableBuilder<bool>(
      valueListenable: showGlobalCalculator,
      builder: (context, show, child) {
        if (!show || _isPageOpen) return const SizedBox.shrink();

        return Positioned(
          bottom: 60, // Lower position
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
                    child: Stack(
                      children: [
                        Align(
                          alignment: _isHidden ? Alignment.centerLeft : Alignment.center,
                          child: Padding(
                            padding: EdgeInsets.only(left: _isHidden ? 6.0 : 0),
                            child: Icon(
                              _isHidden ? Icons.chevron_left : Icons.calculate_outlined,
                              color: Colors.white,
                              size: _isHidden ? 20 : 28, // Slightly larger hidden icon
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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F111A) : Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.calculate, color: AppColors.primaryPurple),
            const SizedBox(width: 8),
            Text(
              "Investment Calculator",
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
            ],
          ),
        ),
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
