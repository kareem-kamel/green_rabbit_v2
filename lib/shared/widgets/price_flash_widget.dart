import 'package:flutter/material.dart';

class PriceFlashWidget extends StatefulWidget {
  final double? price;
  final Widget child;

  const PriceFlashWidget({
    super.key,
    required this.price,
    required this.child,
  });

  @override
  State<PriceFlashWidget> createState() => _PriceFlashWidgetState();
}

class _PriceFlashWidgetState extends State<PriceFlashWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;
  Color _flashColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.transparent,
    ).animate(_animationController);
  }

  @override
  void didUpdateWidget(PriceFlashWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.price != oldWidget.price && widget.price != null && oldWidget.price != null) {
      if (widget.price! > oldWidget.price!) {
        _triggerFlash(Colors.green.withValues(alpha: 0.18));
      } else if (widget.price! < oldWidget.price!) {
        _triggerFlash(Colors.red.withValues(alpha: 0.18));
      }
    }
  }

  void _triggerFlash(Color color) {
    setState(() {
      _flashColor = color;
      _colorAnimation = ColorTween(
        begin: _flashColor,
        end: Colors.transparent,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));
    });
    _animationController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: widget.child,
        );
      },
    );
  }
}
