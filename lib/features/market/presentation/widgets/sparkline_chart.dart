import 'package:flutter/material.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';

class SparklineChart extends StatelessWidget {
  final List<double> data;
  final List<String>? labelsX;
  final List<String>? labelsY;
  final double? currentPrice;
  final Color color;

  const SparklineChart({
    super.key,
    required this.data,
    this.labelsX,
    this.labelsY,
    this.currentPrice,
    this.color = Colors.blueAccent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: _SparklinePainter(
              data: data, 
              color: color, 
              currentPrice: currentPrice,
              labelsX: labelsX,
              labelsY: labelsY,
            ),
          ),
        ),
        if (labelsX != null)
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 40, right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: labelsX!.map((l) => Text(l, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10))).toList(),
            ),
          ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final List<String>? labelsX;
  final List<String>? labelsY;
  final Color color;
  final double? currentPrice;

  _SparklinePainter({
    required this.data,
    required this.color,
    this.labelsX,
    this.labelsY,
    this.currentPrice,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    const leftPadding = 40.0;
    const rightPadding = 10.0;
    final chartWidth = size.width - leftPadding - rightPadding;

    final minPrice = data.reduce((a, b) => a < b ? a : b);
    final maxPrice = data.reduce((a, b) => a > b ? a : b);
    final dataRange = (maxPrice - minPrice) == 0 ? 1.0 : (maxPrice - minPrice);
    
    final paddingY = size.height * 0.1;
    final usableHeight = size.height - (paddingY * 2);

    double getY(double price) => size.height - paddingY - ((price - minPrice) / dataRange * usableHeight);
    double getX(int index) => leftPadding + (index * chartWidth / (data.length - 1));

    // Draw Y Axis Labels and Grid lines
    final gridPaint = Paint()..color = Colors.white.withOpacity(0.05)..strokeWidth = 1.0;
    if (labelsY != null) {
      for (int i = 0; i < labelsY!.length; i++) {
        final y = size.height - paddingY - (i * usableHeight / (labelsY!.length - 1));
        canvas.drawLine(Offset(leftPadding, y), Offset(size.width - rightPadding, y), gridPaint);
        
        _drawText(canvas, Offset(5, y - 6), labelsY![i], AppColors.textSecondary);
      }
    }

    // Current Price Indicator (Dotted Line + Bubble)
    if (currentPrice != null) {
      final cpY = getY(currentPrice!);
      final dashPaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      _drawDashedLine(canvas, Offset(leftPadding, cpY), Offset(size.width - rightPadding, cpY), dashPaint);
      _drawBubbleLabel(canvas, Offset(leftPadding, cpY), currentPrice!.toStringAsFixed(0));
    }

    // Path for Line
    final path = Path();
    final fillPath = Path();
    
    for (var i = 0; i < data.length; i++) {
      final x = getX(i);
      final y = getY(data[i]);
      
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height - paddingY);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
      
      if (i == data.length - 1) {
        fillPath.lineTo(x, size.height - paddingY);
        fillPath.close();
      }
    }

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color.withOpacity(0.35), color.withOpacity(0.0)],
    );
    final fillPaint = Paint()..shader = gradient.createShader(Rect.fromLTWH(leftPadding, 0, chartWidth, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  void _drawText(Canvas canvas, Offset offset, String text, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 10)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 4;
    const dashSpace = 4;
    double currentX = start.dx;
    while (currentX < end.dx) {
      canvas.drawLine(
        Offset(currentX, start.dy),
        Offset(currentX + dashWidth, start.dy),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  void _drawBubbleLabel(Canvas canvas, Offset center, String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final bubbleWidth = textPainter.width + 12;
    final bubbleHeight = textPainter.height + 6;
    final bubbleRect = Rect.fromCenter(
      center: Offset(center.dx - bubbleWidth / 2, center.dy),
      width: bubbleWidth,
      height: bubbleHeight,
    );

    final bubblePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(bubbleRect, const Radius.circular(4)), bubblePaint);

    textPainter.paint(
      canvas, 
      Offset(bubbleRect.left + 6, bubbleRect.top + 3),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
