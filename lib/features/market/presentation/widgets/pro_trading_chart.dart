import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:interactive_chart/interactive_chart.dart'; // For CandleData model
import 'package:green_rabbit/core/theme/app_colors.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:green_rabbit/features/market/presentation/utils/indicator_calculator.dart';
import 'package:green_rabbit/features/profile/presentation/screens/subscription_screen.dart';

enum ProChartMode { area, candle, indicators }

/// Tier-safe period ↔ interval pairs confirmed working via API testing.
/// Only 1M+1h is confirmed to work for free/classic accounts.
/// Others return 503 "market data unavailable" from the server.
const Map<String, String> kTierSafeIntervals = {
  '1D': '15m',   // 503 on free/classic; kept for pro tier
  '1W': '1h',   // 503 on free/classic; kept for pro tier
  '1M': '1h',   // ✅ CONFIRMED WORKING
  '3M': '1d',   // Classic+
  '6M': '1d',   // Classic+
  '1Y': '1d',   // Classic+
  '5Y': '1w',   // Pro only
  '10Y': '1M',  // Pro only
  '15Y': '1M',  // Pro only
  'ALL': '1M',  // Pro only
};

/// Returns the best available interval for a given period based on tier restrictions.
String getIntervalForPeriod(String period) {
  return kTierSafeIntervals[period] ?? '1h';
}

class ProTradingChart extends StatefulWidget {
  final List<CandleData> candles;
  final bool showMovingAverages;
  final ProChartMode mode;
  final String period;         // e.g. '1M', '1W'
  final String interval;       // e.g. '1h', '1d'
  final String symbolName;     // e.g. 'Apple Inc. (AAPL)'
  final String currency;       // e.g. 'USD'
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Set<String> activeIndicators;
  final String? activeDrawingTool;
  final ValueChanged<String?>? onDrawingToolChanged;
  final int clearDrawingsTrigger;

  const ProTradingChart({
    super.key,
    required this.candles,
    this.showMovingAverages = true,
    this.mode = ProChartMode.area,
    this.period = '1M',
    this.interval = '1h',
    this.symbolName = '',
    this.currency = 'USD',
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.activeIndicators = const {},
    this.activeDrawingTool,
    this.onDrawingToolChanged,
    this.clearDrawingsTrigger = 0,
  });

  @override
  State<ProTradingChart> createState() => _ProTradingChartState();
}

class _ProTradingChartState extends State<ProTradingChart> {
  double _scrollOffset = -1.0; // -1 indicates "needs initialization"
  double _zoomLevel = 1.0;
  double _baseZoomLevel = 1.0;

  bool _isAutoScale = true;
  double _manualMinPrice = 0.0;
  double _manualMaxPrice = 0.0;
  double _baseMinPrice = 0.0;
  double _baseMaxPrice = 0.0;
  bool _isScalingY = false;

  List<UserDrawing> _drawings = [];
  final List<DrawingPoint> _tempPoints = [];

  DateTime? _lastTapTime;
  double _lastTapX = 0.0;
  double _lastTapY = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDrawings();
  }

  Future<void> _loadDrawings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'drawings_${widget.symbolName}';
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        final List<dynamic> decoded = json.decode(jsonString);
        setState(() {
          _drawings = decoded.map((item) => UserDrawing.fromJson(item)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading drawings: $e');
    }
  }

  Future<void> _saveDrawings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'drawings_${widget.symbolName}';
      final jsonString = json.encode(_drawings.map((d) => d.toJson()).toList());
      await prefs.setString(key, jsonString);
    } catch (e) {
      debugPrint('Error saving drawings: $e');
    }
  }

  void _clearDrawings() {
    setState(() {
      _drawings.clear();
      _tempPoints.clear();
    });
    _saveDrawings();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All drawings cleared')),
    );
  }

  @override
  void didUpdateWidget(ProTradingChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset scroll when data changes (period/interval switch)
    if (oldWidget.period != widget.period || oldWidget.interval != widget.interval || (oldWidget.candles.isEmpty && widget.candles.isNotEmpty)) {
      _scrollOffset = -1.0;
      _isAutoScale = true;
    }
    if (oldWidget.clearDrawingsTrigger != widget.clearDrawingsTrigger && widget.clearDrawingsTrigger > 0) {
      _clearDrawings();
    }
    if (oldWidget.symbolName != widget.symbolName) {
      _tempPoints.clear();
      _loadDrawings();
      _isAutoScale = true;
    }
  }

  void _handleTap(TapDownDetails details, BoxConstraints constraints) {
    if (widget.activeDrawingTool == null) {
      debugPrint('Drawing tap ignored: activeDrawingTool is null');
      return;
    }
    
    final localX = details.localPosition.dx;
    final localY = details.localPosition.dy;

    // Debounce fast ghost taps/bounces in the same spot
    final now = DateTime.now();
    if (_lastTapTime != null && now.difference(_lastTapTime!) < const Duration(milliseconds: 300)) {
      final dx = localX - _lastTapX;
      final dy = localY - _lastTapY;
      if ((dx * dx + dy * dy) < 225) { // 15 pixels threshold (15 * 15 = 225)
        debugPrint('Drawing tap ignored: debounced ghost touch / bounce');
        return;
      }
    }
    _lastTapTime = now;
    _lastTapX = localX;
    _lastTapY = localY;

    debugPrint('Drawing tap detected: x=$localX, y=$localY, tool=${widget.activeDrawingTool}');

    const labelWidth = 80.0;
    const xAxisHeight = 45.0;
    
    List<String> subCharts = [];
    if (widget.activeIndicators.contains('Volume')) subCharts.add('Volume');
    if (widget.activeIndicators.contains('RSI')) subCharts.add('RSI');
    if (widget.activeIndicators.contains('MACD')) subCharts.add('MACD');
    if (widget.activeIndicators.contains('ATR')) subCharts.add('ATR');
    if (widget.activeIndicators.contains('Stoch')) subCharts.add('Stoch');
    if (widget.activeIndicators.contains('StochRSI')) subCharts.add('StochRSI');
    if (widget.activeIndicators.contains('ADX')) subCharts.add('ADX');
    if (widget.activeIndicators.contains('CCI')) subCharts.add('CCI');
    if (widget.activeIndicators.contains('WilliamsR')) subCharts.add('WilliamsR');
    if (widget.activeIndicators.contains('ROC')) subCharts.add('ROC');
    if (widget.activeIndicators.contains('OBV')) subCharts.add('OBV');
    if (widget.activeIndicators.contains('MFI')) subCharts.add('MFI');
    if (widget.activeIndicators.contains('Aroon')) subCharts.add('Aroon');
    if (widget.activeIndicators.contains('UO')) subCharts.add('UO');
    if (widget.activeIndicators.contains('BullBear')) subCharts.add('BullBear');
    if (widget.activeIndicators.contains('ADL')) subCharts.add('ADL');
    if (widget.activeIndicators.contains('CMF')) subCharts.add('CMF');
    if (widget.activeIndicators.contains('DPO')) subCharts.add('DPO');
    if (widget.activeIndicators.contains('STC')) subCharts.add('STC');
    if (widget.activeIndicators.contains('SMA_Subchart')) subCharts.add('SMA_Subchart');
    if (widget.activeIndicators.contains('EMA_Subchart')) subCharts.add('EMA_Subchart');
    if (widget.activeIndicators.contains('BB_Subchart')) subCharts.add('BB_Subchart');

    final subChartHeight = subCharts.isEmpty ? 0.0 : (constraints.maxHeight * 0.2).clamp(60.0, 100.0);
    final totalSubChartsHeight = subChartHeight * subCharts.length;
    
    final chartWidth = constraints.maxWidth - labelWidth;
    final mainChartHeight = max(100.0, constraints.maxHeight - xAxisHeight - totalSubChartsHeight);

    if (localX < 0 || localX > chartWidth || localY < 0 || localY > mainChartHeight) {
      debugPrint('Drawing tap out of bounds: x=$localX, y=$localY, width=$chartWidth, height=$mainChartHeight');
      return;
    }

    final candleWidth = 8.0 * _zoomLevel;
    final candleSpacing = 4.0 * _zoomLevel;
    final totalCandleWidth = candleWidth + candleSpacing;

    final double rawIdx = (localX + _scrollOffset) / totalCandleWidth;
    final int idx = rawIdx.floor().clamp(0, widget.candles.length - 1);
    final int timestamp = widget.candles[idx].timestamp;

    final firstVisibleIdx = (_scrollOffset / totalCandleWidth).floor().clamp(0, widget.candles.length - 1);
    final lastVisibleIdx = ((_scrollOffset + chartWidth) / totalCandleWidth).floor().clamp(0, widget.candles.length - 1);

    final visibleCandles = widget.candles.sublist(firstVisibleIdx, lastVisibleIdx + 1);
    if (visibleCandles.isEmpty) {
      debugPrint('Drawing tap ignored: no visible candles');
      return;
    }

    final double minPrice = _manualMinPrice;
    final double maxPrice = _manualMaxPrice;
    final priceRange = maxPrice - minPrice;

    if (widget.activeDrawingTool == 'eraser') {
      UserDrawing? drawingToErase;
      double closestDist = double.infinity;
      
      double distToSegment(Offset t, Offset a, Offset b) {
        double l2 = (a.dx - b.dx) * (a.dx - b.dx) + (a.dy - b.dy) * (a.dy - b.dy);
        if (l2 == 0) return (t - a).distance;
        double projection = ((t.dx - a.dx) * (b.dx - a.dx) + (t.dy - a.dy) * (b.dy - a.dy)) / l2;
        double tClamped = projection.clamp(0.0, 1.0);
        Offset projectionPoint = Offset(a.dx + tClamped * (b.dx - a.dx), a.dy + tClamped * (b.dy - a.dy));
        return (t - projectionPoint).distance;
      }

      final scaleY = mainChartHeight / (priceRange == 0 ? 1 : priceRange);

      for (final drawing in _drawings) {
        if (drawing.points.isEmpty) continue;
        final List<Offset> offsets = [];
        for (final p in drawing.points) {
          int closestIdx = 0;
          int minDiff = 9999999999999;
          for (int i = 0; i < widget.candles.length; i++) {
            final diff = (widget.candles[i].timestamp - p.timestamp).abs();
            if (diff < minDiff) {
              minDiff = diff;
              closestIdx = i;
            }
          }
          final double px = (closestIdx * totalCandleWidth) - _scrollOffset + totalCandleWidth / 2;
          final double py = mainChartHeight - (p.price - minPrice) * scaleY;
          offsets.add(Offset(px, py));
        }

        // 1. Check distance to nodes
        for (final offset in offsets) {
          final dist = (Offset(localX, localY) - offset).distance;
          if (dist < 24.0 && dist < closestDist) {
            closestDist = dist;
            drawingToErase = drawing;
          }
        }

        // 2. Check distance to line segments connecting nodes
        if (offsets.length > 1) {
          for (int j = 0; j < offsets.length - 1; j++) {
            final dist = distToSegment(Offset(localX, localY), offsets[j], offsets[j + 1]);
            if (dist < 18.0 && dist < closestDist) {
              closestDist = dist;
              drawingToErase = drawing;
            }
          }
        }
      }

      if (drawingToErase != null) {
        setState(() {
          _drawings.remove(drawingToErase);
          _saveDrawings();
          
          if (widget.onDrawingToolChanged != null) {
            widget.onDrawingToolChanged!(null);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Drawing erased')),
        );
      } else {
        debugPrint('Eraser tap: no drawing close enough to erase.');
      }
      return;
    }

    final double price = maxPrice - (localY / mainChartHeight) * priceRange;

    setState(() {
      _tempPoints.add(DrawingPoint(timestamp: timestamp, price: price));
      debugPrint('Drawing point added at price $price. Temp points size: ${_tempPoints.length}');
      final int required = _getRequiredPoints(widget.activeDrawingTool!);
      
      if (_tempPoints.length == required) {
        final newDrawing = UserDrawing(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: widget.activeDrawingTool!,
          points: List.from(_tempPoints),
        );
        _drawings.add(newDrawing);
        debugPrint('Drawing completed! Added user drawing id: ${newDrawing.id}, type: ${newDrawing.type}');
        _tempPoints.clear();
        _saveDrawings();
        
        if (widget.onDrawingToolChanged != null) {
          widget.onDrawingToolChanged!(null);
        }
      }
    });
  }

  int _getRequiredPoints(String tool) {
    switch (tool) {
      case 'horizontal_line':
      case 'vertical_line':
      case 'cross_line':
        return 1;
      case 'trend_line':
      case 'ray':
      case 'info_line':
      case 'sine_line':
      case 'cyclic_lines':
      case 'time_cycles':
      case 'fib_retracement':
      case 'gann_box':
      case 'gann_fan':
        return 2;
      case 'fib_extension':
      case 'abcd':
      case 'three_drives':
      case 'elliott_double':
      case 'elliott_correction':
        return 3;
      case 'head_shoulders':
        return 4;
      case 'xabcd':
      case 'cypher':
      case 'triangle':
      case 'elliott_impulse':
      case 'elliott_triangle':
      case 'elliott_triple':
        return 5;
      default:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.errorMessage != null) {
      return _buildErrorState(widget.errorMessage!);
    }

    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.unlockBlue));
    }

    if (widget.candles.isEmpty) {
      return _buildEmptyState();
    }

    final last = widget.candles.last;
    final first = widget.candles.first;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16),
          child: widget.mode == ProChartMode.indicators
              ? _buildIndicatorsLegend()
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.remove_circle_outline, color: AppColors.textMuted, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        widget.symbolName.isNotEmpty
                            ? '${widget.symbolName} , ${widget.interval} , (${widget.currency})'
                            : widget.interval,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.settings_outlined, color: AppColors.textMuted, size: 14),
                      const SizedBox(width: 12),
                      _buildLegendValue('O', last.open?.toStringAsFixed(2) ?? '--'),
                      _buildLegendValue('H', last.high?.toStringAsFixed(2) ?? '--'),
                      _buildLegendValue('L', last.low?.toStringAsFixed(2) ?? '--'),
                      _buildLegendValue('C', last.close?.toStringAsFixed(2) ?? '--'),
                    ],
                  ),
                ),
        ),

        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double totalCandleWidth = (8.0 + 4.0) * _zoomLevel;
              final double maxScroll = max(0.0, widget.candles.length * totalCandleWidth - (constraints.maxWidth - 80));

              if (_scrollOffset == -1.0) {
                _scrollOffset = maxScroll;
              }

              final double chartWidth = constraints.maxWidth - 80.0;
              final firstVisibleIdx = (_scrollOffset / totalCandleWidth).floor().clamp(0, widget.candles.length - 1);
              final lastVisibleIdx = ((_scrollOffset + chartWidth) / totalCandleWidth).floor().clamp(0, widget.candles.length - 1);

              final visibleCandles = widget.candles.sublist(firstVisibleIdx, lastVisibleIdx + 1);

              if (_isAutoScale) {
                double visibleMin = double.infinity;
                double visibleMax = double.negativeInfinity;
                if (visibleCandles.isNotEmpty) {
                  for (var candle in visibleCandles) {
                    final low = candle.low ?? 0;
                    final high = candle.high ?? 0;
                    if (low < visibleMin) visibleMin = low;
                    if (high > visibleMax) visibleMax = high;
                  }
                  visibleMin *= 0.998;
                  visibleMax *= 1.002;
                } else {
                  visibleMin = 0.0;
                  visibleMax = 1.0;
                }
                _manualMinPrice = visibleMin;
                _manualMaxPrice = visibleMax;
              }

              return GestureDetector(
                onScaleStart: (details) {
                  _baseZoomLevel = _zoomLevel;
                  _baseMinPrice = _manualMinPrice;
                  _baseMaxPrice = _manualMaxPrice;
                  _isScalingY = details.localFocalPoint.dx > (constraints.maxWidth - 80);
                },
                onScaleUpdate: (details) {
                  setState(() {
                    if (_isScalingY) {
                      if (details.pointerCount > 1) {
                        final double verticalScale = details.verticalScale;
                        if (verticalScale != 0.0) {
                          _isAutoScale = false;
                          final double center = (_baseMinPrice + _baseMaxPrice) / 2;
                          final double range = (_baseMaxPrice - _baseMinPrice) / verticalScale;
                          if (range > 0.001) {
                            _manualMinPrice = center - range / 2;
                            _manualMaxPrice = center + range / 2;
                          }
                        }
                      } else {
                        final double dy = details.focalPointDelta.dy;
                        if (dy != 0.0) {
                          _isAutoScale = false;
                          final double sensitivity = 0.005;
                          final double factor = 1.0 + dy * sensitivity;
                          final double center = (_manualMinPrice + _manualMaxPrice) / 2;
                          final double range = (_manualMaxPrice - _manualMinPrice) * factor;
                          if (range > 0.001) {
                            _manualMinPrice = center - range / 2;
                            _manualMaxPrice = center + range / 2;
                          }
                        }
                      }
                    } else {
                      if (details.pointerCount > 1) {
                        if (details.horizontalScale != 1.0) {
                          _zoomLevel = (_baseZoomLevel * details.horizontalScale).clamp(0.2, 5.0);
                        }
                        if (details.verticalScale != 1.0) {
                          _isAutoScale = false;
                          final double center = (_baseMinPrice + _baseMaxPrice) / 2;
                          final double range = (_baseMaxPrice - _baseMinPrice) / details.verticalScale;
                          if (range > 0.001) {
                            _manualMinPrice = center - range / 2;
                            _manualMaxPrice = center + range / 2;
                          }
                        }
                      } else {
                        _scrollOffset -= details.focalPointDelta.dx;
                        final double currentTotalWidth = (8.0 + 4.0) * _zoomLevel;
                        final double currentMaxScroll = max(0.0, widget.candles.length * currentTotalWidth - (constraints.maxWidth - 80));
                        _scrollOffset = _scrollOffset.clamp(0.0, currentMaxScroll);

                        if (!_isAutoScale) {
                          List<String> subCharts = [];
                          if (widget.activeIndicators.contains('Volume')) subCharts.add('Volume');
                          if (widget.activeIndicators.contains('RSI')) subCharts.add('RSI');
                          if (widget.activeIndicators.contains('MACD')) subCharts.add('MACD');
                          if (widget.activeIndicators.contains('ATR')) subCharts.add('ATR');
                          if (widget.activeIndicators.contains('Stoch')) subCharts.add('Stoch');
                          if (widget.activeIndicators.contains('StochRSI')) subCharts.add('StochRSI');
                          if (widget.activeIndicators.contains('ADX')) subCharts.add('ADX');
                          if (widget.activeIndicators.contains('CCI')) subCharts.add('CCI');
                          if (widget.activeIndicators.contains('WilliamsR')) subCharts.add('WilliamsR');
                          if (widget.activeIndicators.contains('ROC')) subCharts.add('ROC');
                          if (widget.activeIndicators.contains('OBV')) subCharts.add('OBV');
                          if (widget.activeIndicators.contains('MFI')) subCharts.add('MFI');
                          if (widget.activeIndicators.contains('Aroon')) subCharts.add('Aroon');
                          if (widget.activeIndicators.contains('UO')) subCharts.add('UO');
                          if (widget.activeIndicators.contains('BullBear')) subCharts.add('BullBear');
                          if (widget.activeIndicators.contains('ADL')) subCharts.add('ADL');
                          if (widget.activeIndicators.contains('CMF')) subCharts.add('CMF');
                          if (widget.activeIndicators.contains('DPO')) subCharts.add('DPO');
                          if (widget.activeIndicators.contains('STC')) subCharts.add('STC');
                          if (widget.activeIndicators.contains('SMA_Subchart')) subCharts.add('SMA_Subchart');
                          if (widget.activeIndicators.contains('EMA_Subchart')) subCharts.add('EMA_Subchart');
                          if (widget.activeIndicators.contains('BB_Subchart')) subCharts.add('BB_Subchart');

                          final subChartHeight = subCharts.isEmpty ? 0.0 : (constraints.maxHeight * 0.2).clamp(60.0, 100.0);
                          final totalSubChartsHeight = subChartHeight * subCharts.length;
                          final mainChartHeight = max(100.0, constraints.maxHeight - 45.0 - totalSubChartsHeight);

                          final double priceRange = _manualMaxPrice - _manualMinPrice;
                          final double scaleY = mainChartHeight / (priceRange == 0 ? 1 : priceRange);
                          final double deltaPrice = details.focalPointDelta.dy / scaleY;
                          _manualMinPrice += deltaPrice;
                          _manualMaxPrice += deltaPrice;
                        }
                      }
                    }
                  });
                },
                onDoubleTap: () {
                  setState(() {
                    _isAutoScale = true;
                  });
                },
                onTapDown: (details) => _handleTap(details, constraints),
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _ChartPainter(
                    candles: widget.candles,
                    scrollOffset: _scrollOffset,
                    zoomLevel: _zoomLevel,
                    mode: widget.mode,
                    period: widget.period,
                    interval: widget.interval,
                    activeIndicators: widget.activeIndicators,
                    drawings: _drawings,
                    tempPoints: _tempPoints,
                    activeDrawingTool: widget.activeDrawingTool,
                    minPrice: _manualMinPrice,
                    maxPrice: _manualMaxPrice,
                  ),
                ),
              );
            },
          ),
        ),

        // ── Bottom Stat Bar ───────────────────────────────────────────
        Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${widget.candles.length} candles',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              const SizedBox(width: 12),
              Text(
                _formatTimestamp(first.timestamp),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              const Text(' → ', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              Text(
                _formatTimestamp(last.timestamp),
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              const Spacer(),
              Text('%', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
              const SizedBox(width: 12),
              Text('Log', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isAutoScale = true;
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    'auto',
                    style: TextStyle(
                      color: _isAutoScale ? AppColors.unlockBlue : AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Error State ──────────────────────────────────────────────────────
  Widget _buildErrorState(String message) {
    // Detect tier/503 errors specifically
    final bool isTierError = message.toLowerCase().contains('503') ||
        message.toLowerCase().contains('unavailable') ||
        message.toLowerCase().contains('tier');

    Widget errorContent = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isTierError ? Icons.lock_outline : Icons.cloud_off_outlined,
            color: isTierError ? AppColors.premiumGold : AppColors.textMuted,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            isTierError
                ? 'Subscription Required for ${widget.period} / ${widget.interval}'
                : 'Chart Unavailable',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            isTierError
                ? 'This period/interval combination requires a higher subscription tier.\nTry 1M with 1h interval.'
                : message,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          if (isTierError) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
                );
              },
              icon: const Icon(Icons.star, size: 16, color: AppColors.premiumGold),
              label: const Text('Upgrade Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.unlockBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ] else if (widget.onRetry != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: widget.onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.unlockBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
    );

    if (isTierError) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
          );
        },
        behavior: HitTestBehavior.opaque,
        child: Center(child: errorContent),
      );
    }

    return Center(child: errorContent);
  }

  // ── Empty State ──────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bar_chart_outlined, color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          const Text('No chart data available', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
          const SizedBox(height: 6),
          Text(
            'Period: ${widget.period} · Interval: ${widget.interval}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Indicators Legend Row ─────────────────────────────────────────────
  Widget _buildIndicatorsLegend() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildLegendItem('Candles', Colors.red, isRect: true),
          const SizedBox(width: 12),
          _buildLegendItem('MA5', const Color(0xFF4A90E2)),
          const SizedBox(width: 12),
          _buildLegendItem('MA10', const Color(0xFF50E3C2)),
          const SizedBox(width: 12),
          _buildLegendItem('MA20', const Color(0xFFF8E71C)),
          const SizedBox(width: 12),
          _buildLegendItem('MA30', const Color(0xFFE34F4F)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, {bool isRect = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: isRect ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: isRect ? BorderRadius.circular(2) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildLegendValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(text: '$label ', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500)),
            TextSpan(text: value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(int ms) {
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      return DateFormat('MMM d, yy').format(dt);
    } catch (_) {
      return '';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Custom Painter
// ═══════════════════════════════════════════════════════════════════════════════
class _ChartPainter extends CustomPainter {
  final List<CandleData> candles;
  final double scrollOffset;
  final double zoomLevel;
  final ProChartMode mode;
  final String period;
  final String interval;
  final Set<String> activeIndicators;
  final List<UserDrawing> drawings;
  final List<DrawingPoint> tempPoints;
  final String? activeDrawingTool;
  final double minPrice;
  final double maxPrice;

  _ChartPainter({
    required this.candles,
    required this.scrollOffset,
    required this.zoomLevel,
    required this.mode,
    required this.period,
    required this.interval,
    required this.activeIndicators,
    required this.drawings,
    required this.tempPoints,
    this.activeDrawingTool,
    required this.minPrice,
    required this.maxPrice,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const labelWidth = 80.0;
    const xAxisHeight = 45.0;
    
    List<String> subCharts = [];
    if (activeIndicators.contains('Volume')) subCharts.add('Volume');
    if (activeIndicators.contains('RSI')) subCharts.add('RSI');
    if (activeIndicators.contains('MACD')) subCharts.add('MACD');
    if (activeIndicators.contains('ATR')) subCharts.add('ATR');
    if (activeIndicators.contains('Stoch')) subCharts.add('Stoch');
    if (activeIndicators.contains('StochRSI')) subCharts.add('StochRSI');
    if (activeIndicators.contains('ADX')) subCharts.add('ADX');
    if (activeIndicators.contains('CCI')) subCharts.add('CCI');
    if (activeIndicators.contains('WilliamsR')) subCharts.add('WilliamsR');
    if (activeIndicators.contains('ROC')) subCharts.add('ROC');
    if (activeIndicators.contains('OBV')) subCharts.add('OBV');
    if (activeIndicators.contains('MFI')) subCharts.add('MFI');
    if (activeIndicators.contains('Aroon')) subCharts.add('Aroon');
    if (activeIndicators.contains('UO')) subCharts.add('UO');
    if (activeIndicators.contains('BullBear')) subCharts.add('BullBear');
    if (activeIndicators.contains('ADL')) subCharts.add('ADL');
    if (activeIndicators.contains('CMF')) subCharts.add('CMF');
    if (activeIndicators.contains('DPO')) subCharts.add('DPO');
    if (activeIndicators.contains('STC')) subCharts.add('STC');
    if (activeIndicators.contains('SMA_Subchart')) subCharts.add('SMA_Subchart');
    if (activeIndicators.contains('EMA_Subchart')) subCharts.add('EMA_Subchart');
    if (activeIndicators.contains('BB_Subchart')) subCharts.add('BB_Subchart');

    final subChartHeight = subCharts.isEmpty ? 0.0 : (size.height * 0.2).clamp(60.0, 100.0);
    final totalSubChartsHeight = subChartHeight * subCharts.length;
    
    final chartWidth = size.width - labelWidth;
    final mainChartHeight = max(100.0, size.height - xAxisHeight - totalSubChartsHeight);

    final candleWidth = 8.0 * zoomLevel;
    final candleSpacing = 4.0 * zoomLevel;
    final totalCandleWidth = candleWidth + candleSpacing;

    final firstVisibleIdx = (scrollOffset / totalCandleWidth).floor().clamp(0, candles.length - 1);
    final lastVisibleIdx = ((scrollOffset + chartWidth) / totalCandleWidth).floor().clamp(0, candles.length - 1);

    final visibleCandles = candles.sublist(firstVisibleIdx, lastVisibleIdx + 1);
    if (visibleCandles.isEmpty) return;

    final double minPrice = this.minPrice;
    final double maxPrice = this.maxPrice;

    final priceRange = maxPrice - minPrice;
    final scaleY = mainChartHeight / (priceRange == 0 ? 1 : priceRange);

    double getY(double price) => mainChartHeight - (price - minPrice) * scaleY;

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..strokeWidth = 0.8;
    for (int i = 0; i <= 5; i++) {
      final y = mainChartHeight * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
      final price = maxPrice - (i / 5) * priceRange;
      _drawText(canvas, Offset(chartWidth + 8, y - 8), price.toStringAsFixed(2), Colors.white.withOpacity(0.6));
    }

    // 1. Save and Clip for Main Chart Elements (Candles, Overlays, Drawings, Last Price Line)
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, chartWidth, mainChartHeight));

    // Draw main chart candles/area
    if (mode == ProChartMode.area) {
      _drawAreaChart(canvas, mainChartHeight, getY, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
    } else {
      _drawCandles(canvas, getY, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
    }

    // Draw overlays
    if (activeIndicators.contains('SMA_Overlay') || activeIndicators.contains('SMA')) {
      _drawMALine(canvas, getY, firstVisibleIdx, lastVisibleIdx, totalCandleWidth, IndicatorCalculator.calculateSMA(candles, 20), const Color(0xFF4A90E2));
    }
    if (activeIndicators.contains('EMA_Overlay') || activeIndicators.contains('EMA')) {
      _drawMALine(canvas, getY, firstVisibleIdx, lastVisibleIdx, totalCandleWidth, IndicatorCalculator.calculateEMA(candles, 20), const Color(0xFF50E3C2));
    }
    if (activeIndicators.contains('BB_Overlay') || activeIndicators.contains('BB')) {
      _drawBollingerBands(canvas, getY, firstVisibleIdx, lastVisibleIdx, totalCandleWidth, IndicatorCalculator.calculateBollingerBands(candles, 20, 2.0));
    }
    if (activeIndicators.contains('VWAP')) {
      _drawVWAPOverlay(canvas, getY, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
    }
    if (activeIndicators.contains('Ichimoku')) {
      _drawIchimokuOverlay(canvas, getY, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
    }
    if (activeIndicators.contains('SuperTrend')) {
      _drawSuperTrendOverlay(canvas, getY, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
    }
    if (activeIndicators.contains('SAR')) {
      _drawParabolicSarOverlay(canvas, getY, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
    }
    if (activeIndicators.contains('Donchian')) {
      _drawDonchianChannelsOverlay(canvas, getY, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
    }
    if (activeIndicators.contains('Keltner')) {
      _drawKeltnerChannelsOverlay(canvas, getY, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
    }
    if (activeIndicators.contains('Fibonacci')) {
      _drawFibonacciRetracementOverlay(canvas, getY, chartWidth, firstVisibleIdx, lastVisibleIdx);
    }
    if (activeIndicators.contains('Pivot')) {
      _drawPivotPointsOverlay(canvas, getY, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
    }
    if (activeIndicators.contains('VolumeProfile')) {
      _drawVolumeProfileOverlay(canvas, getY, chartWidth, mainChartHeight, firstVisibleIdx, lastVisibleIdx);
    }

    // Draw last price line (inside clip)
    final lastPrice = candles.last.close ?? 0;
    final lastPriceY = getY(lastPrice);
    if (lastPriceY >= 0 && lastPriceY <= mainChartHeight) {
      final dashPaint = Paint()
        ..color = AppColors.unlockBlue.withOpacity(0.6)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      for (double x = 0; x < chartWidth; x += 10) {
        canvas.drawLine(Offset(x, lastPriceY), Offset(x + 5, lastPriceY), dashPaint);
      }
    }

    // --- Render Drawings (inside clip) ---
    double getCanvasX(int ts) {
      if (candles.isEmpty) return 0.0;
      int closestIdx = 0;
      int minDiff = 9999999999999;
      for (int i = 0; i < candles.length; i++) {
        final diff = (candles[i].timestamp - ts).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closestIdx = i;
        }
      }
      return (closestIdx * totalCandleWidth) - scrollOffset + totalCandleWidth / 2;
    }

    double getCanvasY(double price) {
      return mainChartHeight - (price - minPrice) * scaleY;
    }

    final drawingPaint = Paint()
      ..color = const Color(0xFF2D5CFF) // TradingView blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final nodePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final nodeBorderPaint = Paint()
      ..color = const Color(0xFF2D5CFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    void drawNode(Offset offset, {double radius = 4.0}) {
      canvas.drawCircle(offset, radius, nodePaint);
      canvas.drawCircle(offset, radius, nodeBorderPaint);
    }

    // Draw completed drawings
    for (final drawing in drawings) {
      if (drawing.points.isEmpty) continue;
      final offsets = drawing.points.map((p) => Offset(getCanvasX(p.timestamp), getCanvasY(p.price))).toList();
      _paintDrawingShape(canvas, drawing.type, offsets, drawingPaint, drawNode, chartWidth, mainChartHeight, drawing.points);
    }

    // Draw temporary in-progress preview
    if (activeDrawingTool != null && tempPoints.isNotEmpty) {
      final tempOffsets = tempPoints.map((p) => Offset(getCanvasX(p.timestamp), getCanvasY(p.price))).toList();
      for (final offset in tempOffsets) {
        drawNode(offset);
      }
      if (tempOffsets.isNotEmpty) {
        final tempPaint = Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        
        if (tempOffsets.length == 1) {
          drawNode(tempOffsets[0], radius: 5.0);
        } else {
          final path = Path()..moveTo(tempOffsets[0].dx, tempOffsets[0].dy);
          for (int i = 1; i < tempOffsets.length; i++) {
            path.lineTo(tempOffsets[i].dx, tempOffsets[i].dy);
          }
          canvas.drawPath(path, tempPaint);
        }
      }
    }

    canvas.restore(); // Restore clip rect

    // --- Draw Last Price Label (outside clip, so Y-axis tag isn't clipped) ---
    if (lastPriceY >= 0 && lastPriceY <= mainChartHeight) {
      final rect = RRect.fromRectAndRadius(Rect.fromLTWH(chartWidth, lastPriceY - 14, labelWidth, 28), const Radius.circular(4));
      canvas.drawRRect(rect, Paint()..color = AppColors.unlockBlue);
      _drawText(canvas, Offset(chartWidth + 6, lastPriceY - 8), lastPrice.toStringAsFixed(2), Colors.white, isBold: true, fontSize: 12);
    }

    // --- Draw Subcharts (outside clip) ---
    double currentSubChartTop = mainChartHeight;
    for (String subChart in subCharts) {
      canvas.drawLine(Offset(0, currentSubChartTop), Offset(chartWidth, currentSubChartTop), Paint()..color = Colors.white.withOpacity(0.2)..strokeWidth = 1);
      
      if (subChart == 'Volume') {
        _drawVolumeChart(canvas, currentSubChartTop, subChartHeight, chartWidth, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
      } else if (subChart == 'RSI') {
        _drawRSIChart(canvas, currentSubChartTop, subChartHeight, chartWidth, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
      } else if (subChart == 'MACD') {
        _drawMACDChart(canvas, currentSubChartTop, subChartHeight, chartWidth, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
      } else if (subChart == 'ATR') {
        _drawATRChart(canvas, currentSubChartTop, subChartHeight, chartWidth, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
      } else if (subChart == 'Stoch') {
        _drawStochChart(canvas, currentSubChartTop, subChartHeight, chartWidth, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
      } else if (subChart == 'StochRSI') {
        _drawStochRSIChart(canvas, currentSubChartTop, subChartHeight, chartWidth, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
      } else if (subChart == 'ADX') {
        _drawADXChart(canvas, currentSubChartTop, subChartHeight, chartWidth, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
      } else if (subChart == 'CCI') {
        _drawCCIChart(canvas, currentSubChartTop, subChartHeight, chartWidth, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
      } else if (subChart == 'WilliamsR') {
        _drawWilliamsRChart(canvas, currentSubChartTop, subChartHeight, chartWidth, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
      } else if (subChart == 'ROC') {
        _drawROCChart(canvas, currentSubChartTop, subChartHeight, chartWidth, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
      } else if (subChart == 'OBV') {
        _drawOBVChart(canvas, currentSubChartTop, subChartHeight, chartWidth, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
      } else if (subChart == 'MFI') {
        _drawMFIChart(canvas, currentSubChartTop, subChartHeight, chartWidth, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
      } else if (subChart == 'Aroon') {
        _drawAroonChart(canvas, currentSubChartTop, subChartHeight, chartWidth, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
      } else if (subChart == 'UO') {
        _drawUOChart(canvas, currentSubChartTop, subChartHeight, chartWidth, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
      } else if (subChart == 'BullBear') {
        _drawBullBearChart(canvas, currentSubChartTop, subChartHeight, chartWidth, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
      } else if (subChart == 'ADL') {
        _drawADLChart(canvas, currentSubChartTop, subChartHeight, chartWidth, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
      } else if (subChart == 'CMF') {
        _drawCMFChart(canvas, currentSubChartTop, subChartHeight, chartWidth, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
      } else if (subChart == 'DPO') {
        _drawDPOChart(canvas, currentSubChartTop, subChartHeight, chartWidth, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
      } else if (subChart == 'STC') {
        _drawSTCChart(canvas, currentSubChartTop, subChartHeight, chartWidth, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
      } else if (subChart == 'SMA_Subchart') {
        _drawSubChartMA(canvas, currentSubChartTop, subChartHeight, chartWidth, firstVisibleIdx, lastVisibleIdx, totalCandleWidth, IndicatorCalculator.calculateSMA(candles, 20), const Color(0xFF4A90E2), 'SMA');
      } else if (subChart == 'EMA_Subchart') {
        _drawSubChartMA(canvas, currentSubChartTop, subChartHeight, chartWidth, firstVisibleIdx, lastVisibleIdx, totalCandleWidth, IndicatorCalculator.calculateEMA(candles, 20), const Color(0xFF50E3C2), 'EMA');
      } else if (subChart == 'BB_Subchart') {
        _drawSubChartBB(canvas, currentSubChartTop, subChartHeight, chartWidth, firstVisibleIdx, lastVisibleIdx, totalCandleWidth, IndicatorCalculator.calculateBollingerBands(candles, 20, 2.0));
      }
      
      currentSubChartTop += subChartHeight;
    }

    // --- Draw X-axis timeline labels (outside clip) ---
    final visibleCount = lastVisibleIdx - firstVisibleIdx + 1;
    final step = max(1, (visibleCount / 8).ceil());
    final xAxisY = size.height - xAxisHeight;

    for (int i = firstVisibleIdx; i <= lastVisibleIdx; i += step) {
      final x = (i * totalCandleWidth) - scrollOffset + totalCandleWidth / 2;
      if (x < 0 || x > chartWidth) continue;

      final candle = candles[i];
      final date = DateTime.fromMillisecondsSinceEpoch(candle.timestamp);
      String topText;
      String bottomText;

      if (interval == '1d' || interval == '1w' || interval == '1M') {
        topText = DateFormat('yyyy').format(date);
        bottomText = DateFormat('MMM dd').format(date);
      } else if (interval == '1h' || interval == '15m' || interval == '5m') {
        topText = DateFormat('MMM dd').format(date);
        bottomText = DateFormat('HH:mm').format(date);
      } else {
        topText = DateFormat('MM/dd').format(date);
        bottomText = DateFormat('HH:mm').format(date);
      }

      _drawText(canvas, Offset(x - 30, xAxisY + 6), topText, Colors.white.withOpacity(0.45), fontSize: 11);
      _drawText(canvas, Offset(x - 22, xAxisY + 20), bottomText, Colors.white.withOpacity(0.45), fontSize: 11);
    }
  }

  void _paintDrawingShape(
    Canvas canvas,
    String type,
    List<Offset> offsets,
    Paint paint,
    void Function(Offset, {double radius}) drawNode,
    double chartWidth,
    double chartHeight,
    List<DrawingPoint> points,
  ) {
    if (offsets.isEmpty) return;

    void drawDashedLine(Offset p1, Offset p2, {double dashWidth = 3, double dashSpace = 3}) {
      final dx = p2.dx - p1.dx;
      final dy = p2.dy - p1.dy;
      final distance = sqrt(dx * dx + dy * dy);
      if (distance == 0) return;
      final steps = distance / (dashWidth + dashSpace);
      final deltaX = dx / steps;
      final deltaY = dy / steps;

      final dashPaint = Paint()
        ..color = paint.color.withOpacity(0.5)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < steps.toInt(); i++) {
        final x1 = p1.dx + deltaX * i;
        final y1 = p1.dy + deltaY * i;
        final x2 = x1 + deltaX * (dashWidth / (dashWidth + dashSpace));
        final y2 = y1 + deltaY * (dashWidth / (dashWidth + dashSpace));
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), dashPaint);
      }
    }

    void drawLabelText(String text, Offset offset, {double fontSize = 9.0}) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            backgroundColor: Colors.black.withOpacity(0.6),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        offset - Offset(textPainter.width / 2, textPainter.height + 3),
      );
    }

    switch (type) {
      case 'trend_line':
        if (offsets.length < 2) return;
        canvas.drawLine(offsets[0], offsets[1], paint);
        drawNode(offsets[0]);
        drawNode(offsets[1]);
        break;

      case 'ray':
        if (offsets.length < 2) return;
        canvas.drawLine(offsets[0], offsets[1], paint);
        drawNode(offsets[0]);
        // Draw small arrow indicator at offsets[1]
        final angle = atan2(offsets[1].dy - offsets[0].dy, offsets[1].dx - offsets[0].dx);
        const len = 8.0;
        canvas.drawLine(offsets[1], offsets[1] - Offset(len * cos(angle - pi/6), len * sin(angle - pi/6)), paint);
        canvas.drawLine(offsets[1], offsets[1] - Offset(len * cos(angle + pi/6), len * sin(angle + pi/6)), paint);
        break;

      case 'info_line':
        if (offsets.length < 2) return;
        canvas.drawLine(offsets[0], offsets[1], paint);
        drawNode(offsets[0]);
        drawNode(offsets[1]);
        
        // Calculate info metrics
        final priceDiff = points[1].price - points[0].price;
        final pricePct = (priceDiff / points[0].price * 100);
        final infoText = "${priceDiff > 0 ? '+' : ''}${priceDiff.toStringAsFixed(2)} (${pricePct.toStringAsFixed(2)}%)";
        drawLabelText(infoText, (offsets[0] + offsets[1]) / 2);
        break;

      case 'horizontal_line':
        final y = offsets[0].dy;
        canvas.drawLine(Offset(0, y), Offset(chartWidth, y), paint);
        drawNode(offsets[0]);
        break;

      case 'vertical_line':
        final x = offsets[0].dx;
        canvas.drawLine(Offset(x, 0), Offset(x, chartHeight), paint);
        drawNode(offsets[0]);
        break;

      case 'cross_line':
        final x = offsets[0].dx;
        final y = offsets[0].dy;
        canvas.drawLine(Offset(0, y), Offset(chartWidth, y), paint);
        canvas.drawLine(Offset(x, 0), Offset(x, chartHeight), paint);
        drawNode(offsets[0]);
        break;

      case 'fib_retracement':
        if (offsets.length < 2) return;
        final y0 = offsets[0].dy;
        final y1 = offsets[1].dy;
        final dy = y1 - y0;
        final fibLevels = [0.0, 0.236, 0.382, 0.5, 0.618, 0.786, 1.0];
        final labels = ['0.0%', '23.6%', '38.2%', '50.0%', '61.8%', '78.6%', '100.0%'];
        
        for (int i = 0; i < fibLevels.length; i++) {
          final levelY = y0 + dy * fibLevels[i];
          canvas.drawLine(Offset(0, levelY), Offset(chartWidth, levelY), paint);
          drawLabelText(labels[i], Offset(chartWidth - 30, levelY + 2), fontSize: 8.0);
        }
        drawDashedLine(offsets[0], offsets[1]);
        drawNode(offsets[0]);
        drawNode(offsets[1]);
        break;

      case 'fib_extension':
        if (offsets.length < 3) return;
        canvas.drawLine(offsets[0], offsets[1], paint);
        canvas.drawLine(offsets[1], offsets[2], paint);
        drawNode(offsets[0]);
        drawNode(offsets[1]);
        drawNode(offsets[2]);

        final baseHeight = (offsets[1].dy - offsets[0].dy).abs();
        final extLevels = [0.618, 1.0, 1.618];
        final extLabels = ['0.618', '1.000', '1.618'];
        final yRef = offsets[2].dy;
        final direction = offsets[1].dy > offsets[0].dy ? 1 : -1;

        for (int i = 0; i < extLevels.length; i++) {
          final levelY = yRef + direction * baseHeight * extLevels[i];
          canvas.drawLine(Offset(offsets[2].dx, levelY), Offset(chartWidth, levelY), paint);
          drawLabelText(extLabels[i], Offset(chartWidth - 25, levelY + 2), fontSize: 8.0);
        }
        break;

      case 'gann_box':
        if (offsets.length < 2) return;
        final rect = Rect.fromPoints(offsets[0], offsets[1]);
        canvas.drawRect(rect, paint);
        canvas.drawLine(rect.topLeft, rect.bottomRight, paint);
        canvas.drawLine(rect.bottomLeft, rect.topRight, paint);
        canvas.drawLine(Offset(rect.left, rect.top + rect.height/2), Offset(rect.right, rect.top + rect.height/2), paint);
        canvas.drawLine(Offset(rect.left + rect.width/2, rect.top), Offset(rect.left + rect.width/2, rect.bottom), paint);
        drawNode(offsets[0]);
        drawNode(offsets[1]);
        break;

      case 'gann_fan':
        if (offsets.length < 2) return;
        final origin = offsets[0];
        final target = offsets[1];
        final dx = target.dx - origin.dx;
        final dy = target.dy - origin.dy;
        final fanSlopes = [1.0, 0.5, 0.25, 2.0, 4.0];
        for (final slope in fanSlopes) {
          canvas.drawLine(origin, origin + Offset(dx, dy * slope), paint);
        }
        drawNode(origin);
        drawNode(target);
        break;

      case 'xabcd':
        if (offsets.length < 5) return;
        final x = offsets[0];
        final a = offsets[1];
        final b = offsets[2];
        final c = offsets[3];
        final d = offsets[4];

        final fillPaint = Paint()
          ..color = paint.color.withOpacity(0.06)
          ..style = PaintingStyle.fill;
        final pathXAB = Path()..moveTo(x.dx, x.dy)..lineTo(a.dx, a.dy)..lineTo(b.dx, b.dy)..close();
        final pathBCD = Path()..moveTo(b.dx, b.dy)..lineTo(c.dx, c.dy)..lineTo(d.dx, d.dy)..close();
        canvas.drawPath(pathXAB, fillPaint);
        canvas.drawPath(pathBCD, fillPaint);

        canvas.drawLine(x, a, paint);
        canvas.drawLine(a, b, paint);
        canvas.drawLine(b, c, paint);
        canvas.drawLine(c, d, paint);

        drawDashedLine(x, b);
        drawDashedLine(b, d);

        drawNode(x); drawNode(a); drawNode(b); drawNode(c); drawNode(d);
        drawLabelText('X', x); drawLabelText('A', a); drawLabelText('B', b); drawLabelText('C', c); drawLabelText('D', d);
        break;

      case 'cypher':
        if (offsets.length < 5) return;
        final x = offsets[0];
        final a = offsets[1];
        final b = offsets[2];
        final c = offsets[3];
        final d = offsets[4];

        final fillPaint = Paint()
          ..color = paint.color.withOpacity(0.06)
          ..style = PaintingStyle.fill;
        final pathXAC = Path()..moveTo(x.dx, x.dy)..lineTo(a.dx, a.dy)..lineTo(c.dx, c.dy)..close();
        canvas.drawPath(pathXAC, fillPaint);

        canvas.drawLine(x, a, paint);
        canvas.drawLine(a, b, paint);
        canvas.drawLine(b, c, paint);
        canvas.drawLine(c, d, paint);

        drawDashedLine(x, c);
        drawDashedLine(a, c);
        drawDashedLine(b, d);

        drawNode(x); drawNode(a); drawNode(b); drawNode(c); drawNode(d);
        drawLabelText('X', x); drawLabelText('A', a); drawLabelText('B', b); drawLabelText('C', c); drawLabelText('D', d);
        break;

      case 'head_shoulders':
        if (offsets.length < 4) return;
        final p1 = offsets[0]; // Left shoulder peak
        final p2 = offsets[1]; // Left trough
        final p3 = offsets[2]; // Head peak
        final p4 = offsets[3]; // Right shoulder peak
        
        final dip2 = Offset(p3.dx + (p3.dx - p2.dx), p2.dy);
        final start = Offset(p1.dx - (p2.dx - p1.dx), p2.dy);
        final end = Offset(p4.dx + (p4.dx - p3.dx), p2.dy);

        final hsPath = Path()
          ..moveTo(start.dx, start.dy)
          ..lineTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..lineTo(p3.dx, p3.dy)
          ..lineTo(dip2.dx, dip2.dy)
          ..lineTo(p4.dx, p4.dy)
          ..lineTo(end.dx, end.dy);
        canvas.drawPath(hsPath, paint);
        drawDashedLine(p2, dip2);

        drawNode(p1); drawNode(p3); drawNode(p4);
        drawLabelText('LS', p1);
        drawLabelText('Head', p3);
        drawLabelText('RS', p4);
        break;

      case 'abcd':
        if (offsets.length < 4) return;
        canvas.drawLine(offsets[0], offsets[1], paint);
        canvas.drawLine(offsets[1], offsets[2], paint);
        canvas.drawLine(offsets[2], offsets[3], paint);
        drawNode(offsets[0]); drawNode(offsets[1]); drawNode(offsets[2]); drawNode(offsets[3]);
        drawLabelText('A', offsets[0]); drawLabelText('B', offsets[1]); drawLabelText('C', offsets[2]); drawLabelText('D', offsets[3]);
        break;

      case 'triangle':
        if (offsets.length < 5) return;
        canvas.drawLine(offsets[0], offsets[2], paint);
        canvas.drawLine(offsets[1], offsets[3], paint);
        final zigPath = Path()
          ..moveTo(offsets[0].dx, offsets[0].dy)
          ..lineTo(offsets[1].dx, offsets[1].dy)
          ..lineTo(offsets[2].dx, offsets[2].dy)
          ..lineTo(offsets[3].dx, offsets[3].dy)
          ..lineTo(offsets[4].dx, offsets[4].dy);
        canvas.drawPath(zigPath, paint);
        for (final o in offsets) {
          drawNode(o);
        }
        break;

      case 'three_drives':
        if (offsets.length < 3) return;
        final start = Offset(offsets[0].dx - 15, offsets[0].dy + 10);
        final t1 = Offset((offsets[0].dx + offsets[1].dx)/2, (offsets[0].dy + offsets[1].dy)/2 + 15);
        final t2 = Offset((offsets[1].dx + offsets[2].dx)/2, (offsets[1].dy + offsets[2].dy)/2 + 15);
        final end = Offset(offsets[2].dx + 15, offsets[2].dy + 10);

        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..lineTo(offsets[0].dx, offsets[0].dy)
          ..lineTo(t1.dx, t1.dy)
          ..lineTo(offsets[1].dx, offsets[1].dy)
          ..lineTo(t2.dx, t2.dy)
          ..lineTo(offsets[2].dx, offsets[2].dy)
          ..lineTo(end.dx, end.dy);
        canvas.drawPath(path, paint);
        drawNode(offsets[0]); drawNode(offsets[1]); drawNode(offsets[2]);
        drawLabelText('1', offsets[0]); drawLabelText('2', offsets[1]); drawLabelText('3', offsets[2]);
        break;

      case 'elliott_impulse':
        if (offsets.length < 5) return;
        final start = Offset(offsets[0].dx - 15, offsets[0].dy + 15);
        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..lineTo(offsets[0].dx, offsets[0].dy)
          ..lineTo(offsets[1].dx, offsets[1].dy)
          ..lineTo(offsets[2].dx, offsets[2].dy)
          ..lineTo(offsets[3].dx, offsets[3].dy)
          ..lineTo(offsets[4].dx, offsets[4].dy);
        canvas.drawPath(path, paint);
        for (int i = 0; i < 5; i++) {
          drawNode(offsets[i]);
          drawLabelText((i+1).toString(), offsets[i]);
        }
        break;

      case 'elliott_correction':
        if (offsets.length < 3) return;
        final start = Offset(offsets[0].dx - 15, offsets[0].dy - 10);
        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..lineTo(offsets[0].dx, offsets[0].dy)
          ..lineTo(offsets[1].dx, offsets[1].dy)
          ..lineTo(offsets[2].dx, offsets[2].dy);
        canvas.drawPath(path, paint);
        drawNode(offsets[0]); drawNode(offsets[1]); drawNode(offsets[2]);
        drawLabelText('A', offsets[0]); drawLabelText('B', offsets[1]); drawLabelText('C', offsets[2]);
        break;

      case 'elliott_triangle':
        if (offsets.length < 5) return;
        drawDashedLine(offsets[0], offsets[2]);
        drawDashedLine(offsets[1], offsets[3]);
        final path = Path()
          ..moveTo(offsets[0].dx, offsets[0].dy)
          ..lineTo(offsets[1].dx, offsets[1].dy)
          ..lineTo(offsets[2].dx, offsets[2].dy)
          ..lineTo(offsets[3].dx, offsets[3].dy)
          ..lineTo(offsets[4].dx, offsets[4].dy);
        canvas.drawPath(path, paint);
        final labels = ['A', 'B', 'C', 'D', 'E'];
        for (int i = 0; i < 5; i++) {
          drawNode(offsets[i]);
          drawLabelText(labels[i], offsets[i]);
        }
        break;

      case 'elliott_double':
        if (offsets.length < 3) return;
        final start = Offset(offsets[0].dx - 15, offsets[0].dy + 15);
        final end = Offset(offsets[2].dx + 15, offsets[2].dy + 15);
        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..lineTo(offsets[0].dx, offsets[0].dy)
          ..lineTo(offsets[1].dx, offsets[1].dy)
          ..lineTo(offsets[2].dx, offsets[2].dy)
          ..lineTo(end.dx, end.dy);
        canvas.drawPath(path, paint);
        drawNode(offsets[0]); drawNode(offsets[1]); drawNode(offsets[2]);
        drawLabelText('W', offsets[0]); drawLabelText('X', offsets[1]); drawLabelText('Y', offsets[2]);
        break;

      case 'elliott_triple':
        if (offsets.length < 5) return;
        final start = Offset(offsets[0].dx - 15, offsets[0].dy + 15);
        final end = Offset(offsets[4].dx + 15, offsets[4].dy + 15);
        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..lineTo(offsets[0].dx, offsets[0].dy)
          ..lineTo(offsets[1].dx, offsets[1].dy)
          ..lineTo(offsets[2].dx, offsets[2].dy)
          ..lineTo(offsets[3].dx, offsets[3].dy)
          ..lineTo(offsets[4].dx, offsets[4].dy)
          ..lineTo(end.dx, end.dy);
        canvas.drawPath(path, paint);
        final labels = ['W', 'X', 'Y', 'X', 'Z'];
        for (int i = 0; i < 5; i++) {
          drawNode(offsets[i]);
          drawLabelText(labels[i], offsets[i]);
        }
        break;

      case 'cyclic_lines':
        if (offsets.length < 2) return;
        final dx = (offsets[1].dx - offsets[0].dx).abs();
        if (dx == 0) return;
        canvas.drawLine(Offset(0, offsets[0].dy), Offset(chartWidth, offsets[0].dy), paint);
        double curX = offsets[0].dx;
        while (curX < chartWidth) {
          canvas.drawLine(Offset(curX, 0), Offset(curX, chartHeight), paint);
          curX += dx;
        }
        curX = offsets[0].dx - dx;
        while (curX > 0) {
          canvas.drawLine(Offset(curX, 0), Offset(curX, chartHeight), paint);
          curX -= dx;
        }
        drawNode(offsets[0]);
        drawNode(offsets[1]);
        break;

      case 'time_cycles':
        if (offsets.length < 2) return;
        final dx = (offsets[1].dx - offsets[0].dx).abs();
        final baselineY = offsets[0].dy;
        if (dx == 0) return;
        
        canvas.drawLine(Offset(0, baselineY), Offset(chartWidth, baselineY), paint);
        
        void drawArches(double startX, double dir) {
          double x = startX;
          while (dir > 0 ? (x < chartWidth) : (x > -dx)) {
            final xEnd = x + dir * dx;
            final midX = (x + xEnd) / 2;
            final peakY = baselineY - 25; // Loop peak
            final p = Path()
              ..moveTo(x, baselineY)
              ..quadraticBezierTo(midX, peakY, xEnd, baselineY);
            canvas.drawPath(p, paint);
            drawNode(Offset(x, baselineY), radius: 2.5);
            x = xEnd;
          }
        }
        drawArches(offsets[0].dx, 1);
        drawArches(offsets[0].dx, -1);
        break;

      case 'sine_line':
        if (offsets.length < 2) return;
        final p0 = offsets[0];
        final p1 = offsets[1];
        final wavePath = Path();
        
        wavePath.moveTo(p0.dx, p0.dy);
        final steps = (p1.dx - p0.dx).abs().toInt();
        final double midY = (p0.dy + p1.dy) / 2;
        final double amp = (p1.dy - p0.dy).abs() / 2 + 15;
        final dir = p1.dx > p0.dx ? 1 : -1;
        
        for (int i = 0; i <= steps; i++) {
          final x = p0.dx + dir * i;
          final pct = i / (steps == 0 ? 1 : steps);
          final y = midY + amp * sin(2 * pi * pct);
          wavePath.lineTo(x, y);
        }
        canvas.drawPath(wavePath, paint);
        drawNode(p0);
        drawNode(p1);
        break;
    }
  }

  void _drawAreaChart(Canvas canvas, double height, Function(double) getY, int start, int end, double stepX) {
    final path = Path();
    final fillPath = Path();
    bool first = true;

    for (int i = start; i <= end; i++) {
      final x = (i * stepX) - scrollOffset;
      final y = getY(candles[i].close ?? 0);

      if (first) {
        path.moveTo(x, y);
        fillPath.moveTo(x, height);
        fillPath.lineTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo((end * stepX) - scrollOffset, height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.unlockBlue.withOpacity(0.25), AppColors.unlockBlue.withOpacity(0.0)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, 1000, height));

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, Paint()
      ..color = AppColors.unlockBlue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke);
  }

  void _drawCandles(Canvas canvas, Function(double) getY, int start, int end, double stepX) {
    final candleWidth = max(2.0, stepX * 0.7);
    for (int i = start; i <= end; i++) {
      final candle = candles[i];
      final x = (i * stepX) - scrollOffset + (stepX - candleWidth) / 2;

      final open = candle.open ?? 0;
      final close = candle.close ?? 0;
      final high = candle.high ?? 0;
      final low = candle.low ?? 0;

      final isBull = close >= open;
      final paint = Paint()..color = isBull ? AppColors.success : AppColors.error;

      canvas.drawLine(
        Offset(x + candleWidth / 2, getY(high)),
        Offset(x + candleWidth / 2, getY(low)),
        paint..strokeWidth = 1.5,
      );
      final top = getY(isBull ? close : open);
      final bottom = getY(isBull ? open : close);
      canvas.drawRect(Rect.fromLTWH(x, top, candleWidth, max(1.0, (bottom - top).abs())), paint);
    }
  }

  void _drawMALine(Canvas canvas, Function(double) getY, int start, int end, double stepX, List<double?> maData, Color color) {
    final path = Path();
    bool first = true;
    for (int i = start; i <= end; i++) {
      if (maData[i] == null) continue;
      final x = (i * stepX) - scrollOffset + stepX / 2;
      final y = getY(maData[i]!);
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, Paint()
      ..color = color.withOpacity(0.85)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke);
  }

  void _drawBollingerBands(Canvas canvas, Function(double) getY, int start, int end, double stepX, List<BollingerBandValue> bbData) {
    final upperPath = Path();
    final lowerPath = Path();
    final middlePath = Path();
    final fillPath = Path();
    bool first = true;

    for (int i = start; i <= end; i++) {
      if (bbData[i].upper == null || bbData[i].lower == null || bbData[i].middle == null) continue;
      final x = (i * stepX) - scrollOffset + stepX / 2;
      final yu = getY(bbData[i].upper!);
      final yl = getY(bbData[i].lower!);
      final ym = getY(bbData[i].middle!);

      if (first) {
        upperPath.moveTo(x, yu);
        lowerPath.moveTo(x, yl);
        middlePath.moveTo(x, ym);
        fillPath.moveTo(x, yu);
        first = false;
      } else {
        upperPath.lineTo(x, yu);
        lowerPath.lineTo(x, yl);
        middlePath.lineTo(x, ym);
        fillPath.lineTo(x, yu);
      }
    }

    if (!first) {
      for (int i = end; i >= start; i--) {
        if (bbData[i].lower == null) continue;
        final x = (i * stepX) - scrollOffset + stepX / 2;
        final yl = getY(bbData[i].lower!);
        fillPath.lineTo(x, yl);
      }
      fillPath.close();

      canvas.drawPath(fillPath, Paint()..color = Colors.blueAccent.withOpacity(0.1));
      final linePaint = Paint()..color = Colors.blueAccent.withOpacity(0.5)..strokeWidth = 1..style = PaintingStyle.stroke;
      canvas.drawPath(upperPath, linePaint);
      canvas.drawPath(lowerPath, linePaint);
      canvas.drawPath(middlePath, Paint()..color = Colors.orangeAccent.withOpacity(0.6)..strokeWidth = 1..style = PaintingStyle.stroke);
    }
  }

  void _drawVolumeChart(Canvas canvas, double top, double height, double width, int start, int end, double stepX) {
    _drawText(canvas, Offset(8, top + 4), 'VOL', Colors.white54, fontSize: 10);
    double maxVol = 0;
    for (int i = start; i <= end; i++) {
      double vol = candles[i].volume ?? 0;
      if (vol > maxVol) maxVol = vol;
    }
    if (maxVol == 0) return;
    
    final candleWidth = max(2.0, stepX * 0.7);
    for (int i = start; i <= end; i++) {
      final candle = candles[i];
      final vol = candle.volume ?? 0;
      final h = (vol / maxVol) * (height - 10);
      final x = (i * stepX) - scrollOffset + (stepX - candleWidth) / 2;
      final isBull = (candle.close ?? 0) >= (candle.open ?? 0);
      canvas.drawRect(
        Rect.fromLTWH(x, top + height - h, candleWidth, h),
        Paint()..color = isBull ? AppColors.success.withOpacity(0.6) : AppColors.error.withOpacity(0.6),
      );
    }
  }

  void _drawRSIChart(Canvas canvas, double top, double height, double width, int start, int end, double stepX) {
    _drawText(canvas, Offset(8, top + 4), 'RSI(14)', Colors.white54, fontSize: 10);
    final rsiData = IndicatorCalculator.calculateRSI(candles, 14);
    
    final y70 = top + height - (70 / 100) * (height - 10);
    final y30 = top + height - (30 / 100) * (height - 10);
    final linePaint = Paint()..color = Colors.white24..strokeWidth = 1;
    canvas.drawLine(Offset(0, y70), Offset(width, y70), linePaint);
    canvas.drawLine(Offset(0, y30), Offset(width, y30), linePaint);

    final path = Path();
    bool first = true;
    for (int i = start; i <= end; i++) {
      if (rsiData[i] == null) continue;
      final x = (i * stepX) - scrollOffset + stepX / 2;
      final y = top + height - (rsiData[i]! / 100) * (height - 10);
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, Paint()..color = Colors.purpleAccent..strokeWidth = 1.5..style = PaintingStyle.stroke);
  }

  void _drawMACDChart(Canvas canvas, double top, double height, double width, int start, int end, double stepX) {
    _drawText(canvas, Offset(8, top + 4), 'MACD(12,26,9)', Colors.white54, fontSize: 10);
    final macdData = IndicatorCalculator.calculateMACD(candles, 12, 26, 9);
    
    double maxAbs = 0;
    for (int i = start; i <= end; i++) {
      if (macdData[i].macd != null && macdData[i].macd!.abs() > maxAbs) maxAbs = macdData[i].macd!.abs();
      if (macdData[i].signal != null && macdData[i].signal!.abs() > maxAbs) maxAbs = macdData[i].signal!.abs();
      if (macdData[i].histogram != null && macdData[i].histogram!.abs() > maxAbs) maxAbs = macdData[i].histogram!.abs();
    }
    if (maxAbs == 0) return;

    final centerY = top + height / 2;
    canvas.drawLine(Offset(0, centerY), Offset(width, centerY), Paint()..color = Colors.white24..strokeWidth = 1);

    final macdPath = Path();
    final signalPath = Path();
    bool firstMacd = true, firstSignal = true;

    final barWidth = max(1.0, stepX * 0.5);
    for (int i = start; i <= end; i++) {
      final data = macdData[i];
      final x = (i * stepX) - scrollOffset + stepX / 2;
      
      if (data.histogram != null) {
        final h = (data.histogram! / maxAbs) * (height / 2 - 5);
        canvas.drawRect(
          Rect.fromLTWH(x - barWidth / 2, h > 0 ? centerY - h : centerY, barWidth, h.abs()),
          Paint()..color = data.histogram! > 0 ? AppColors.success.withOpacity(0.5) : AppColors.error.withOpacity(0.5),
        );
      }
      
      if (data.macd != null) {
        final y = centerY - (data.macd! / maxAbs) * (height / 2 - 5);
        if (firstMacd) { macdPath.moveTo(x, y); firstMacd = false; } else { macdPath.lineTo(x, y); }
      }
      if (data.signal != null) {
        final y = centerY - (data.signal! / maxAbs) * (height / 2 - 5);
        if (firstSignal) { signalPath.moveTo(x, y); firstSignal = false; } else { signalPath.lineTo(x, y); }
      }
    }
    canvas.drawPath(macdPath, Paint()..color = Colors.blueAccent..strokeWidth = 1.5..style = PaintingStyle.stroke);
    canvas.drawPath(signalPath, Paint()..color = Colors.orangeAccent..strokeWidth = 1.5..style = PaintingStyle.stroke);
  }

  void _drawATRChart(Canvas canvas, double top, double height, double width, int start, int end, double stepX) {
    _drawText(canvas, Offset(8, top + 4), 'ATR(14)', Colors.white54, fontSize: 10);
    final atrData = IndicatorCalculator.calculateATR(candles, 14);
    
    double maxAtr = 0;
    double minAtr = double.infinity;
    for (int i = start; i <= end; i++) {
      if (atrData[i] != null) {
        if (atrData[i]! > maxAtr) maxAtr = atrData[i]!;
        if (atrData[i]! < minAtr) minAtr = atrData[i]!;
      }
    }
    if (maxAtr == 0 || minAtr == double.infinity) return;
    
    final path = Path();
    bool first = true;
    for (int i = start; i <= end; i++) {
      if (atrData[i] == null) continue;
      final x = (i * stepX) - scrollOffset + stepX / 2;
      final y = top + height - 5 - ((atrData[i]! - minAtr) / (maxAtr - minAtr)) * (height - 10);
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, Paint()..color = Colors.cyanAccent..strokeWidth = 1.5..style = PaintingStyle.stroke);
  }

  void _drawStochChart(Canvas canvas, double top, double height, double width, int start, int end, double stepX) {
    _drawText(canvas, Offset(8, top + 4), 'Stoch(14,3,3)', Colors.white54, fontSize: 10);
    final stochData = IndicatorCalculator.calculateStochastic(candles, 14, 3);
    
    final y80 = top + height - (80 / 100) * (height - 10);
    final y20 = top + height - (20 / 100) * (height - 10);
    final linePaint = Paint()..color = Colors.white24..strokeWidth = 1;
    canvas.drawLine(Offset(0, y80), Offset(width, y80), linePaint);
    canvas.drawLine(Offset(0, y20), Offset(width, y20), linePaint);

    final kPath = Path();
    final dPath = Path();
    bool firstK = true, firstD = true;

    for (int i = start; i <= end; i++) {
      final x = (i * stepX) - scrollOffset + stepX / 2;
      if (stochData[i].k != null) {
        final y = top + height - (stochData[i].k! / 100) * (height - 10);
        if (firstK) { kPath.moveTo(x, y); firstK = false; } else { kPath.lineTo(x, y); }
      }
      if (stochData[i].d != null) {
        final y = top + height - (stochData[i].d! / 100) * (height - 10);
        if (firstD) { dPath.moveTo(x, y); firstD = false; } else { dPath.lineTo(x, y); }
      }
    }
    canvas.drawPath(kPath, Paint()..color = Colors.blueAccent..strokeWidth = 1.5..style = PaintingStyle.stroke);
    canvas.drawPath(dPath, Paint()..color = Colors.orangeAccent..strokeWidth = 1.5..style = PaintingStyle.stroke);
  }

  void _drawStochRSIChart(Canvas canvas, double top, double height, double width, int start, int end, double stepX) {
    _drawText(canvas, Offset(8, top + 4), 'Stoch RSI(14,14,3,3)', Colors.white54, fontSize: 10);
    final stochRsiData = IndicatorCalculator.calculateStochRSI(candles, 14, 14, 3, 3);
    
    final y80 = top + height - (80 / 100) * (height - 10);
    final y20 = top + height - (20 / 100) * (height - 10);
    final linePaint = Paint()..color = Colors.white24..strokeWidth = 1;
    canvas.drawLine(Offset(0, y80), Offset(width, y80), linePaint);
    canvas.drawLine(Offset(0, y20), Offset(width, y20), linePaint);

    final kPath = Path();
    final dPath = Path();
    bool firstK = true, firstD = true;

    for (int i = start; i <= end; i++) {
      if (i >= stochRsiData.length) continue;
      final x = (i * stepX) - scrollOffset + stepX / 2;
      if (stochRsiData[i].k != null) {
        final y = top + height - (stochRsiData[i].k! / 100) * (height - 10);
        if (firstK) { kPath.moveTo(x, y); firstK = false; } else { kPath.lineTo(x, y); }
      }
      if (stochRsiData[i].d != null) {
        final y = top + height - (stochRsiData[i].d! / 100) * (height - 10);
        if (firstD) { dPath.moveTo(x, y); firstD = false; } else { dPath.lineTo(x, y); }
      }
    }
    canvas.drawPath(kPath, Paint()..color = Colors.lightBlueAccent..strokeWidth = 1.5..style = PaintingStyle.stroke);
    canvas.drawPath(dPath, Paint()..color = Colors.orangeAccent..strokeWidth = 1.5..style = PaintingStyle.stroke);
  }

  void _drawADXChart(Canvas canvas, double top, double height, double width, int start, int end, double stepX) {
    _drawText(canvas, Offset(8, top + 4), 'ADX(14)', Colors.white54, fontSize: 10);
    final adxData = IndicatorCalculator.calculateADX(candles, 14);
    
    final y25 = top + height - (25 / 100) * (height - 10);
    final linePaint = Paint()..color = Colors.white24..strokeWidth = 1;
    canvas.drawLine(Offset(0, y25), Offset(width, y25), linePaint);

    final adxPath = Path();
    final plusDIPath = Path();
    final minusDIPath = Path();
    bool firstAdx = true, firstPlus = true, firstMinus = true;

    for (int i = start; i <= end; i++) {
      if (i >= adxData.length) continue;
      final x = (i * stepX) - scrollOffset + stepX / 2;
      final data = adxData[i];
      if (data.adx != null) {
        final y = top + height - (data.adx! / 100) * (height - 10);
        if (firstAdx) { adxPath.moveTo(x, y); firstAdx = false; } else { adxPath.lineTo(x, y); }
      }
      if (data.plusDI != null) {
        final y = top + height - (data.plusDI! / 100) * (height - 10);
        if (firstPlus) { plusDIPath.moveTo(x, y); firstPlus = false; } else { plusDIPath.lineTo(x, y); }
      }
      if (data.minusDI != null) {
        final y = top + height - (data.minusDI! / 100) * (height - 10);
        if (firstMinus) { minusDIPath.moveTo(x, y); firstMinus = false; } else { minusDIPath.lineTo(x, y); }
      }
    }
    canvas.drawPath(plusDIPath, Paint()..color = Colors.greenAccent.withOpacity(0.6)..strokeWidth = 1.0..style = PaintingStyle.stroke);
    canvas.drawPath(minusDIPath, Paint()..color = Colors.redAccent.withOpacity(0.6)..strokeWidth = 1.0..style = PaintingStyle.stroke);
    canvas.drawPath(adxPath, Paint()..color = Colors.yellowAccent..strokeWidth = 2.0..style = PaintingStyle.stroke);
  }

  void _drawCCIChart(Canvas canvas, double top, double height, double width, int start, int end, double stepX) {
    _drawText(canvas, Offset(8, top + 4), 'CCI(20)', Colors.white54, fontSize: 10);
    final cciData = IndicatorCalculator.calculateCCI(candles, 20);
    
    double maxAbs = 150.0;
    for (int i = start; i <= end; i++) {
      if (i >= cciData.length) continue;
      if (cciData[i] != null && cciData[i]!.abs() > maxAbs) {
        maxAbs = cciData[i]!.abs();
      }
    }
    
    final centerY = top + height / 2;
    final scaleY = (height / 2 - 5) / maxAbs;
    
    final yPlus100 = centerY - 100.0 * scaleY;
    final yMinus100 = centerY + 100.0 * scaleY;
    
    final linePaint = Paint()..color = Colors.white24..strokeWidth = 1;
    canvas.drawLine(Offset(0, centerY), Offset(width, centerY), linePaint);
    canvas.drawLine(Offset(0, yPlus100), Offset(width, yPlus100), linePaint);
    canvas.drawLine(Offset(0, yMinus100), Offset(width, yMinus100), linePaint);

    final path = Path();
    bool first = true;
    for (int i = start; i <= end; i++) {
      if (i >= cciData.length) continue;
      if (cciData[i] == null) continue;
      final x = (i * stepX) - scrollOffset + stepX / 2;
      final y = centerY - cciData[i]! * scaleY;
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, Paint()..color = Colors.amberAccent..strokeWidth = 1.5..style = PaintingStyle.stroke);
  }

  void _drawVWAPOverlay(Canvas canvas, double Function(double) getY, int start, int end, double stepX) {
    _drawText(canvas, const Offset(8, 20), 'VWAP', Colors.blue.withOpacity(0.85), fontSize: 10);
    final vwapData = IndicatorCalculator.calculateVWAP(candles);

    final path = Path();
    bool first = true;
    for (int i = start; i <= end; i++) {
      if (i >= vwapData.length) continue;
      if (vwapData[i] == null) continue;
      final x = (i * stepX) - scrollOffset + stepX / 2;
      final y = getY(vwapData[i]!);
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, Paint()..color = Colors.blue..strokeWidth = 1.8..style = PaintingStyle.stroke);
  }

  void _drawIchimokuOverlay(Canvas canvas, double Function(double) getY, int start, int end, double stepX) {
    _drawText(canvas, const Offset(8, 32), 'Ichimoku(9,26,52)', Colors.cyanAccent.withOpacity(0.85), fontSize: 10);
    final ichimokuData = IndicatorCalculator.calculateIchimoku(candles);

    final tenkanPath = Path();
    final kijunPath = Path();
    final spanAPath = Path();
    final spanBPath = Path();
    final chikouPath = Path();

    bool firstTenkan = true, firstKijun = true, firstSpanA = true, firstSpanB = true, firstChikou = true;

    final List<Offset> spanAPoints = [];
    final List<Offset> spanBPoints = [];

    for (int i = start; i <= end; i++) {
      if (i >= ichimokuData.length) continue;
      final data = ichimokuData[i];
      final x = (i * stepX) - scrollOffset + stepX / 2;

      if (data.tenkan != null) {
        final y = getY(data.tenkan!);
        if (firstTenkan) { tenkanPath.moveTo(x, y); firstTenkan = false; } else { tenkanPath.lineTo(x, y); }
      }
      if (data.kijun != null) {
        final y = getY(data.kijun!);
        if (firstKijun) { kijunPath.moveTo(x, y); firstKijun = false; } else { kijunPath.lineTo(x, y); }
      }
      if (data.senkouA != null) {
        final y = getY(data.senkouA!);
        spanAPoints.add(Offset(x, y));
        if (firstSpanA) { spanAPath.moveTo(x, y); firstSpanA = false; } else { spanAPath.lineTo(x, y); }
      }
      if (data.senkouB != null) {
        final y = getY(data.senkouB!);
        spanBPoints.add(Offset(x, y));
        if (firstSpanB) { spanBPath.moveTo(x, y); firstSpanB = false; } else { spanBPath.lineTo(x, y); }
      }
      if (data.chikou != null) {
        final y = getY(data.chikou!);
        if (firstChikou) { chikouPath.moveTo(x, y); firstChikou = false; } else { chikouPath.lineTo(x, y); }
      }
    }

    if (spanAPoints.isNotEmpty && spanBPoints.isNotEmpty && spanAPoints.length == spanBPoints.length) {
      final cloudPaintBull = Paint()..color = Colors.green.withOpacity(0.06)..style = PaintingStyle.fill;
      final cloudPaintBear = Paint()..color = Colors.red.withOpacity(0.06)..style = PaintingStyle.fill;

      for (int i = 0; i < spanAPoints.length - 1; i++) {
        final pA1 = spanAPoints[i];
        final pA2 = spanAPoints[i + 1];
        final pB1 = spanBPoints[i];
        final pB2 = spanBPoints[i + 1];

        final path = Path()
          ..moveTo(pA1.dx, pA1.dy)
          ..lineTo(pA2.dx, pA2.dy)
          ..lineTo(pB2.dx, pB2.dy)
          ..lineTo(pB1.dx, pB1.dy)
          ..close();

        final isBullish = pA1.dy < pB1.dy;
        canvas.drawPath(path, isBullish ? cloudPaintBull : cloudPaintBear);
      }
    }

    canvas.drawPath(tenkanPath, Paint()..color = Colors.blueAccent.withOpacity(0.9)..strokeWidth = 1.0..style = PaintingStyle.stroke);
    canvas.drawPath(kijunPath, Paint()..color = Colors.redAccent.withOpacity(0.9)..strokeWidth = 1.0..style = PaintingStyle.stroke);
    canvas.drawPath(spanAPath, Paint()..color = Colors.green.withOpacity(0.5)..strokeWidth = 1.0..style = PaintingStyle.stroke);
    canvas.drawPath(spanBPath, Paint()..color = Colors.red.withOpacity(0.5)..strokeWidth = 1.0..style = PaintingStyle.stroke);
    canvas.drawPath(chikouPath, Paint()..color = Colors.purple.withOpacity(0.4)..strokeWidth = 1.0..style = PaintingStyle.stroke);
  }

  void _drawSuperTrendOverlay(Canvas canvas, double Function(double) getY, int start, int end, double stepX) {
    _drawText(canvas, const Offset(8, 44), 'SuperTrend(10,3)', Colors.greenAccent.withOpacity(0.85), fontSize: 10);
    final superTrendData = IndicatorCalculator.calculateSuperTrend(candles, 10, 3.0);

    for (int i = start; i < end; i++) {
      if (i >= superTrendData.length - 1 || i < 10) continue;
      final data1 = superTrendData[i];
      final data2 = superTrendData[i + 1];

      if (data1.value == null || data2.value == null) continue;

      final x1 = (i * stepX) - scrollOffset + stepX / 2;
      final x2 = ((i + 1) * stepX) - scrollOffset + stepX / 2;
      final y1 = getY(data1.value!);
      final y2 = getY(data2.value!);

      final trendPaint = Paint()
        ..color = data1.trend == 1 ? Colors.green : Colors.red
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), trendPaint);
    }
  }

  void _drawParabolicSarOverlay(Canvas canvas, double Function(double) getY, int start, int end, double stepX) {
    _drawText(canvas, const Offset(8, 56), 'SAR(0.02,0.2)', Colors.pinkAccent.withOpacity(0.85), fontSize: 10);
    final sarData = IndicatorCalculator.calculateParabolicSar(candles);

    final dotPaintUp = Paint()..color = Colors.greenAccent..style = PaintingStyle.fill;
    final dotPaintDown = Paint()..color = Colors.redAccent..style = PaintingStyle.fill;

    for (int i = start; i <= end; i++) {
      if (i >= sarData.length) continue;
      if (sarData[i].sar == null) continue;

      final x = (i * stepX) - scrollOffset + stepX / 2;
      final y = getY(sarData[i].sar!);

      canvas.drawCircle(Offset(x, y), 2.0, sarData[i].isUp ? dotPaintUp : dotPaintDown);
    }
  }

  void _drawWilliamsRChart(Canvas canvas, double top, double height, double width, int start, int end, double stepX) {
    _drawText(canvas, Offset(8, top + 4), 'Williams %R(14)', Colors.white54, fontSize: 10);
    final wrData = IndicatorCalculator.calculateWilliamsR(candles, 14);

    final y20 = top + height - (80 / 100) * (height - 10);
    final y80 = top + height - (20 / 100) * (height - 10);

    final linePaint = Paint()..color = Colors.white24..strokeWidth = 1;
    canvas.drawLine(Offset(0, y20), Offset(width, y20), linePaint);
    canvas.drawLine(Offset(0, y80), Offset(width, y80), linePaint);

    final path = Path();
    bool first = true;
    for (int i = start; i <= end; i++) {
      if (i >= wrData.length) continue;
      if (wrData[i] == null) continue;
      final x = (i * stepX) - scrollOffset + stepX / 2;
      final percent = (wrData[i]! + 100.0);
      final y = top + height - (percent / 100.0) * (height - 10);
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, Paint()..color = Colors.pinkAccent..strokeWidth = 1.5..style = PaintingStyle.stroke);
  }

  void _drawROCChart(Canvas canvas, double top, double height, double width, int start, int end, double stepX) {
    _drawText(canvas, Offset(8, top + 4), 'ROC(9)', Colors.white54, fontSize: 10);
    final rocData = IndicatorCalculator.calculateROC(candles, 9);

    double maxAbs = 5.0;
    for (int i = start; i <= end; i++) {
      if (i >= rocData.length) continue;
      if (rocData[i] != null && rocData[i]!.abs() > maxAbs) {
        maxAbs = rocData[i]!.abs();
      }
    }

    final centerY = top + height / 2;
    final scaleY = (height / 2 - 5) / maxAbs;

    final linePaint = Paint()..color = Colors.white24..strokeWidth = 1;
    canvas.drawLine(Offset(0, centerY), Offset(width, centerY), linePaint);

    final path = Path();
    bool first = true;
    for (int i = start; i <= end; i++) {
      if (i >= rocData.length) continue;
      if (rocData[i] == null) continue;
      final x = (i * stepX) - scrollOffset + stepX / 2;
      final y = centerY - rocData[i]! * scaleY;
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, Paint()..color = Colors.greenAccent..strokeWidth = 1.5..style = PaintingStyle.stroke);
  }

  void _drawOBVChart(Canvas canvas, double top, double height, double width, int start, int end, double stepX) {
    _drawText(canvas, Offset(8, top + 4), 'OBV', Colors.white54, fontSize: 10);
    final obvData = IndicatorCalculator.calculateOBV(candles);

    double maxObv = double.negativeInfinity;
    double minObv = double.infinity;
    for (int i = start; i <= end; i++) {
      if (i >= obvData.length) continue;
      if (obvData[i] != null) {
        if (obvData[i]! > maxObv) maxObv = obvData[i]!;
        if (obvData[i]! < minObv) minObv = obvData[i]!;
      }
    }

    if (maxObv == double.negativeInfinity || minObv == double.infinity) return;
    final double range = maxObv - minObv;
    final double scaleY = (height - 10) / (range == 0.0 ? 1.0 : range);

    final path = Path();
    bool first = true;
    for (int i = start; i <= end; i++) {
      if (i >= obvData.length) continue;
      if (obvData[i] == null) continue;
      final x = (i * stepX) - scrollOffset + stepX / 2;
      final y = top + height - 5 - (obvData[i]! - minObv) * scaleY;
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, Paint()..color = Colors.lightBlueAccent..strokeWidth = 1.5..style = PaintingStyle.stroke);
  }

  void _drawMFIChart(Canvas canvas, double top, double height, double width, int start, int end, double stepX) {
    _drawText(canvas, Offset(8, top + 4), 'MFI(14)', Colors.white54, fontSize: 10);
    final mfiData = IndicatorCalculator.calculateMFI(candles, 14);

    final y80 = top + height - (80 / 100) * (height - 10);
    final y20 = top + height - (20 / 100) * (height - 10);
    final linePaint = Paint()..color = Colors.white24..strokeWidth = 1;
    canvas.drawLine(Offset(0, y80), Offset(width, y80), linePaint);
    canvas.drawLine(Offset(0, y20), Offset(width, y20), linePaint);

    final path = Path();
    bool first = true;
    for (int i = start; i <= end; i++) {
      if (i >= mfiData.length) continue;
      if (mfiData[i] == null) continue;
      final x = (i * stepX) - scrollOffset + stepX / 2;
      final y = top + height - (mfiData[i]! / 100.0) * (height - 10);
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, Paint()..color = Colors.tealAccent..strokeWidth = 1.5..style = PaintingStyle.stroke);
  }

  void _drawAroonChart(Canvas canvas, double top, double height, double width, int start, int end, double stepX) {
    _drawText(canvas, Offset(8, top + 4), 'Aroon(25)', Colors.white54, fontSize: 10);
    final aroonData = IndicatorCalculator.calculateAroon(candles, 25);

    final y50 = top + height - (50 / 100) * (height - 10);
    final linePaint = Paint()..color = Colors.white24..strokeWidth = 1;
    canvas.drawLine(Offset(0, y50), Offset(width, y50), linePaint);

    final upPath = Path();
    final downPath = Path();
    bool firstUp = true, firstDown = true;

    for (int i = start; i <= end; i++) {
      if (i >= aroonData.length) continue;
      final x = (i * stepX) - scrollOffset + stepX / 2;
      final data = aroonData[i];

      if (data.up != null) {
        final y = top + height - (data.up! / 100.0) * (height - 10);
        if (firstUp) { upPath.moveTo(x, y); firstUp = false; } else { upPath.lineTo(x, y); }
      }
      if (data.down != null) {
        final y = top + height - (data.down! / 100.0) * (height - 10);
        if (firstDown) { downPath.moveTo(x, y); firstDown = false; } else { downPath.lineTo(x, y); }
      }
    }
    canvas.drawPath(upPath, Paint()..color = Colors.greenAccent..strokeWidth = 1.3..style = PaintingStyle.stroke);
    canvas.drawPath(downPath, Paint()..color = Colors.redAccent..strokeWidth = 1.3..style = PaintingStyle.stroke);
  }

  void _drawUOChart(Canvas canvas, double top, double height, double width, int start, int end, double stepX) {
    _drawText(canvas, Offset(8, top + 4), 'UO(7,14,28)', Colors.white54, fontSize: 10);
    final uoData = IndicatorCalculator.calculateUltimateOscillator(candles);

    final y70 = top + height - (70 / 100) * (height - 10);
    final y30 = top + height - (30 / 100) * (height - 10);
    final linePaint = Paint()..color = Colors.white24..strokeWidth = 1;
    canvas.drawLine(Offset(0, y70), Offset(width, y70), linePaint);
    canvas.drawLine(Offset(0, y30), Offset(width, y30), linePaint);

    final path = Path();
    bool first = true;
    for (int i = start; i <= end; i++) {
      if (i >= uoData.length) continue;
      if (uoData[i] == null) continue;
      final x = (i * stepX) - scrollOffset + stepX / 2;
      final y = top + height - (uoData[i]! / 100.0) * (height - 10);
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, Paint()..color = Colors.deepPurpleAccent..strokeWidth = 1.5..style = PaintingStyle.stroke);
  }

  void _drawSubChartMA(Canvas canvas, double top, double height, double width, int start, int end, double stepX, List<double?> maData, Color color, String name) {
    _drawText(canvas, Offset(8, top + 4), '$name(20)', color.withOpacity(0.8), fontSize: 10);
    
    double maxVal = double.negativeInfinity;
    double minVal = double.infinity;
    for (int i = start; i <= end; i++) {
      if (maData[i] != null) {
        if (maData[i]! > maxVal) maxVal = maData[i]!;
        if (maData[i]! < minVal) minVal = maData[i]!;
      }
    }
    
    if (maxVal == double.negativeInfinity) return;
    if (maxVal == minVal) {
      maxVal += 1;
      minVal -= 1;
    }
    
    final range = maxVal - minVal;
    final scaleY = (height - 20) / range;
    
    double getLocalY(double val) => top + height - 10 - (val - minVal) * scaleY;
    
    _drawMALine(canvas, getLocalY, start, end, stepX, maData, color);
  }

  void _drawSubChartBB(Canvas canvas, double top, double height, double width, int start, int end, double stepX, List<BollingerBandValue> bbData) {
    _drawText(canvas, Offset(8, top + 4), 'BB(20,2.0)', Colors.white54, fontSize: 10);
    
    double maxVal = double.negativeInfinity;
    double minVal = double.infinity;
    for (int i = start; i <= end; i++) {
      if (bbData[i].upper != null) {
        if (bbData[i].upper! > maxVal) maxVal = bbData[i].upper!;
      }
      if (bbData[i].lower != null) {
        if (bbData[i].lower! < minVal) minVal = bbData[i].lower!;
      }
    }
    
    if (maxVal == double.negativeInfinity) return;
    if (maxVal == minVal) {
      maxVal += 1;
      minVal -= 1;
    }
    
    final range = maxVal - minVal;
    final scaleY = (height - 20) / range;
    
    double getLocalY(double val) => top + height - 10 - (val - minVal) * scaleY;
    
    _drawBollingerBands(canvas, getLocalY, start, end, stepX, bbData);
  }

  void _drawDonchianChannelsOverlay(Canvas canvas, double Function(double) getY, int start, int end, double stepX) {
    final dcData = IndicatorCalculator.calculateDonchianChannels(candles, 20);
    final upperPath = Path();
    final lowerPath = Path();
    final middlePath = Path();
    final fillPath = Path();
    bool first = true;

    for (int i = start; i <= end; i++) {
      if (i >= dcData.length) continue;
      final val = dcData[i];
      if (val.upper == null || val.lower == null || val.middle == null) continue;
      final x = (i * stepX) - scrollOffset + stepX / 2;
      final yu = getY(val.upper!);
      final yl = getY(val.lower!);
      final ym = getY(val.middle!);

      if (first) {
        upperPath.moveTo(x, yu);
        lowerPath.moveTo(x, yl);
        middlePath.moveTo(x, ym);
        fillPath.moveTo(x, yu);
        first = false;
      } else {
        upperPath.lineTo(x, yu);
        lowerPath.lineTo(x, yl);
        middlePath.lineTo(x, ym);
        fillPath.lineTo(x, yu);
      }
    }

    if (!first) {
      for (int i = end; i >= start; i--) {
        if (i >= dcData.length || dcData[i].lower == null) continue;
        final x = (i * stepX) - scrollOffset + stepX / 2;
        final yl = getY(dcData[i].lower!);
        fillPath.lineTo(x, yl);
      }
      fillPath.close();

      canvas.drawPath(fillPath, Paint()..color = Colors.cyan.withOpacity(0.05));
      final linePaint = Paint()..color = Colors.cyan.withOpacity(0.5)..strokeWidth = 1..style = PaintingStyle.stroke;
      canvas.drawPath(upperPath, linePaint);
      canvas.drawPath(lowerPath, linePaint);
      canvas.drawPath(middlePath, Paint()..color = Colors.orangeAccent.withOpacity(0.5)..strokeWidth = 1..style = PaintingStyle.stroke);
    }
  }

  void _drawKeltnerChannelsOverlay(Canvas canvas, double Function(double) getY, int start, int end, double stepX) {
    final kcData = IndicatorCalculator.calculateKeltnerChannels(candles, 20, 1.5);
    final upperPath = Path();
    final lowerPath = Path();
    final middlePath = Path();
    final fillPath = Path();
    bool first = true;

    for (int i = start; i <= end; i++) {
      if (i >= kcData.length) continue;
      final val = kcData[i];
      if (val.upper == null || val.lower == null || val.middle == null) continue;
      final x = (i * stepX) - scrollOffset + stepX / 2;
      final yu = getY(val.upper!);
      final yl = getY(val.lower!);
      final ym = getY(val.middle!);

      if (first) {
        upperPath.moveTo(x, yu);
        lowerPath.moveTo(x, yl);
        middlePath.moveTo(x, ym);
        fillPath.moveTo(x, yu);
        first = false;
      } else {
        upperPath.lineTo(x, yu);
        lowerPath.lineTo(x, yl);
        middlePath.lineTo(x, ym);
        fillPath.lineTo(x, yu);
      }
    }

    if (!first) {
      for (int i = end; i >= start; i--) {
        if (i >= kcData.length || kcData[i].lower == null) continue;
        final x = (i * stepX) - scrollOffset + stepX / 2;
        final yl = getY(kcData[i].lower!);
        fillPath.lineTo(x, yl);
      }
      fillPath.close();

      canvas.drawPath(fillPath, Paint()..color = Colors.indigoAccent.withOpacity(0.05));
      final linePaint = Paint()..color = Colors.indigoAccent.withOpacity(0.5)..strokeWidth = 1..style = PaintingStyle.stroke;
      canvas.drawPath(upperPath, linePaint);
      canvas.drawPath(lowerPath, linePaint);
      canvas.drawPath(middlePath, Paint()..color = Colors.orangeAccent.withOpacity(0.5)..strokeWidth = 1..style = PaintingStyle.stroke);
    }
  }

  void _drawFibonacciRetracementOverlay(Canvas canvas, double Function(double) getY, double chartWidth, int start, int end) {
    double visibleHigh = double.negativeInfinity;
    double visibleLow = double.infinity;
    for (int i = start; i <= end; i++) {
      if (i >= candles.length) continue;
      final high = candles[i].high ?? 0.0;
      final low = candles[i].low ?? 0.0;
      if (high > visibleHigh) visibleHigh = high;
      if (low < visibleLow) visibleLow = low;
    }

    if (visibleHigh == double.negativeInfinity || visibleLow == double.infinity || visibleHigh == visibleLow) return;

    final diff = visibleHigh - visibleLow;
    final levels = {
      0.0: '0.0%',
      0.236: '23.6%',
      0.382: '38.2%',
      0.5: '50.0%',
      0.618: '61.8%',
      0.786: '78.6%',
      1.0: '100.0%',
    };

    final linePaint = Paint()
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    levels.forEach((ratio, label) {
      final price = visibleHigh - ratio * diff;
      final y = getY(price);

      Color color;
      if (ratio == 0.0 || ratio == 1.0) {
        color = Colors.amber.withOpacity(0.5);
      } else if (ratio == 0.5 || ratio == 0.618) {
        color = Colors.redAccent.withOpacity(0.5);
      } else {
        color = Colors.blueAccent.withOpacity(0.4);
      }

      linePaint.color = color;
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), linePaint);

      final textOffset = Offset(8, y - 12);
      _drawText(canvas, textOffset, '$label (${price.toStringAsFixed(2)})', color.withOpacity(0.8), fontSize: 9);
    });
  }

  void _drawPivotPointsOverlay(Canvas canvas, double Function(double) getY, int start, int end, double stepX) {
    final pivotData = IndicatorCalculator.calculatePivotPoints(candles);

    final pPath = Path();
    final r1Path = Path();
    final s1Path = Path();
    final r2Path = Path();
    final s2Path = Path();
    final r3Path = Path();
    final s3Path = Path();

    bool first = true;

    for (int i = start; i <= end; i++) {
      if (i >= pivotData.length) continue;
      final val = pivotData[i];
      final x = (i * stepX) - scrollOffset + stepX / 2;

      if (first) {
        if (val.p != null) pPath.moveTo(x, getY(val.p!));
        if (val.r1 != null) r1Path.moveTo(x, getY(val.r1!));
        if (val.s1 != null) s1Path.moveTo(x, getY(val.s1!));
        if (val.r2 != null) r2Path.moveTo(x, getY(val.r2!));
        if (val.s2 != null) s2Path.moveTo(x, getY(val.s2!));
        if (val.r3 != null) r3Path.moveTo(x, getY(val.r3!));
        if (val.s3 != null) s3Path.moveTo(x, getY(val.s3!));
        first = false;
      } else {
        if (val.p != null) pPath.lineTo(x, getY(val.p!));
        if (val.r1 != null) r1Path.lineTo(x, getY(val.r1!));
        if (val.s1 != null) s1Path.lineTo(x, getY(val.s1!));
        if (val.r2 != null) r2Path.lineTo(x, getY(val.r2!));
        if (val.s2 != null) s2Path.lineTo(x, getY(val.s2!));
        if (val.r3 != null) r3Path.lineTo(x, getY(val.r3!));
        if (val.s3 != null) s3Path.lineTo(x, getY(val.s3!));
      }
    }

    final pPaint = Paint()..color = Colors.amber.withOpacity(0.5)..strokeWidth = 1..style = PaintingStyle.stroke;
    final rPaint = Paint()..color = Colors.redAccent.withOpacity(0.4)..strokeWidth = 1..style = PaintingStyle.stroke;
    final sPaint = Paint()..color = Colors.greenAccent.withOpacity(0.4)..strokeWidth = 1..style = PaintingStyle.stroke;

    canvas.drawPath(pPath, pPaint);
    canvas.drawPath(r1Path, rPaint);
    canvas.drawPath(r2Path, rPaint);
    canvas.drawPath(r3Path, rPaint);
    canvas.drawPath(s1Path, sPaint);
    canvas.drawPath(s2Path, sPaint);
    canvas.drawPath(s3Path, sPaint);

    if (end < pivotData.length) {
      final lastVal = pivotData[end];
      final labelX = (end * stepX) - scrollOffset + stepX + 4;
      if (lastVal.p != null) _drawText(canvas, Offset(labelX, getY(lastVal.p!) - 6), 'P', Colors.amber, fontSize: 9);
      if (lastVal.r1 != null) _drawText(canvas, Offset(labelX, getY(lastVal.r1!) - 6), 'R1', Colors.redAccent, fontSize: 9);
      if (lastVal.r2 != null) _drawText(canvas, Offset(labelX, getY(lastVal.r2!) - 6), 'R2', Colors.redAccent, fontSize: 9);
      if (lastVal.r3 != null) _drawText(canvas, Offset(labelX, getY(lastVal.r3!) - 6), 'R3', Colors.redAccent, fontSize: 9);
      if (lastVal.s1 != null) _drawText(canvas, Offset(labelX, getY(lastVal.s1!) - 6), 'S1', Colors.greenAccent, fontSize: 9);
      if (lastVal.s2 != null) _drawText(canvas, Offset(labelX, getY(lastVal.s2!) - 6), 'S2', Colors.greenAccent, fontSize: 9);
      if (lastVal.s3 != null) _drawText(canvas, Offset(labelX, getY(lastVal.s3!) - 6), 'S3', Colors.greenAccent, fontSize: 9);
    }
  }

  void _drawVolumeProfileOverlay(Canvas canvas, double Function(double) getY, double chartWidth, double mainChartHeight, int start, int end) {
    double visibleHigh = double.negativeInfinity;
    double visibleLow = double.infinity;
    for (int i = start; i <= end; i++) {
      if (i >= candles.length) continue;
      final high = candles[i].high ?? 0.0;
      final low = candles[i].low ?? 0.0;
      if (high > visibleHigh) visibleHigh = high;
      if (low < visibleLow) visibleLow = low;
    }

    if (visibleHigh == double.negativeInfinity || visibleLow == double.infinity || visibleHigh == visibleLow) return;

    const int numBins = 25;
    final double binSize = (visibleHigh - visibleLow) / numBins;
    final List<double> binVolumes = List.filled(numBins, 0.0);

    for (int i = start; i <= end; i++) {
      if (i >= candles.length) continue;
      final candle = candles[i];
      final price = ((candle.high ?? 0.0) + (candle.low ?? 0.0) + (candle.close ?? 0.0)) / 3.0;
      final vol = (candle.volume ?? 0.0).toDouble();

      final int binIndex = ((price - visibleLow) / binSize).floor().clamp(0, numBins - 1);
      binVolumes[binIndex] += vol;
    }

    double maxBinVol = 0.0;
    for (final v in binVolumes) {
      if (v > maxBinVol) maxBinVol = v;
    }
    if (maxBinVol == 0.0) return;

    final maxBarWidth = chartWidth * 0.25;
    final barPaint = Paint()
      ..color = AppColors.unlockBlue.withOpacity(0.12)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = AppColors.unlockBlue.withOpacity(0.25)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < numBins; i++) {
      final double vol = binVolumes[i];
      if (vol == 0.0) continue;

      final double lowPrice = visibleLow + i * binSize;
      final double highPrice = visibleLow + (i + 1) * binSize;

      final double yTop = getY(highPrice);
      final double yBottom = getY(lowPrice);
      final double barHeight = (yBottom - yTop).abs();

      final double barWidth = (vol / maxBinVol) * maxBarWidth;
      final double x = chartWidth - barWidth;

      final rect = Rect.fromLTWH(x, yTop, barWidth, barHeight);
      canvas.drawRect(rect, barPaint);
      canvas.drawRect(rect, borderPaint);
    }
  }

  void _drawBullBearChart(Canvas canvas, double top, double height, double width, int start, int end, double stepX) {
    _drawText(canvas, Offset(8, top + 4), 'Bull/Bear Power(13)', Colors.white54, fontSize: 10);
    final data = IndicatorCalculator.calculateBullBearPower(candles, 13);

    double maxVal = double.negativeInfinity;
    double minVal = double.infinity;
    for (int i = start; i <= end; i++) {
      if (i >= data.length) continue;
      final val = data[i];
      if (val.bull != null) {
        if (val.bull! > maxVal) maxVal = val.bull!;
        if (val.bull! < minVal) minVal = val.bull!;
      }
      if (val.bear != null) {
        if (val.bear! > maxVal) maxVal = val.bear!;
        if (val.bear! < minVal) minVal = val.bear!;
      }
    }

    if (maxVal == double.negativeInfinity) return;
    if (minVal > 0) minVal = 0;
    if (maxVal < 0) maxVal = 0;
    if (maxVal == minVal) {
      maxVal += 1;
      minVal -= 1;
    }

    final range = maxVal - minVal;
    final scaleY = (height - 20) / range;
    double getLocalY(double val) => top + height - 10 - (val - minVal) * scaleY;

    final centerY = getLocalY(0.0);
    canvas.drawLine(Offset(0, centerY), Offset(width, centerY), Paint()..color = Colors.white24..strokeWidth = 1);

    final bullPath = Path();
    final bearPath = Path();
    bool firstBull = true, firstBear = true;

    for (int i = start; i <= end; i++) {
      if (i >= data.length) continue;
      final val = data[i];
      final x = (i * stepX) - scrollOffset + stepX / 2;

      if (val.bull != null) {
        final y = getLocalY(val.bull!);
        if (firstBull) {
          bullPath.moveTo(x, y);
          firstBull = false;
        } else {
          bullPath.lineTo(x, y);
        }
      }
      if (val.bear != null) {
        final y = getLocalY(val.bear!);
        if (firstBear) {
          bearPath.moveTo(x, y);
          firstBear = false;
        } else {
          bearPath.lineTo(x, y);
        }
      }
    }

    canvas.drawPath(bullPath, Paint()..color = Colors.greenAccent.withOpacity(0.8)..strokeWidth = 1.5..style = PaintingStyle.stroke);
    canvas.drawPath(bearPath, Paint()..color = Colors.redAccent.withOpacity(0.8)..strokeWidth = 1.5..style = PaintingStyle.stroke);
  }

  void _drawADLChart(Canvas canvas, double top, double height, double width, int start, int end, double stepX) {
    _drawText(canvas, Offset(8, top + 4), 'ADL', Colors.white54, fontSize: 10);
    final data = IndicatorCalculator.calculateADL(candles);

    double maxVal = double.negativeInfinity;
    double minVal = double.infinity;
    for (int i = start; i <= end; i++) {
      if (i >= data.length) continue;
      final val = data[i];
      if (val != null) {
        if (val > maxVal) maxVal = val;
        if (val < minVal) minVal = val;
      }
    }

    if (maxVal == double.negativeInfinity) return;
    if (maxVal == minVal) {
      maxVal += 1;
      minVal -= 1;
    }

    final range = maxVal - minVal;
    final scaleY = (height - 20) / range;
    double getLocalY(double val) => top + height - 10 - (val - minVal) * scaleY;

    final path = Path();
    bool first = true;
    for (int i = start; i <= end; i++) {
      if (i >= data.length || data[i] == null) continue;
      final x = (i * stepX) - scrollOffset + stepX / 2;
      final y = getLocalY(data[i]!);

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, Paint()..color = Colors.yellowAccent.withOpacity(0.85)..strokeWidth = 1.5..style = PaintingStyle.stroke);
  }

  void _drawCMFChart(Canvas canvas, double top, double height, double width, int start, int end, double stepX) {
    _drawText(canvas, Offset(8, top + 4), 'CMF(20)', Colors.white54, fontSize: 10);
    final data = IndicatorCalculator.calculateCMF(candles, 20);

    double maxVal = 0.1;
    double minVal = -0.1;
    for (int i = start; i <= end; i++) {
      if (i >= data.length) continue;
      final val = data[i];
      if (val != null) {
        if (val > maxVal) maxVal = val;
        if (val < minVal) minVal = val;
      }
    }

    final range = maxVal - minVal;
    final scaleY = (height - 20) / range;
    double getLocalY(double val) => top + height - 10 - (val - minVal) * scaleY;

    final centerY = getLocalY(0.0);
    canvas.drawLine(Offset(0, centerY), Offset(width, centerY), Paint()..color = Colors.white24..strokeWidth = 1);

    final path = Path();
    bool first = true;
    for (int i = start; i <= end; i++) {
      if (i >= data.length || data[i] == null) continue;
      final x = (i * stepX) - scrollOffset + stepX / 2;
      final y = getLocalY(data[i]!);

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, Paint()..color = Colors.greenAccent..strokeWidth = 1.5..style = PaintingStyle.stroke);
  }

  void _drawDPOChart(Canvas canvas, double top, double height, double width, int start, int end, double stepX) {
    _drawText(canvas, Offset(8, top + 4), 'DPO(20)', Colors.white54, fontSize: 10);
    final data = IndicatorCalculator.calculateDPO(candles, 20);

    double maxVal = double.negativeInfinity;
    double minVal = double.infinity;
    for (int i = start; i <= end; i++) {
      if (i >= data.length) continue;
      final val = data[i];
      if (val != null) {
        if (val > maxVal) maxVal = val;
        if (val < minVal) minVal = val;
      }
    }

    if (maxVal == double.negativeInfinity) return;
    if (minVal > 0) minVal = 0;
    if (maxVal < 0) maxVal = 0;
    if (maxVal == minVal) {
      maxVal += 1;
      minVal -= 1;
    }

    final range = maxVal - minVal;
    final scaleY = (height - 20) / range;
    double getLocalY(double val) => top + height - 10 - (val - minVal) * scaleY;

    final centerY = getLocalY(0.0);
    canvas.drawLine(Offset(0, centerY), Offset(width, centerY), Paint()..color = Colors.white24..strokeWidth = 1);

    final path = Path();
    bool first = true;
    for (int i = start; i <= end; i++) {
      if (i >= data.length || data[i] == null) continue;
      final x = (i * stepX) - scrollOffset + stepX / 2;
      final y = getLocalY(data[i]!);

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, Paint()..color = Colors.pinkAccent..strokeWidth = 1.5..style = PaintingStyle.stroke);
  }

  void _drawSTCChart(Canvas canvas, double top, double height, double width, int start, int end, double stepX) {
    _drawText(canvas, Offset(8, top + 4), 'STC(23,50,10,3)', Colors.white54, fontSize: 10);
    final data = IndicatorCalculator.calculateSTC(candles, 23, 50, 10, 3);

    final y80 = top + height - 10 - (80 / 100) * (height - 20);
    final y20 = top + height - 10 - (20 / 100) * (height - 20);
    final linePaint = Paint()..color = Colors.white24..strokeWidth = 1;
    canvas.drawLine(Offset(0, y80), Offset(width, y80), linePaint);
    canvas.drawLine(Offset(0, y20), Offset(width, y20), linePaint);

    final path = Path();
    bool first = true;
    for (int i = start; i <= end; i++) {
      if (i >= data.length || data[i] == null) continue;
      final x = (i * stepX) - scrollOffset + stepX / 2;
      final y = top + height - 10 - (data[i]! / 100) * (height - 20);

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, Paint()..color = Colors.lightGreenAccent..strokeWidth = 1.5..style = PaintingStyle.stroke);
  }

  void _drawText(
    Canvas canvas,
    Offset offset,
    String text,
    Color color, {
    bool isBold = false,
    double fontSize = 13,
  }) {
    final span = TextSpan(
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      ),
      text: text,
    );
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.scrollOffset != scrollOffset ||
      oldDelegate.mode != mode ||
      oldDelegate.candles != candles ||
      oldDelegate.period != period ||
      oldDelegate.activeIndicators != activeIndicators ||
      oldDelegate.interval != interval ||
      oldDelegate.drawings != drawings ||
      oldDelegate.tempPoints != tempPoints ||
      oldDelegate.activeDrawingTool != activeDrawingTool;
}

class UserDrawing {
  final String id;
  final String type;
  final List<DrawingPoint> points;

  UserDrawing({
    required this.id,
    required this.type,
    required this.points,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'points': points.map((p) => p.toJson()).toList(),
      };

  factory UserDrawing.fromJson(Map<String, dynamic> json) {
    return UserDrawing(
      id: json['id'] as String,
      type: json['type'] as String,
      points: (json['points'] as List)
          .map((p) => DrawingPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DrawingPoint {
  final int timestamp;
  final double price;

  DrawingPoint({
    required this.timestamp,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'price': price,
      };

  factory DrawingPoint.fromJson(Map<String, dynamic> json) {
    return DrawingPoint(
      timestamp: json['timestamp'] as int,
      price: (json['price'] as num).toDouble(),
    );
  }
}
