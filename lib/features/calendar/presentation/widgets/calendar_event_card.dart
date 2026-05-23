import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/calendar_event.dart';
import '../../../market/presentation/pages/instrument_detail_page.dart';

class CalendarEventCard extends StatelessWidget {
  final CalendarEvent event;
  final String? category;

  const CalendarEventCard({super.key, required this.event, this.category});

  @override
  Widget build(BuildContext context) {
    // If it's a holiday (based on description or name containing holiday)
    final isHoliday = event.name?.toLowerCase().contains('holiday') ?? false;

    if (isHoliday) {
      return GestureDetector(
        onTap: () {
          final instrumentId = event.instrument?.id ?? event.symbol;
          if (instrumentId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InstrumentDetailPage(instrumentId: instrumentId),
              ),
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161922),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Holiday", style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 8),
                  // Flag placeholder
                  Container(
                    width: 32,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 40),
              Expanded(
                child: Text(
                  event.name ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w300),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hasMetrics = 
        category == 'ipo' ||
        // Earnings
        event.epsEstimate != null || 
        event.epsActual != null || 
        event.revenueEstimate != null || 
        event.revenueActual != null ||
        // Dividends
        event.amount != null || 
        event.dividendYield != null || 
        event.paymentDate != null ||
        // Splits
        event.fromFactor != null || 
        event.toFactor != null || 
        event.ratio != null ||
        // IPOs
        event.priceRangeLow != null || 
        event.priceRangeHigh != null || 
        event.offerPrice != null || 
        event.lastPrice != null || 
        event.ipoValue != null ||
        event.shares != null ||
        // Economic
        event.actual != null || 
        event.forecast != null || 
        event.previous != null;

    return GestureDetector(
      onTap: () {
        final instrumentId = event.instrument?.id ?? event.symbol;
        if (instrumentId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InstrumentDetailPage(instrumentId: instrumentId),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161922),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column (Flag/Currency/Rabbits)
            SizedBox(
              width: 85, // Increased width to ensure rabbits and currency fit perfectly
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Flag next to Currency
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 16,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          image: event.instrument?.logoUrl != null 
                            ? DecorationImage(image: NetworkImage(event.instrument!.logoUrl!), fit: BoxFit.cover)
                            : null,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        event.currency ?? 'USD',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(3, (index) {
                      final activeCount = _getActiveRabbits();
                      final isHighlighted = activeCount > index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Image.asset(
                          isHighlighted ? 'assets/rabbit_highlighted.png' : 'assets/rabbit_dark.png',
                          width: 16, // slightly larger for visibility
                          height: 16,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Event Name and Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    event.name ?? event.symbol,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w400),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!hasMetrics) ...[
                    const SizedBox(height: 6),
                    Text(
                      event.description ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    _buildMetrics(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _getDetailedTextSpans() {
    if (event.actual != null) {
      return [
        const TextSpan(text: "Act:"),
        TextSpan(text: "${event.actual} ", style: const TextStyle(color: Colors.white70)),
        const TextSpan(text: "| Core | Prev, "),
        TextSpan(text: "${event.previous ?? '-'}B", style: const TextStyle(color: AppColors.profitGreen)),
      ];
    }
    // Fallback for other types
    return [
      TextSpan(text: _getEventDetails()),
    ];
  }

  // Refined metrics widget for cleaner layout
  Widget _buildMetrics() {
    // Splits Layout
    if (event.fromFactor != null || event.toFactor != null || event.ratio != null) {
      String ratioText = "-";
      if (event.fromFactor != null && event.toFactor != null) {
        ratioText = "${event.toFactor} : ${event.fromFactor}";
      } else if (event.ratio != null) {
        ratioText = "1 : ${(1 / event.ratio!).toStringAsFixed(0)}";
      }

      String splitType = "Stock Split";
      Color typeColor = Colors.white70;
      if (event.fromFactor != null && event.toFactor != null) {
        if (event.fromFactor! > event.toFactor!) {
          splitType = "Reverse Split";
          typeColor = Colors.red;
        } else {
          splitType = "Forward Split";
          typeColor = AppColors.profitGreen;
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMetricRow("Ratio", ratioText),
          const SizedBox(height: 6),
          _buildMetricRow("Type", splitType, valueColor: typeColor),
        ],
      );
    }

    // IPO Layout
    if (category == 'ipo' ||
        event.lastPrice != null ||
        event.ipoValue != null ||
        event.priceRangeLow != null ||
        event.priceRangeHigh != null ||
        event.offerPrice != null ||
        event.shares != null) {
      final String symbol = event.symbol.isNotEmpty ? event.symbol : (event.instrument?.symbol ?? '');
      final String exchange = event.exchange ?? (event.instrument?.exchange ?? '');
      final String symbolExchange = exchange.isNotEmpty ? "$symbol ($exchange)" : symbol;

      final bool isUpcoming = event.lastPrice == null;
      final List<Widget> metrics = [];
      
      if (symbolExchange.isNotEmpty) {
        metrics.add(_buildMetricRow("Symbol / Exchange", symbolExchange));
      }
      
      if (!isUpcoming && event.lastPrice != null) {
        metrics.add(_buildMetricRow("Last Price", "\$${event.lastPrice!.toStringAsFixed(2)}"));
      }
      
      if (isUpcoming) {
        if (event.priceRangeLow != null && event.priceRangeHigh != null) {
          if (event.priceRangeLow == event.priceRangeHigh) {
            metrics.add(_buildMetricRow("Price Range", "\$${event.priceRangeLow!.toStringAsFixed(2)}"));
          } else {
            metrics.add(_buildMetricRow("Price Range", "\$${event.priceRangeLow!.toStringAsFixed(2)} - \$${event.priceRangeHigh!.toStringAsFixed(2)}"));
          }
        } else {
          metrics.add(_buildMetricRow("Price Range", "TBD"));
        }
      }
      
      if (event.offerPrice != null && event.offerPrice! > 0) {
        metrics.add(_buildMetricRow("Offer Price", "\$${event.offerPrice!.toStringAsFixed(2)}"));
      } else {
        metrics.add(_buildMetricRow("Offer Price", "TBD"));
      }
      
      if (event.shares != null && event.shares! > 0) {
        metrics.add(_buildMetricRow("Shares", NumberFormat.compact().format(event.shares)));
      } else {
        metrics.add(_buildMetricRow("Shares", "TBD"));
      }
      
      if (isUpcoming) {
        if (event.ipoValue != null && event.ipoValue!.isNotEmpty) {
          metrics.add(_buildMetricRow("IPO Value", event.ipoValue!));
        } else {
          metrics.add(_buildMetricRow("IPO Value", "TBD"));
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: () {
          final List<Widget> children = [];
          for (int i = 0; i < metrics.length; i++) {
            if (i > 0) children.add(const SizedBox(height: 6));
            children.add(metrics[i]);
          }
          return children;
        }(),
      );
    }

    // Dividend Layout
    if (event.dividendYield != null || event.paymentDate != null) {
      final String yieldStr = event.dividendYield != null ? " (${event.dividendYield!.toStringAsFixed(2)}%)" : "";
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMetricRow("Dividend / Yield", "\$${event.amount ?? '-'} $yieldStr"),
          if (event.paymentDate != null && event.paymentDate!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildMetricRow("Payment Date", event.paymentDate!),
          ],
          if (event.dividendType != null && event.dividendType!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildMetricRow("Type", event.dividendType!),
          ],
        ],
      );
    }

    // Earnings Layout
    if (event.epsEstimate != null || event.epsActual != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("EPS / Forecast", style: TextStyle(color: Colors.grey, fontSize: 13)),
              Row(
                children: [
                  Text(
                    "${event.epsActual ?? '-'} ",
                    style: TextStyle(
                      color: (event.epsActual ?? 0) >= (event.epsEstimate ?? 0) ? AppColors.profitGreen : Colors.red,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    "/ ${event.epsEstimate ?? '-'}",
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          if (event.revenueActual != null || event.revenueEstimate != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Revenue / Forecast", style: TextStyle(color: Colors.grey, fontSize: 13)),
                Row(
                  children: [
                    Text(
                      "${event.revenueActual ?? '-'}B ",
                      style: TextStyle(
                        color: (event.revenueActual ?? 0) >= (event.revenueEstimate ?? 0) ? AppColors.profitGreen : Colors.red,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      "/ ${event.revenueEstimate ?? '-'}B",
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ],
          if (event.surprisePercent != null) ...[
            const SizedBox(height: 6),
            _buildMetricRow(
              "Surprise",
              "${event.surprisePercent! >= 0 ? '+' : ''}${event.surprisePercent!.toStringAsFixed(1)}%",
              valueColor: event.surprisePercent! >= 0 ? AppColors.profitGreen : Colors.red,
            ),
          ],
          if (event.time != null && event.time!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildMetricRow(
              "Time",
              event.time!.toLowerCase() == 'amc' 
                ? "After Close" 
                : event.time!.toLowerCase() == 'bmo' 
                  ? "Before Open" 
                  : event.time!.toUpperCase(),
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              children: _getDetailedTextSpans(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value, style: TextStyle(color: valueColor ?? Colors.white70, fontSize: 13)),
      ],
    );
  }

  String _getEventDetails() {
    if (event.actual != null) {
      return "Act: ${event.actual} | Prev: ${event.previous ?? '-'}";
    }
    if (event.amount != null) {
      return "Amount: ${event.amount}";
    }
    return event.description ?? '';
  }

  int _getActiveRabbits() {
    // Economic events
    if (event.impact != null) {
      return event.impact!;
    }

    // Earnings
    if (category == 'earnings' || event.surprisePercent != null) {
      final surprise = event.surprisePercent ?? 0.0;
      if (surprise >= 5.0) return 3; // High positive surprise
      if (surprise >= 0.0) return 2; // Met or slightly beat
      return 1; // Missed expectations
    }

    // Dividends
    if (category == 'dividends' || event.dividendYield != null) {
      final yieldVal = event.dividendYield ?? 0.0;
      if (yieldVal >= 4.0) return 3; // High yield
      if (yieldVal >= 1.5) return 2; // Average yield
      return 1; // Low yield
    }

    // IPOs
    if (category == 'ipo') {
      final shares = event.shares ?? 0;
      if (shares >= 20000000) return 3; // Large IPO
      if (shares >= 5000000) return 2; // Mid IPO
      return 1; // Small IPO
    }

    // Splits
    if (category == 'splits') {
      if (event.fromFactor != null && event.toFactor != null) {
        if (event.toFactor! >= 3) return 3; // Major split (e.g. 3-for-1 or more)
        if (event.toFactor! > 1) return 2; // Standard split
      }
      return 1;
    }

    // Default fallback
    return 1;
  }
}
