import 'package:flutter/material.dart';
import 'package:interactive_chart/interactive_chart.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';

class TradingChart extends StatefulWidget {
  final List<CandleData> candles;
  final bool showMovingAverages;

  const TradingChart({
    super.key,
    required this.candles,
    this.showMovingAverages = false,
  });

  @override
  State<TradingChart> createState() => _TradingChartState();
}

class _TradingChartState extends State<TradingChart> {
  CandleData? _selectedCandle;

  @override
  Widget build(BuildContext context) {
    final displayCandle = _selectedCandle ?? (widget.candles.isNotEmpty ? widget.candles.last : null);
    
    return Stack(
      children: [
        InteractiveChart(
          candles: widget.candles,
          style: ChartStyle(
            priceGainColor: AppColors.success,
            priceLossColor: AppColors.error,
            volumeColor: AppColors.textMuted.withOpacity(0.2),
          ),
          onTap: (candle) {
            setState(() => _selectedCandle = candle);
          },
        ),
        if (displayCandle != null)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _legendItem('O', displayCandle.open ?? 0),
                      _legendItem('H', displayCandle.high ?? 0),
                      _legendItem('L', displayCandle.low ?? 0),
                      _legendItem('C', displayCandle.close ?? 0),
                    ],
                  ),
                  if (widget.showMovingAverages) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _legendIndicator('MA(7)', AppColors.primary, (displayCandle.close ?? 0) * 0.995),
                        const SizedBox(width: 12),
                        _legendIndicator('MA(20)', Colors.orange, (displayCandle.close ?? 0) * 0.985),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _legendItem(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(text: value.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _legendIndicator(String label, Color color, double value) {
    return Row(
      children: [
        Container(width: 8, height: 2, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ${value.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
