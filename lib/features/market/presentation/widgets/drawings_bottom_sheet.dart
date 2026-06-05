import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';

class DrawingItem {
  final String label;
  final String type;
  final String category;

  const DrawingItem({
    required this.label,
    required this.type,
    required this.category,
  });
}

const List<DrawingItem> _allDrawingItems = [
  DrawingItem(label: 'Eraser', type: 'eraser', category: 'Trend lines'),
  // Trend lines
  DrawingItem(label: 'Trend Line', type: 'trend_line', category: 'Trend lines'),
  DrawingItem(label: 'Ray', type: 'ray', category: 'Trend lines'),
  DrawingItem(label: 'Info Line', type: 'info_line', category: 'Trend lines'),
  DrawingItem(label: 'Horizontal Line', type: 'horizontal_line', category: 'Trend lines'),
  DrawingItem(label: 'Vertical Line', type: 'vertical_line', category: 'Trend lines'),
  DrawingItem(label: 'Cross Line', type: 'cross_line', category: 'Trend lines'),

  // Gann and fibonacci
  DrawingItem(label: 'Fib Retracement', type: 'fib_retracement', category: 'Gann and fibonacci'),
  DrawingItem(label: 'Fib Extension', type: 'fib_extension', category: 'Gann and fibonacci'),
  DrawingItem(label: 'Gann Box', type: 'gann_box', category: 'Gann and fibonacci'),
  DrawingItem(label: 'Gann Fan', type: 'gann_fan', category: 'Gann and fibonacci'),

  // Patterns
  DrawingItem(label: 'XABCD Pattern', type: 'xabcd', category: 'Patterns'),
  DrawingItem(label: 'Cypher Pattern', type: 'cypher', category: 'Patterns'),
  DrawingItem(label: 'Head & Shoulders', type: 'head_shoulders', category: 'Patterns'),
  DrawingItem(label: 'ABCD Pattern', type: 'abcd', category: 'Patterns'),
  DrawingItem(label: 'Triangle Pattern', type: 'triangle', category: 'Patterns'),
  DrawingItem(label: 'Three Drives Pattern', type: 'three_drives', category: 'Patterns'),
  DrawingItem(label: 'Elliott Impulse Wave (12345)', type: 'elliott_impulse', category: 'Patterns'),
  DrawingItem(label: 'Elliott Correction Wave (ABC)', type: 'elliott_correction', category: 'Patterns'),
  DrawingItem(label: 'Elliott Triangle Wave (ABCDE)', type: 'elliott_triangle', category: 'Patterns'),
  DrawingItem(label: 'Elliott Double Combo Wave (WXY)', type: 'elliott_double', category: 'Patterns'),
  DrawingItem(label: 'Elliott Triple Combo Wave (WXYXZ)', type: 'elliott_triple', category: 'Patterns'),
  DrawingItem(label: 'Cyclic Lines', type: 'cyclic_lines', category: 'Patterns'),
  DrawingItem(label: 'Time Cycles', type: 'time_cycles', category: 'Patterns'),
  DrawingItem(label: 'Sine Line', type: 'sine_line', category: 'Patterns'),
];

class DrawingsBottomSheet extends StatefulWidget {
  const DrawingsBottomSheet({super.key});

  @override
  State<DrawingsBottomSheet> createState() => _DrawingsBottomSheetState();
}

class _DrawingsBottomSheetState extends State<DrawingsBottomSheet> {
  String _selectedCategory = 'Patterns';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Trend lines',
    'Gann and fibonacci',
    'Patterns',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final spacing = isLandscape ? 8.0 : 16.0;
    final crossAxisCount = isLandscape ? 5 : 3;
    final childAspectRatio = isLandscape ? 1.2 : 0.92;

    // Filter items based on category (if search is empty) and search query
    final filteredItems = _allDrawingItems.where((item) {
      final matchesSearch = item.label.toLowerCase().contains(_searchQuery.toLowerCase());
      if (_searchQuery.isNotEmpty) {
        return matchesSearch;
      }
      return item.category == _selectedCategory;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * (isLandscape ? 0.92 : 0.85),
      decoration: const BoxDecoration(
        color: Color(0xFF131722), // TradingView dark slate background
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: spacing),

          // Title & Dismiss Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Drawings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2A2E39),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing),

          // Search Input Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1E222D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.white38,
                    size: 18,
                  ),
                  hintText: 'Search drawings...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white70, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          SizedBox(height: spacing),

          // Categories Pill Tabs (Visible and scrollable horizontally when search is not active)
          if (_searchQuery.isEmpty)
            SizedBox(
              height: isLandscape ? 32 : 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isActive = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isLandscape ? 4 : 8),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF2A2E39) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isActive ? Colors.white : const Color(0xFF848E9C),
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (_searchQuery.isEmpty) SizedBox(height: isLandscape ? 8 : 12),

          // Search Results Tag
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Search Results for "$_searchQuery"',
                style: const TextStyle(color: Color(0xFF848E9C), fontSize: 12),
              ),
            ),

          // Grid Content
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.search_off, color: Colors.white24, size: 40),
                        SizedBox(height: 8),
                        Text(
                          'No drawing tools match your search',
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.all(isLandscape ? 8 : 16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return GestureDetector(
                        onTap: () {
                          // Handle selection & close
                          Navigator.pop(context, item.type);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Selected Drawing Tool: ${item.label}'),
                              backgroundColor: AppColors.primary,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E222D), // TradingView dark gray card
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Vector icon
                              SizedBox(
                                width: isLandscape ? 32 : 44,
                                height: isLandscape ? 32 : 44,
                                child: CustomPaint(
                                  painter: DrawingIconPainter(type: item.type),
                                ),
                              ),
                              SizedBox(height: isLandscape ? 4 : 8),
                              // Label text
                              Expanded(
                                child: Center(
                                  child: Text(
                                    item.label,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isLandscape ? 9.5 : 10.5,
                                      fontWeight: FontWeight.w400,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
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
    );
  }
}

class DrawingIconPainter extends CustomPainter {
  final String type;

  DrawingIconPainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final nodePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final nodeBorderPaint = Paint()
      ..color = const Color(0xFF1E222D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    void drawNode(Offset offset, {double radius = 3.0}) {
      canvas.drawCircle(offset, radius, nodePaint);
      canvas.drawCircle(offset, radius, nodeBorderPaint);
    }

    void drawDashedLine(Offset p1, Offset p2, {double dashWidth = 3, double dashSpace = 3}) {
      final dx = p2.dx - p1.dx;
      final dy = p2.dy - p1.dy;
      final distance = math.sqrt(dx * dx + dy * dy);
      if (distance == 0) return;
      final steps = distance / (dashWidth + dashSpace);
      final deltaX = dx / steps;
      final deltaY = dy / steps;

      for (int i = 0; i < steps.toInt(); i++) {
        final x1 = p1.dx + deltaX * i;
        final y1 = p1.dy + deltaY * i;
        final x2 = x1 + deltaX * (dashWidth / (dashWidth + dashSpace));
        final y2 = y1 + deltaY * (dashWidth / (dashWidth + dashSpace));
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      }
    }

    void drawLabelText(String text, Offset offset, {double fontSize = 8.5}) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        offset - Offset(textPainter.width / 2, textPainter.height + 2),
      );
    }

    switch (type) {
      case 'eraser':
        final rect = Rect.fromLTWH(w * 0.25, h * 0.35, w * 0.5, h * 0.3);
        final path = Path()
          ..moveTo(w * 0.25, h * 0.5)
          ..lineTo(w * 0.5, h * 0.25)
          ..lineTo(w * 0.75, h * 0.5)
          ..lineTo(w * 0.5, h * 0.75)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawLine(Offset(w * 0.375, h * 0.625), Offset(w * 0.625, h * 0.375), paint);
        break;

      // --- Trend Lines ---
      case 'trend_line':
        final p1 = Offset(w * 0.2, h * 0.8);
        final p2 = Offset(w * 0.8, h * 0.2);
        canvas.drawLine(p1, p2, paint);
        drawNode(p1);
        drawNode(p2);
        break;

      case 'ray':
        final p1 = Offset(w * 0.2, h * 0.8);
        final p2 = Offset(w * 0.8, h * 0.2);
        canvas.drawLine(p1, p2, paint);
        drawNode(p1);
        // Draw arrow tip
        final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
        const arrowLength = 7.0;
        final arrowAngle = math.pi / 6;
        final arrowPath = Path()
          ..moveTo(p2.dx, p2.dy)
          ..lineTo(
            p2.dx - arrowLength * math.cos(angle - arrowAngle),
            p2.dy - arrowLength * math.sin(angle - arrowAngle),
          )
          ..moveTo(p2.dx, p2.dy)
          ..lineTo(
            p2.dx - arrowLength * math.cos(angle + arrowAngle),
            p2.dy - arrowLength * math.sin(angle + arrowAngle),
          );
        canvas.drawPath(arrowPath, paint);
        break;

      case 'info_line':
        final p1 = Offset(w * 0.25, h * 0.75);
        final p2 = Offset(w * 0.75, h * 0.25);
        canvas.drawLine(p1, p2, paint);
        drawNode(p1);
        drawNode(p2);
        // Info letter indicator 'i' in a tiny circle
        final iCenter = Offset(w * 0.78, h * 0.18);
        final iPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(iCenter, 4.5, iPaint);
        // dot of 'i'
        canvas.drawCircle(iCenter - const Offset(0, 1.8), 0.6, nodePaint);
        // trunk of 'i'
        canvas.drawLine(iCenter - const Offset(0, 0.4), iCenter + const Offset(0, 1.8), iPaint);
        break;

      case 'horizontal_line':
        final p1 = Offset(w * 0.1, h * 0.5);
        final p2 = Offset(w * 0.9, h * 0.5);
        canvas.drawLine(p1, p2, paint);
        drawNode(Offset(w * 0.5, h * 0.5));
        break;

      case 'vertical_line':
        final p1 = Offset(w * 0.5, h * 0.1);
        final p2 = Offset(w * 0.5, h * 0.9);
        canvas.drawLine(p1, p2, paint);
        drawNode(Offset(w * 0.5, h * 0.5));
        break;

      case 'cross_line':
        canvas.drawLine(Offset(w * 0.1, h * 0.5), Offset(w * 0.9, h * 0.5), paint);
        canvas.drawLine(Offset(w * 0.5, h * 0.1), Offset(w * 0.5, h * 0.9), paint);
        drawNode(Offset(w * 0.5, h * 0.5));
        break;

      // --- Gann and Fibonacci ---
      case 'fib_retracement':
        // Multiple horizontal levels
        final xStart = w * 0.15;
        final xEnd = w * 0.85;
        final levels = [0.2, 0.35, 0.5, 0.65, 0.8];
        for (final yRatio in levels) {
          canvas.drawLine(Offset(xStart, h * yRatio), Offset(xEnd, h * yRatio), paint);
        }
        // Diagonal dotted trend lines
        final p1 = Offset(w * 0.25, h * 0.8);
        final p2 = Offset(w * 0.75, h * 0.2);
        drawDashedLine(p1, p2);
        drawNode(p1);
        drawNode(p2);
        break;

      case 'fib_extension':
        final p1 = Offset(w * 0.2, h * 0.8);
        final p2 = Offset(w * 0.45, h * 0.35);
        final p3 = Offset(w * 0.6, h * 0.6);
        // Trend lines
        canvas.drawLine(p1, p2, paint);
        canvas.drawLine(p2, p3, paint);
        drawNode(p1);
        drawNode(p2);
        drawNode(p3);
        // Extension levels
        final xEnd = w * 0.85;
        canvas.drawLine(Offset(p3.dx, p2.dy), Offset(xEnd, p2.dy), paint);
        canvas.drawLine(Offset(p3.dx, p3.dy), Offset(xEnd, p3.dy), paint);
        canvas.drawLine(Offset(p3.dx, h * 0.2), Offset(xEnd, h * 0.2), paint);
        break;

      case 'gann_box':
        final rect = Rect.fromLTRB(w * 0.2, h * 0.2, w * 0.8, h * 0.8);
        canvas.drawRect(rect, paint);
        // Diagonals
        canvas.drawLine(rect.topLeft, rect.bottomRight, paint);
        canvas.drawLine(rect.bottomLeft, rect.topRight, paint);
        // Mid-lines
        canvas.drawLine(Offset(rect.left, h * 0.5), Offset(rect.right, h * 0.5), paint);
        canvas.drawLine(Offset(w * 0.5, rect.top), Offset(w * 0.5, rect.bottom), paint);
        break;

      case 'gann_fan':
        final origin = Offset(w * 0.2, h * 0.8);
        final targets = [
          Offset(w * 0.8, h * 0.2),
          Offset(w * 0.8, h * 0.4),
          Offset(w * 0.8, h * 0.6),
          Offset(w * 0.6, h * 0.2),
          Offset(w * 0.4, h * 0.2),
        ];
        for (final t in targets) {
          canvas.drawLine(origin, t, paint);
        }
        drawNode(origin);
        break;

      // --- Patterns ---
      case 'xabcd':
        final x = Offset(w * 0.15, h * 0.75);
        final a = Offset(w * 0.32, h * 0.2);
        final b = Offset(w * 0.5, h * 0.6);
        final c = Offset(w * 0.68, h * 0.35);
        final d = Offset(w * 0.85, h * 0.75);

        // Fill shapes
        final fillPaint = Paint()
          ..color = Colors.white.withOpacity(0.08)
          ..style = PaintingStyle.fill;
        final pathXAB = Path()
          ..moveTo(x.dx, x.dy)
          ..lineTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy)
          ..close();
        final pathBCD = Path()
          ..moveTo(b.dx, b.dy)
          ..lineTo(c.dx, c.dy)
          ..lineTo(d.dx, d.dy)
          ..close();
        canvas.drawPath(pathXAB, fillPaint);
        canvas.drawPath(pathBCD, fillPaint);

        // Outlines
        canvas.drawLine(x, a, paint);
        canvas.drawLine(a, b, paint);
        canvas.drawLine(b, c, paint);
        canvas.drawLine(c, d, paint);

        // Connections
        drawDashedLine(x, b);
        drawDashedLine(b, d);

        // Nodes
        drawNode(x);
        drawNode(a);
        drawNode(b);
        drawNode(c);
        drawNode(d);
        break;

      case 'cypher':
        final x = Offset(w * 0.15, h * 0.75);
        final a = Offset(w * 0.32, h * 0.2);
        final b = Offset(w * 0.5, h * 0.6);
        final c = Offset(w * 0.68, h * 0.28); // Higher peak C
        final d = Offset(w * 0.85, h * 0.75);

        // Fill shapes
        final fillPaint = Paint()
          ..color = Colors.white.withOpacity(0.08)
          ..style = PaintingStyle.fill;
        final pathXAC = Path()
          ..moveTo(x.dx, x.dy)
          ..lineTo(a.dx, a.dy)
          ..lineTo(c.dx, c.dy)
          ..close();
        canvas.drawPath(pathXAC, fillPaint);

        // Outlines
        canvas.drawLine(x, a, paint);
        canvas.drawLine(a, b, paint);
        canvas.drawLine(b, c, paint);
        canvas.drawLine(c, d, paint);

        // Connections
        drawDashedLine(x, c);
        drawDashedLine(a, c);
        drawDashedLine(b, d);

        // Nodes
        drawNode(x);
        drawNode(a);
        drawNode(b);
        drawNode(c);
        drawNode(d);

        // 'C' Label on peak C
        drawLabelText('C', c - const Offset(0, 2));
        break;

      case 'head_shoulders':
        final sStart = Offset(w * 0.1, h * 0.72);
        final peakLeft = Offset(w * 0.28, h * 0.45);
        final dip1 = Offset(w * 0.38, h * 0.65);
        final peakMid = Offset(w * 0.5, h * 0.2);
        final dip2 = Offset(w * 0.62, h * 0.65);
        final peakRight = Offset(w * 0.72, h * 0.45);
        final sEnd = Offset(w * 0.9, h * 0.72);

        // Pattern outline
        final path = Path()
          ..moveTo(sStart.dx, sStart.dy)
          ..lineTo(peakLeft.dx, peakLeft.dy)
          ..lineTo(dip1.dx, dip1.dy)
          ..lineTo(peakMid.dx, peakMid.dy)
          ..lineTo(dip2.dx, dip2.dy)
          ..lineTo(peakRight.dx, peakRight.dy)
          ..lineTo(sEnd.dx, sEnd.dy);
        canvas.drawPath(path, paint);

        // Neckline (dashed)
        drawDashedLine(dip1, dip2);

        // Peak nodes
        drawNode(peakLeft);
        drawNode(peakMid);
        drawNode(peakRight);
        break;

      case 'abcd':
        final a = Offset(w * 0.2, h * 0.35);
        final b = Offset(w * 0.45, h * 0.75);
        final c = Offset(w * 0.55, h * 0.45);
        final d = Offset(w * 0.8, h * 0.85);

        canvas.drawLine(a, b, paint);
        canvas.drawLine(b, c, paint);
        canvas.drawLine(c, d, paint);

        drawNode(a);
        drawNode(b);
        drawNode(c);
        drawNode(d);
        break;

      case 'triangle':
        // Top converging boundary
        final topStart = Offset(w * 0.15, h * 0.25);
        final topEnd = Offset(w * 0.85, h * 0.48);
        canvas.drawLine(topStart, topEnd, paint);

        // Bottom converging boundary
        final bottomStart = Offset(w * 0.15, h * 0.75);
        final bottomEnd = Offset(w * 0.85, h * 0.52);
        canvas.drawLine(bottomStart, bottomEnd, paint);

        // zigzag inside
        final p1 = Offset(w * 0.2, h * 0.72);
        final p2 = Offset(w * 0.35, h * 0.32);
        final p3 = Offset(w * 0.5, h * 0.63);
        final p4 = Offset(w * 0.65, h * 0.42);
        final p5 = Offset(w * 0.8, h * 0.53);

        final zigPath = Path()
          ..moveTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..lineTo(p3.dx, p3.dy)
          ..lineTo(p4.dx, p4.dy)
          ..lineTo(p5.dx, p5.dy);
        canvas.drawPath(zigPath, paint);

        // Nodes
        drawNode(p1);
        drawNode(p2);
        drawNode(p3);
        drawNode(p4);
        drawNode(p5);
        break;

      case 'three_drives':
        final start = Offset(w * 0.12, h * 0.75);
        final d1 = Offset(w * 0.32, h * 0.52);
        final t1 = Offset(w * 0.42, h * 0.68);
        final d2 = Offset(w * 0.58, h * 0.36);
        final t2 = Offset(w * 0.68, h * 0.52);
        final d3 = Offset(w * 0.82, h * 0.2);
        final end = Offset(w * 0.9, h * 0.35);

        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..lineTo(d1.dx, d1.dy)
          ..lineTo(t1.dx, t1.dy)
          ..lineTo(d2.dx, d2.dy)
          ..lineTo(t2.dx, t2.dy)
          ..lineTo(d3.dx, d3.dy)
          ..lineTo(end.dx, end.dy);
        canvas.drawPath(path, paint);

        // Peak nodes
        drawNode(d1);
        drawNode(d2);
        drawNode(d3);

        // Drive number labels
        drawLabelText('1', d1 - const Offset(0, 1));
        drawLabelText('2', d2 - const Offset(0, 1));
        drawLabelText('3', d3 - const Offset(0, 1));
        break;

      case 'elliott_impulse':
        final p0 = Offset(w * 0.12, h * 0.8);
        final p1 = Offset(w * 0.26, h * 0.52);
        final p2 = Offset(w * 0.42, h * 0.72);
        final p3 = Offset(w * 0.58, h * 0.24);
        final p4 = Offset(w * 0.74, h * 0.58);
        final p5 = Offset(w * 0.88, h * 0.2);

        final path = Path()
          ..moveTo(p0.dx, p0.dy)
          ..lineTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..lineTo(p3.dx, p3.dy)
          ..lineTo(p4.dx, p4.dy)
          ..lineTo(p5.dx, p5.dy);
        canvas.drawPath(path, paint);

        // Nodes
        drawNode(p0);
        drawNode(p1);
        drawNode(p2);
        drawNode(p3);
        drawNode(p4);
        drawNode(p5);

        // Node labels
        drawLabelText('1', p1 - const Offset(0, 1));
        drawLabelText('2', p2 + const Offset(0, 11)); // place below the node
        drawLabelText('3', p3 - const Offset(0, 1));
        drawLabelText('4', p4 + const Offset(0, 11)); // place below
        drawLabelText('5', p5 - const Offset(0, 1));
        break;

      case 'elliott_correction':
        final p0 = Offset(w * 0.18, h * 0.35);
        final a = Offset(w * 0.42, h * 0.78);
        final b = Offset(w * 0.65, h * 0.48);
        final c = Offset(w * 0.85, h * 0.88);

        final path = Path()
          ..moveTo(p0.dx, p0.dy)
          ..lineTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy)
          ..lineTo(c.dx, c.dy);
        canvas.drawPath(path, paint);

        // Nodes
        drawNode(p0);
        drawNode(a);
        drawNode(b);
        drawNode(c);

        // Labels
        drawLabelText('A', a + const Offset(0, 11)); // below
        drawLabelText('B', b - const Offset(0, 1));  // above
        drawLabelText('C', c + const Offset(0, 11)); // below
        break;

      case 'elliott_triangle':
        // Dotted converging lines
        final topStart = Offset(w * 0.15, h * 0.25);
        final topEnd = Offset(w * 0.85, h * 0.48);
        drawDashedLine(topStart, topEnd);

        final bottomStart = Offset(w * 0.15, h * 0.75);
        final bottomEnd = Offset(w * 0.85, h * 0.52);
        drawDashedLine(bottomStart, bottomEnd);

        // zigzag: A, B, C, D, E
        final a = Offset(w * 0.22, h * 0.31);
        final b = Offset(w * 0.37, h * 0.67);
        final c = Offset(w * 0.52, h * 0.37);
        final d = Offset(w * 0.67, h * 0.61);
        final e = Offset(w * 0.8, h * 0.44);

        final path = Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy)
          ..lineTo(c.dx, c.dy)
          ..lineTo(d.dx, d.dy)
          ..lineTo(e.dx, e.dy);
        canvas.drawPath(path, paint);

        // Nodes
        drawNode(a);
        drawNode(b);
        drawNode(c);
        drawNode(d);
        drawNode(e);

        // Labels
        drawLabelText('A', a - const Offset(0, 1));
        drawLabelText('B', b + const Offset(0, 11));
        drawLabelText('C', c - const Offset(0, 1));
        drawLabelText('D', d + const Offset(0, 11));
        drawLabelText('E', e - const Offset(0, 1));
        break;

      case 'elliott_double':
        final start = Offset(w * 0.18, h * 0.72);
        final wNode = Offset(w * 0.36, h * 0.34);
        final xNode = Offset(w * 0.54, h * 0.62);
        final yNode = Offset(w * 0.72, h * 0.28);
        final end = Offset(w * 0.88, h * 0.56);

        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..lineTo(wNode.dx, wNode.dy)
          ..lineTo(xNode.dx, xNode.dy)
          ..lineTo(yNode.dx, yNode.dy)
          ..lineTo(end.dx, end.dy);
        canvas.drawPath(path, paint);

        // Nodes
        drawNode(wNode);
        drawNode(xNode);
        drawNode(yNode);

        // Labels on top peaks
        drawLabelText('W', wNode - const Offset(0, 1));
        drawLabelText('X', xNode + const Offset(0, 11));
        drawLabelText('Y', yNode - const Offset(0, 1));
        break;

      case 'elliott_triple':
        final start = Offset(w * 0.12, h * 0.7);
        final wNode = Offset(w * 0.26, h * 0.35);
        final xNode = Offset(w * 0.4, h * 0.65);
        final yNode = Offset(w * 0.54, h * 0.3);
        final xxNode = Offset(w * 0.68, h * 0.6);
        final zNode = Offset(w * 0.82, h * 0.25);
        final end = Offset(w * 0.9, h * 0.45);

        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..lineTo(wNode.dx, wNode.dy)
          ..lineTo(xNode.dx, xNode.dy)
          ..lineTo(yNode.dx, yNode.dy)
          ..lineTo(xxNode.dx, xxNode.dy)
          ..lineTo(zNode.dx, zNode.dy)
          ..lineTo(end.dx, end.dy);
        canvas.drawPath(path, paint);

        // Nodes
        drawNode(wNode);
        drawNode(xNode);
        drawNode(yNode);
        drawNode(xxNode);
        drawNode(zNode);

        // Labels
        drawLabelText('W', wNode - const Offset(0, 1));
        drawLabelText('X', xNode + const Offset(0, 11));
        drawLabelText('Y', yNode - const Offset(0, 1));
        drawLabelText('X', xxNode + const Offset(0, 11));
        drawLabelText('Z', zNode - const Offset(0, 1));
        break;

      case 'cyclic_lines':
        // Horizontal line
        canvas.drawLine(Offset(w * 0.1, h * 0.5), Offset(w * 0.9, h * 0.5), paint);
        // 4 Vertical parallel lines
        final xCoords = [w * 0.2, w * 0.4, w * 0.6, w * 0.8];
        for (final xCoord in xCoords) {
          canvas.drawLine(Offset(xCoord, h * 0.25), Offset(xCoord, h * 0.75), paint);
        }
        // Adjustment nodes on intersection 1 & 2
        drawNode(Offset(w * 0.2, h * 0.5));
        drawNode(Offset(w * 0.4, h * 0.5));
        break;

      case 'time_cycles':
        // Baseline
        final yBase = h * 0.68;
        canvas.drawLine(Offset(w * 0.12, yBase), Offset(w * 0.88, yBase), paint);

        // 3 consecutive semi-circular loops (quadratic bezier arches)
        final xPoints = [w * 0.15, w * 0.38, w * 0.61, w * 0.84];
        for (int i = 0; i < 3; i++) {
          final xStart = xPoints[i];
          final xEnd = xPoints[i + 1];
          final midX = (xStart + xEnd) / 2;
          final peakY = h * 0.32; // height of loop

          final loopPath = Path()
            ..moveTo(xStart, yBase)
            ..quadraticBezierTo(midX, peakY, xEnd, yBase);
          canvas.drawPath(loopPath, paint);
          drawNode(Offset(xStart, yBase), radius: 2.2);
          if (i == 2) {
            drawNode(Offset(xEnd, yBase), radius: 2.2);
          }
        }
        break;

      case 'sine_line':
        // Smooth sine wave
        final path = Path();
        final xStart = w * 0.15;
        final xEnd = w * 0.85;
        final midY = h * 0.55;
        final amplitude = h * 0.25;

        path.moveTo(xStart, midY);
        for (double x = xStart; x <= xEnd; x += 1.0) {
          final relativeX = (x - xStart) / (xEnd - xStart);
          final y = midY + amplitude * math.sin(2 * math.pi * relativeX);
          path.lineTo(x, y);
        }
        canvas.drawPath(path, paint);

        // Nodes at ends
        drawNode(Offset(xStart, midY));
        drawNode(Offset(xEnd, midY));
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
