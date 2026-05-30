import 'dart:math';
import 'package:flutter/material.dart';
import 'package:interactive_chart/interactive_chart.dart'; // For CandleData model
import 'package:green_rabbit/core/theme/app_colors.dart';
import 'package:intl/intl.dart' hide TextDirection;

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
  });

  @override
  State<ProTradingChart> createState() => _ProTradingChartState();
}

class _ProTradingChartState extends State<ProTradingChart> {
  double _scrollOffset = -1.0; // -1 indicates "needs initialization"
  double _zoomLevel = 1.0;
  double _baseZoomLevel = 1.0;

  @override
  void didUpdateWidget(ProTradingChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset scroll when data changes (period/interval switch)
    if (oldWidget.period != widget.period || oldWidget.interval != widget.interval || (oldWidget.candles.isEmpty && widget.candles.isNotEmpty)) {
      _scrollOffset = -1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Error state ---
    if (widget.errorMessage != null) {
      return _buildErrorState(widget.errorMessage!);
    }

    // --- Loading state ---
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.unlockBlue));
    }

    // --- Empty state ---
    if (widget.candles.isEmpty) {
      return _buildEmptyState();
    }

    // Last candle for live legend values
    final last = widget.candles.last;
    final first = widget.candles.first;

    return Column(
      children: [
        // ── Legend Header ──────────────────────────────────────────────
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

        // ── Chart ─────────────────────────────────────────────────────
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double totalCandleWidth = (8.0 + 4.0) * _zoomLevel;
              final double maxScroll = max(0.0, widget.candles.length * totalCandleWidth - (constraints.maxWidth - 80));

              if (_scrollOffset == -1.0) {
                _scrollOffset = maxScroll;
              }

              return GestureDetector(
                onScaleStart: (details) {
                  _baseZoomLevel = _zoomLevel;
                },
                onScaleUpdate: (details) {
                  setState(() {
                    if (details.scale != 1.0) {
                      _zoomLevel = (_baseZoomLevel * details.scale).clamp(0.2, 5.0);
                    }
                    _scrollOffset -= details.focalPointDelta.dx;
                    final double currentTotalWidth = (8.0 + 4.0) * _zoomLevel;
                    final double currentMaxScroll = max(0.0, widget.candles.length * currentTotalWidth - (constraints.maxWidth - 80));
                    _scrollOffset = _scrollOffset.clamp(0.0, currentMaxScroll);
                  });
                },
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
              Text('auto', style: const TextStyle(color: AppColors.unlockBlue, fontSize: 13, fontWeight: FontWeight.bold)),
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

  _ChartPainter({
    required this.candles,
    required this.scrollOffset,
    required this.zoomLevel,
    required this.mode,
    required this.period,
    required this.interval,
    required this.activeIndicators,
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

    double minPrice = double.infinity;
    double maxPrice = double.negativeInfinity;
    for (var candle in visibleCandles) {
      final low = candle.low ?? 0;
      final high = candle.high ?? 0;
      if (low < minPrice) minPrice = low;
      if (high > maxPrice) maxPrice = high;
    }

    minPrice *= 0.998;
    maxPrice *= 1.002;

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

    if (mode == ProChartMode.area) {
      _drawAreaChart(canvas, mainChartHeight, getY, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
    } else {
      _drawCandles(canvas, getY, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
    }

    if (activeIndicators.contains('SMA_Overlay') || activeIndicators.contains('SMA')) {
      _drawMALine(canvas, getY, firstVisibleIdx, lastVisibleIdx, totalCandleWidth, IndicatorCalculator.calculateSMA(candles, 20), const Color(0xFF4A90E2));
    }
    if (activeIndicators.contains('EMA_Overlay') || activeIndicators.contains('EMA')) {
      _drawMALine(canvas, getY, firstVisibleIdx, lastVisibleIdx, totalCandleWidth, IndicatorCalculator.calculateEMA(candles, 20), const Color(0xFF50E3C2));
    }
    if (activeIndicators.contains('BB_Overlay') || activeIndicators.contains('BB')) {
      _drawBollingerBands(canvas, getY, firstVisibleIdx, lastVisibleIdx, totalCandleWidth, IndicatorCalculator.calculateBollingerBands(candles, 20, 2.0));
    }

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
      } else if (subChart == 'SMA_Subchart') {
        _drawSubChartMA(canvas, currentSubChartTop, subChartHeight, chartWidth, firstVisibleIdx, lastVisibleIdx, totalCandleWidth, IndicatorCalculator.calculateSMA(candles, 20), const Color(0xFF4A90E2), 'SMA');
      } else if (subChart == 'EMA_Subchart') {
        _drawSubChartMA(canvas, currentSubChartTop, subChartHeight, chartWidth, firstVisibleIdx, lastVisibleIdx, totalCandleWidth, IndicatorCalculator.calculateEMA(candles, 20), const Color(0xFF50E3C2), 'EMA');
      } else if (subChart == 'BB_Subchart') {
        _drawSubChartBB(canvas, currentSubChartTop, subChartHeight, chartWidth, firstVisibleIdx, lastVisibleIdx, totalCandleWidth, IndicatorCalculator.calculateBollingerBands(candles, 20, 2.0));
      }
      
      currentSubChartTop += subChartHeight;
    }

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
      final rect = RRect.fromRectAndRadius(Rect.fromLTWH(chartWidth, lastPriceY - 14, labelWidth, 28), const Radius.circular(4));
      canvas.drawRRect(rect, Paint()..color = AppColors.unlockBlue);
      _drawText(canvas, Offset(chartWidth + 6, lastPriceY - 8), lastPrice.toStringAsFixed(2), Colors.white, isBold: true, fontSize: 12);
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
      oldDelegate.interval != interval;
}
