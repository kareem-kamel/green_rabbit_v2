import 'dart:math';
import 'package:flutter/material.dart';
import 'package:interactive_chart/interactive_chart.dart'; // For CandleData model
import 'package:green_rabbit/core/theme/app_colors.dart';
import 'package:intl/intl.dart' hide TextDirection;

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
                            : '${widget.interval}',
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

    return Center(
      child: Padding(
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
            if (widget.onRetry != null) ...[
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
      ),
    );
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

  _ChartPainter({
    required this.candles,
    required this.scrollOffset,
    required this.zoomLevel,
    required this.mode,
    required this.period,
    required this.interval,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const labelWidth = 80.0;
    const xAxisHeight = 45.0;
    final chartWidth = size.width - labelWidth;
    final chartHeight = size.height - xAxisHeight;

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
    final scaleY = chartHeight / (priceRange == 0 ? 1 : priceRange);

    double getY(double price) => chartHeight - (price - minPrice) * scaleY;

    // ── Grid Lines ────────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..strokeWidth = 0.8;
    for (int i = 0; i <= 5; i++) {
      final y = chartHeight * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);

      final price = maxPrice - (i / 5) * priceRange;
      _drawText(canvas, Offset(chartWidth + 8, y - 8), price.toStringAsFixed(2), Colors.white.withOpacity(0.6));
    }

    // ── Chart Body ────────────────────────────────────────────────────
    if (mode == ProChartMode.area) {
      _drawAreaChart(canvas, chartHeight, getY, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
    } else if (mode == ProChartMode.candle) {
      _drawCandles(canvas, getY, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
    } else {
      _drawIndicatorsChart(canvas, getY, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
    }

    // ── X-Axis Labels ─────────────────────────────────────────────────
    // Determine step to keep labels readable (at most ~8 labels)
    final visibleCount = lastVisibleIdx - firstVisibleIdx + 1;
    final step = max(1, (visibleCount / 8).ceil());

    for (int i = firstVisibleIdx; i <= lastVisibleIdx; i += step) {
      final x = (i * totalCandleWidth) - scrollOffset + totalCandleWidth / 2;
      if (x < 0 || x > chartWidth) continue;

      final candle = candles[i];
      final date = DateTime.fromMillisecondsSinceEpoch(candle.timestamp);

      String topText;
      String bottomText;

      // Interval-aware label format
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

      _drawText(canvas, Offset(x - 30, chartHeight + 6), topText, Colors.white.withOpacity(0.45), fontSize: 11);
      _drawText(canvas, Offset(x - 22, chartHeight + 20), bottomText, Colors.white.withOpacity(0.45), fontSize: 11);
    }

    // ── Current Price Indicator ───────────────────────────────────────
    final lastPrice = candles.last.close ?? 0;
    final lastPriceY = getY(lastPrice);
    final isInView = lastPriceY >= 0 && lastPriceY <= chartHeight;

    if (isInView) {
      final dashPaint = Paint()
        ..color = AppColors.unlockBlue.withOpacity(0.6)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      for (double x = 0; x < chartWidth; x += 10) {
        canvas.drawLine(Offset(x, lastPriceY), Offset(x + 5, lastPriceY), dashPaint);
      }

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(chartWidth, lastPriceY - 14, labelWidth, 28),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, Paint()..color = AppColors.unlockBlue);
      _drawText(
        canvas,
        Offset(chartWidth + 6, lastPriceY - 8),
        lastPrice.toStringAsFixed(2),
        Colors.white,
        isBold: true,
        fontSize: 12,
      );
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

  void _drawIndicatorsChart(Canvas canvas, Function(double) getY, int start, int end, double stepX) {
    _drawCandles(canvas, getY, start, end, stepX);
    _drawMALine(canvas, getY, start, end, stepX, 5, const Color(0xFF4A90E2));
    _drawMALine(canvas, getY, start, end, stepX, 10, const Color(0xFF50E3C2));
    _drawMALine(canvas, getY, start, end, stepX, 20, const Color(0xFFF8E71C));
    _drawMALine(canvas, getY, start, end, stepX, 30, const Color(0xFFE34F4F));
  }

  void _drawMALine(Canvas canvas, Function(double) getY, int start, int end, double stepX, int period, Color color) {
    final path = Path();
    bool first = true;
    for (int i = start; i <= end; i++) {
      if (i < period - 1) continue;
      double sum = 0;
      for (int j = 0; j < period; j++) {
        sum += candles[i - j].close ?? 0;
      }
      final x = (i * stepX) - scrollOffset + stepX / 2;
      final y = getY(sum / period);
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 1.5, Paint()..color = color);
    }
    canvas.drawPath(path, Paint()
      ..color = color.withOpacity(0.85)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke);
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
      oldDelegate.interval != interval;
}
