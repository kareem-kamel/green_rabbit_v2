import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/calendar_event.dart';

class CalendarEventCard extends StatelessWidget {
  final CalendarEvent event;

  const CalendarEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    // If it's a holiday (based on description or name containing holiday)
    final isHoliday = event.name?.toLowerCase().contains('holiday') ?? false;

    if (isHoliday) {
      return Container(
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
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161922),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column (Flag/Currency)
          SizedBox(
            width: 75, // Increased for Holiday currency+flag
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event.lastPrice == null && event.dividendYield == null && event.epsActual == null && event.actual == null)
                  // Holiday Layout: JPY [Flag]
                  Row(
                    children: [
                      Text(
                        event.currency ?? 'JPY',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(width: 6),
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
                    ],
                  )
                else ...[
                  // Standard Layout: Flag above Currency
                  Container(
                    width: 32,
                    height: 20,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      image: event.instrument?.logoUrl != null 
                        ? DecorationImage(image: NetworkImage(event.instrument!.logoUrl!), fit: BoxFit.cover)
                        : null,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    event.currency ?? 'USD',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                ],
                if (event.impact != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(3, (index) {
                      final isHighlighted = (event.impact ?? 1) > index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Image.asset(
                          isHighlighted ? 'assets/rabbit_highlighted.png' : 'assets/rabbit_dark.png',
                          width: 14,
                          height: 14,
                        ),
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Event Name and Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.name ?? event.symbol,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w300),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (event.lastPrice == null && event.dividendYield == null && event.epsActual == null && event.actual == null) ...[
                  const SizedBox(height: 4),
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
    );
  }

  List<TextSpan> _getDetailedTextSpans() {
    if (event.epsEstimate != null || event.epsActual != null) {
      // Earnings Layout
      return [
        const TextSpan(text: "EPS / Forecast"),
        const TextSpan(text: "\n"), // Placeholder for layout, actually using separate RichTexts would be better but let's try to fit
        TextSpan(
          text: "${event.epsActual ?? '-'} / ${event.epsEstimate ?? '-'}",
          style: TextStyle(color: (event.epsActual ?? 0) >= (event.epsEstimate ?? 0) ? AppColors.profitGreen : Colors.red),
        ),
        const TextSpan(text: "\nRevenue / Forecast\n"),
        TextSpan(
          text: "${event.revenueActual ?? '-'}B / ${event.revenueEstimate ?? '-'}B",
          style: TextStyle(color: (event.revenueActual ?? 0) >= (event.revenueEstimate ?? 0) ? AppColors.profitGreen : Colors.red),
        ),
      ];
    }
    
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
    if (event.lastPrice != null || event.ipoValue != null || event.priceRangeLow != null) {
      // IPO Layout
      final bool isUpcoming = event.lastPrice == null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUpcoming)
            _buildMetricRow("Last Price", event.lastPrice?.toString() ?? '-'),
          if (isUpcoming)
            _buildMetricRow("IPO Price", "${event.priceRangeLow ?? '-'} - ${event.priceRangeHigh ?? '-'}")
          else
            _buildMetricRow("IPO Price", event.offerPrice?.toString() ?? '-'),
          if (isUpcoming && event.ipoValue != null)
            _buildMetricRow("IPO Value", event.ipoValue!),
          _buildMetricRow("Exchange", event.exchange ?? 'NYSE'),
        ],
      );
    }

    if (event.dividendYield != null || event.paymentDate != null) {
      // Dividend Layout
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildMetricRow("Dividend / Yield", "${event.amount ?? '-'} (${event.dividendYield ?? '-'}%)"),
          const SizedBox(height: 4),
          _buildMetricRow("Payment Date", event.paymentDate ?? '-'),
          const SizedBox(height: 4),
          _buildMetricRow("Type", event.dividendType ?? '-'),
        ],
      );
    }

    if (event.epsEstimate != null || event.epsActual != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text("EPS / Forecast", style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(width: 12),
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
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text("Revenue / Forecast", style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(width: 12),
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
        const Icon(Icons.diamond, color: Colors.amber, size: 14),
      ],
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(width: 12),
        Text(value, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }

  String _getEventDetails() {
    if (event.actual != null) {
      return "Act: ${event.actual} | Prev: ${event.previous ?? '-'}";
    }
    if (event.epsEstimate != null) {
      return "Est: ${event.epsEstimate} | Act: ${event.epsActual ?? '-'}";
    }
    if (event.amount != null) {
      return "Amount: ${event.amount}";
    }
    return event.description ?? '';
  }
}
