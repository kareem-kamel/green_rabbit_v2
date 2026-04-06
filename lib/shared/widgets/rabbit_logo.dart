import 'package:flutter/material.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';

class RabbitLogo extends StatelessWidget {
  final double size;
  final Color color;

  const RabbitLogo({
    super.key,
    this.size = 30,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RabbitPainter(color: color),
      ),
    );
  }
}

class _RabbitPainter extends CustomPainter {
  final Color color;

  _RabbitPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Rabbit head/body simplified silhouette
    path.moveTo(w * 0.4, h * 0.9);
    path.quadraticBezierTo(w * 0.2, h * 0.8, w * 0.2, h * 0.6);
    path.quadraticBezierTo(w * 0.2, h * 0.4, w * 0.4, h * 0.35);
    
    // Ears
    path.lineTo(w * 0.35, h * 0.1);
    path.quadraticBezierTo(w * 0.45, h * 0.0, w * 0.5, h * 0.25);
    path.lineTo(w * 0.65, h * 0.05);
    path.quadraticBezierTo(w * 0.75, 0, w * 0.7, h * 0.3);
    
    // Face/Nose
    path.quadraticBezierTo(w * 0.85, h * 0.4, w * 0.85, h * 0.6);
    path.quadraticBezierTo(w * 0.85, h * 0.8, w * 0.6, h * 0.9);
    path.close();

    canvas.drawPath(path, paint);

    // Trending Up Arrow Line (Integrated)
    final linePaint = Paint()
      ..color = AppColors.backgroundSubtle // Background color to "cut" through the rabbit
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final arrowPath = Path();
    arrowPath.moveTo(w * 0.35, h * 0.75);
    arrowPath.lineTo(w * 0.45, h * 0.65);
    arrowPath.lineTo(w * 0.55, h * 0.7);
    arrowPath.lineTo(w * 0.75, h * 0.45);
    
    // Arrow head
    arrowPath.moveTo(w * 0.68, h * 0.48);
    arrowPath.lineTo(w * 0.75, h * 0.45);
    arrowPath.lineTo(w * 0.72, h * 0.54);

    canvas.drawPath(arrowPath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
