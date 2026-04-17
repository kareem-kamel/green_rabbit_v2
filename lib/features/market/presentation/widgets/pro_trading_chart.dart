import 'dart:math';
import 'package:flutter/material.dart';
import 'package:interactive_chart/interactive_chart.dart'; // For CandleData model
import 'package:green_rabbit/core/theme/app_colors.dart';
import 'package:intl/intl.dart' hide TextDirection;

enum ProChartMode { area, candle, indicators }

class ProTradingChart extends StatefulWidget {
  final List<CandleData> candles;
  final bool showMovingAverages;
  final ProChartMode mode;
  final String timeframe;

  const ProTradingChart({
    super.key,
    required this.candles,
    this.showMovingAverages = true,
    this.mode = ProChartMode.area, 
    this.timeframe = '15',
  });

  @override
  State<ProTradingChart> createState() => _ProTradingChartState();
}

class _ProTradingChartState extends State<ProTradingChart> {
  double _scrollOffset = 0.0;
  final double _zoomLevel = 1.0;
  
  @override
  Widget build(BuildContext context) {
    if (widget.candles.isEmpty) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        // Legend Header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16),
          child: widget.mode == ProChartMode.indicators 
            ? _buildIndicatorsLegend()
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Icon(Icons.remove_circle_outline, color: AppColors.textMuted, size: 14),
                    const SizedBox(width: 8),
                    Text('Silver Futures , ${widget.timeframe} , (CFD)', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    const Icon(Icons.settings_outlined, color: AppColors.textMuted, size: 14),
                    const SizedBox(width: 8),
                    const Icon(Icons.visibility_outlined, color: AppColors.textMuted, size: 14),
                    const SizedBox(width: 12),
                    _buildLegendValue('O', '112.320'),
                    _buildLegendValue('H', '112.493'),
                    _buildLegendValue('L', '111.955'),
                    _buildLegendValue('C', '112.482'),
                  ],
                ),
              ),
        ),
        
        // Main Chart Area
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _scrollOffset -= details.delta.dx;
                    _scrollOffset = _scrollOffset.clamp(0.0, max(0.0, widget.candles.length * 12.0 - (constraints.maxWidth - 80)));
                  });
                },
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _ChartPainter(
                    candles: widget.candles,
                    scrollOffset: _scrollOffset,
                    zoomLevel: _zoomLevel,
                    mode: widget.mode,
                    timeframe: widget.timeframe,
                  ),
                ),
              );
            },
          ),
        ),
        
        // Bottom Labels (Image 2 style)
        Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ...['5y', '3y', '1y', '1m', '1d'].map((label) => Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500)),
              )),
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

  Widget _buildIndicatorsLegend() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildLegendItem('Daily K', Colors.red, isRect: true),
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
            TextSpan(text: value, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<CandleData> candles;
  final double scrollOffset;
  final double zoomLevel;
  final ProChartMode mode;
  final String timeframe;

  _ChartPainter({
    required this.candles,
    required this.scrollOffset,
    required this.zoomLevel,
    required this.mode,
    required this.timeframe,
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
    
    minPrice *= 0.98;
    maxPrice *= 1.02;
    
    final priceRange = maxPrice - minPrice;
    final scaleY = chartHeight / (priceRange == 0 ? 1 : priceRange);

    double getY(double price) => chartHeight - (price - minPrice) * scaleY;

    // Grid Lines
    final gridPaint = Paint()..color = Colors.white.withOpacity(0.1)..strokeWidth = 0.8;
    for (int i = 0; i <= 5; i++) {
      final y = chartHeight * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
      
      final price = maxPrice - (i / 5) * priceRange;
      _drawText(canvas, Offset(chartWidth + 8, y - 8), price.toStringAsFixed(3), Colors.white.withOpacity(0.7));
    }

    if (mode == ProChartMode.area) {
      _drawAreaChart(canvas, chartHeight, getY, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
    } else if (mode == ProChartMode.candle) {
      _drawCandles(canvas, getY, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
    } else {
      _drawIndicatorsChart(canvas, getY, firstVisibleIdx, lastVisibleIdx, totalCandleWidth);
    }

    // X-Axis (Dates)
    for (int i = firstVisibleIdx; i <= lastVisibleIdx; i += 10) {
      final x = (i * totalCandleWidth) - scrollOffset + totalCandleWidth / 2;
      if (x < 0 || x > chartWidth) continue;
      
      final candle = candles[i];
      final date = DateTime.fromMillisecondsSinceEpoch(candle.timestamp);
      
      String topText;
      String bottomText;
      
      if (timeframe == '1M') {
        topText = DateFormat('yyyy').format(date);
        bottomText = DateFormat('MMM').format(date);
      } else if (timeframe == '1D') {
        topText = DateFormat('yyyy-MM').format(date);
        bottomText = DateFormat('dd').format(date);
      } else {
        // Multi-line style like user image
        topText = DateFormat('yyyy-MM-dd').format(date);
        bottomText = DateFormat('HH:mm:ss').format(date);
      }
      
      _drawText(canvas, Offset(x - 35, chartHeight + 6), topText, Colors.white.withOpacity(0.5));
      _drawText(canvas, Offset(x - 30, chartHeight + 22), bottomText, Colors.white.withOpacity(0.5));
    }

    // Current Price Indicator
    final lastPrice = candles.last.close ?? 0;
    final lastPriceY = getY(lastPrice);
    final dashPaint = Paint()
      ..color = AppColors.unlockBlue.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (double x = 0; x < chartWidth; x += 10) {
      canvas.drawLine(Offset(x, lastPriceY), Offset(x + 5, lastPriceY), dashPaint);
    }

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(chartWidth, lastPriceY - 14, labelWidth, 28),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, Paint()..color = Colors.white);
    _drawText(canvas, Offset(chartWidth + 10, lastPriceY - 8), lastPrice.toStringAsFixed(0), Colors.black, isBold: true);
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

    final fillPaint = Paint()..shader = LinearGradient(
      colors: [AppColors.unlockBlue.withOpacity(0.3), AppColors.unlockBlue.withOpacity(0.0)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, 1000, height));
    
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, Paint()..color = AppColors.unlockBlue..strokeWidth = 3..style = PaintingStyle.stroke);
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
      
      canvas.drawLine(Offset(x + candleWidth / 2, getY(high)), Offset(x + candleWidth / 2, getY(low)), paint..strokeWidth = 1.5);
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

    _drawPriceBalloon(canvas, getY, start, end, stepX, 2334, isTop: true, color: Colors.red);
    _drawPriceBalloon(canvas, getY, start, end, stepX, 2300, isTop: true, color: Colors.blueGrey);
    _drawPriceBalloon(canvas, getY, start, end, stepX, 2126, isTop: false, color: Colors.red);
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
      if (first) { path.moveTo(x, y); first = false; } else { path.lineTo(x, y); }
      canvas.drawCircle(Offset(x, y), 1.5, Paint()..color = color);
    }
    canvas.drawPath(path, Paint()..color = color.withOpacity(0.8)..strokeWidth = 1.2..style = PaintingStyle.stroke);
  }

  void _drawPriceBalloon(Canvas canvas, Function(double) getY, int start, int end, double stepX, double price, {required bool isTop, required Color color}) {
    final index = (start + (end - start) * (isTop ? 0.7 : 0.9)).floor().clamp(start, end);
    final x = (index * stepX) - scrollOffset + stepX / 2;
    final y = getY(price);
    final path = Path();
    if (isTop) {
      path.moveTo(x, y); path.lineTo(x - 12, y - 12);
      path.arcToPoint(Offset(x + 12, y - 12), radius: const Radius.circular(12), clockwise: true);
    } else {
      path.moveTo(x, y); path.lineTo(x - 12, y + 12);
      path.arcToPoint(Offset(x + 12, y + 12), radius: const Radius.circular(12), clockwise: false);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
    _drawText(canvas, Offset(x - 10, isTop ? y - 24 : y + 12), price.toStringAsFixed(0), Colors.white, isBold: true);
  }

  void _drawText(Canvas canvas, Offset offset, String text, Color color, {bool isBold = false}) {
    final span = TextSpan(style: TextStyle(color: color, fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal), text: text);
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}
