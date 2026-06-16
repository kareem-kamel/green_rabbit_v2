import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/calendar_event.dart';
import '../../../market/presentation/pages/instrument_detail_page.dart';
import 'package:country_flags/country_flags.dart';
import 'package:currency_symbols/currency_symbols.dart';

class CalendarEventCard extends StatelessWidget {
  final CalendarEvent event;
  final String? category;

  const CalendarEventCard({super.key, required this.event, this.category});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF161922) : Colors.white;
    final cardBorderColor = isDark ? const Color(0xFF242936) : Colors.black.withOpacity(0.08);
    final textPrimaryColor = isDark ? Colors.white : Colors.black87;
    final textSecondaryColor = isDark ? Colors.grey : Colors.black54;
    final subCardBgColor = isDark ? const Color(0xFF1E222D) : Colors.black.withOpacity(0.03);

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
            color: cardBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorderColor, width: 0.8),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Holiday", style: TextStyle(color: textPrimaryColor, fontSize: 16)),
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
                  style: TextStyle(color: textPrimaryColor, fontSize: 18, fontWeight: FontWeight.w300),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hasMetrics = 
        category == 'ipo' ||
        category == 'economic' ||
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
        event.consensus != null ||
        event.previous != null ||
        event.reportName != null;

    final String? currencyVal = (category == 'dividends' || category == 'splits') ? null : (event.currency ?? 'USD');

    return GestureDetector(
      onTap: category == 'economic'
          ? null
          : () {
              final instrumentId = event.instrument?.id ?? event.symbol;
              if (instrumentId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InstrumentDetailPage(instrumentId: instrumentId),
                  ),
                );
              } else if (event.consensus != null || event.reportName != null) {
                _showEconomicDetailsBottomSheet(context);
              }
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorderColor, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Time, Flag, Currency on the left; Importance (Rabbits) on the right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (event.time != null && event.time!.isNotEmpty) ...[
                      Text(
                        event.time!.toUpperCase(),
                        style: TextStyle(
                          color: textPrimaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Dot separator
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Country Flag
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: SafeCountryFlag(
                        symbol: event.symbol,
                        country: event.country,
                        isoCode: event.isoCountryCode,
                        exchange: event.exchange ?? event.instrument?.exchange,
                        currency: event.currency,
                        width: 16,
                        height: 11,
                      ),
                    ),
                    if (currencyVal != null && currencyVal.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${cSymbol(currencyVal)} $currencyVal',
                        style: TextStyle(color: textSecondaryColor, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
                if (category != 'ipo')
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      final activeCount = _getActiveRabbits();
                      final isHighlighted = activeCount > index;
                      return Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Image.asset(
                          isHighlighted ? 'assets/green_rabbit.png' : 'assets/rabbit_dark.png',
                          width: 12,
                          height: 12,
                        ),
                      );
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // Event Name and Details
            Text(
              event.name ?? event.symbol,
              style: TextStyle(color: textPrimaryColor, fontSize: 15, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (category != 'economic' && (event.symbol.isNotEmpty || event.instrument?.symbol != null)) ...[
              const SizedBox(height: 4),
              Text(
                '${event.symbol.isNotEmpty ? event.symbol : (event.instrument?.symbol ?? '')}${event.exchange != null && event.exchange!.isNotEmpty ? ' | ${event.exchange}' : (event.instrument?.exchange != null && event.instrument!.exchange!.isNotEmpty ? ' | ${event.instrument!.exchange}' : '')}',
                style: TextStyle(color: textSecondaryColor, fontSize: 11, fontWeight: FontWeight.w400),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (!hasMetrics) ...[
              if (event.description != null && event.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  event.description!,
                  style: TextStyle(color: textSecondaryColor, fontSize: 13),
                ),
              ],
            ] else ...[
              const SizedBox(height: 10),
              _buildMetrics(
                isDark: isDark,
                cardBgColor: cardBgColor,
                cardBorderColor: cardBorderColor,
                textPrimaryColor: textPrimaryColor,
                textSecondaryColor: textSecondaryColor,
                subCardBgColor: subCardBgColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<TextSpan> _getDetailedTextSpans(Color textPrimaryColor) {
    if (event.actual != null) {
      return [
        const TextSpan(text: "Act:"),
        TextSpan(text: "${event.actual} ", style: TextStyle(color: textPrimaryColor.withOpacity(0.7))),
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
  Widget _buildMetrics({
    required bool isDark,
    required Color cardBgColor,
    required Color cardBorderColor,
    required Color textPrimaryColor,
    required Color textSecondaryColor,
    required Color subCardBgColor,
  }) {
    // Splits Layout
    if (event.fromFactor != null || event.toFactor != null || event.ratio != null) {
      String ratioText = "-";
      if (event.fromFactor != null && event.toFactor != null) {
        ratioText = "${event.toFactor} : ${event.fromFactor}";
      } else if (event.ratio != null) {
        ratioText = "1 : ${(1 / event.ratio!).toStringAsFixed(0)}";
      }

      String splitType = "Stock Split";
      Color typeColor = textPrimaryColor.withOpacity(0.7);
      if (event.fromFactor != null && event.toFactor != null) {
        if (event.fromFactor! > event.toFactor!) {
          splitType = "Reverse Split";
          typeColor = Colors.red;
        } else {
          splitType = "Forward Split";
          typeColor = AppColors.profitGreen;
        }
      }

      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: subCardBgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cardBorderColor, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMetricRow("Ratio", ratioText, textSecondaryColor, textPrimaryColor),
            const SizedBox(height: 6),
            _buildMetricRow("Type", splitType, textSecondaryColor, textPrimaryColor, valueColor: typeColor),
          ],
        ),
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
        metrics.add(_buildMetricRow("Symbol / Exchange", symbolExchange, textSecondaryColor, textPrimaryColor));
      }
      
      if (!isUpcoming && event.lastPrice != null) {
        metrics.add(_buildMetricRow("Last Price", "\$${event.lastPrice!.toStringAsFixed(2)}", textSecondaryColor, textPrimaryColor));
      }
      
      if (isUpcoming) {
        if (event.priceRangeLow != null && event.priceRangeHigh != null) {
          if (event.priceRangeLow == event.priceRangeHigh) {
            metrics.add(_buildMetricRow("Price Range", "\$${event.priceRangeLow!.toStringAsFixed(2)}", textSecondaryColor, textPrimaryColor));
          } else {
            metrics.add(_buildMetricRow("Price Range", "\$${event.priceRangeLow!.toStringAsFixed(2)} - \$${event.priceRangeHigh!.toStringAsFixed(2)}", textSecondaryColor, textPrimaryColor));
          }
        } else {
          metrics.add(_buildMetricRow("Price Range", "TBD", textSecondaryColor, textPrimaryColor));
        }
      }
      
      if (event.offerPrice != null && event.offerPrice! > 0) {
        metrics.add(_buildMetricRow("Offer Price", "\$${event.offerPrice!.toStringAsFixed(2)}", textSecondaryColor, textPrimaryColor));
      } else {
        metrics.add(_buildMetricRow("Offer Price", "TBD", textSecondaryColor, textPrimaryColor));
      }
      
      if (event.shares != null && event.shares! > 0) {
        metrics.add(_buildMetricRow("Shares", NumberFormat.compact().format(event.shares), textSecondaryColor, textPrimaryColor));
      } else {
        metrics.add(_buildMetricRow("Shares", "TBD", textSecondaryColor, textPrimaryColor));
      }
      
      if (isUpcoming) {
        if (event.ipoValue != null && event.ipoValue!.isNotEmpty) {
          metrics.add(_buildMetricRow("IPO Value", event.ipoValue!, textSecondaryColor, textPrimaryColor));
        } else {
          metrics.add(_buildMetricRow("IPO Value", "TBD", textSecondaryColor, textPrimaryColor));
        }
      }

      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: subCardBgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cardBorderColor, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: () {
            final List<Widget> children = [];
            for (int i = 0; i < metrics.length; i++) {
              if (i > 0) children.add(const SizedBox(height: 6));
              children.add(metrics[i]);
            }
            return children;
          }(),
        ),
      );
    }

    // Dividend Layout
    if (event.dividendYield != null || event.paymentDate != null) {
      final String yieldStr = event.dividendYield != null ? " (${event.dividendYield!.toStringAsFixed(2)}%)" : "";
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: subCardBgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cardBorderColor, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMetricRow("Dividend / Yield", "\$${event.amount ?? '-'} $yieldStr", textSecondaryColor, textPrimaryColor),
            if (event.paymentDate != null && event.paymentDate!.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildMetricRow("Payment Date", event.paymentDate!, textSecondaryColor, textPrimaryColor),
            ],
            if (event.dividendType != null && event.dividendType!.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildMetricRow("Type", event.dividendType!, textSecondaryColor, textPrimaryColor),
            ],
          ],
        ),
      );
    }

    // Earnings Layout
    if (event.epsEstimate != null || event.epsActual != null) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: subCardBgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cardBorderColor, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("EPS / Forecast", style: TextStyle(color: textSecondaryColor, fontSize: 13)),
                const SizedBox(width: 8),
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${event.epsActual ?? '-'} ",
                        style: TextStyle(
                          color: (event.epsActual ?? 0) >= (event.epsEstimate ?? 0) ? AppColors.profitGreen : Colors.red,
                          fontSize: 13,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          "/ ${event.epsEstimate ?? '-'}",
                          style: TextStyle(color: textPrimaryColor.withOpacity(0.7), fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (event.revenueActual != null || event.revenueEstimate != null) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Revenue / Forecast", style: TextStyle(color: textSecondaryColor, fontSize: 13)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${event.revenueActual ?? '-'}B ",
                          style: TextStyle(
                            color: (event.revenueActual ?? 0) >= (event.revenueEstimate ?? 0) ? AppColors.profitGreen : Colors.red,
                            fontSize: 13,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            "/ ${event.revenueEstimate ?? '-'}B",
                            style: TextStyle(color: textPrimaryColor.withOpacity(0.7), fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (event.surprisePercent != null) ...[
              const SizedBox(height: 6),
              _buildMetricRow(
                "Surprise",
                "${event.surprisePercent! >= 0 ? '+' : ''}${event.surprisePercent!.toStringAsFixed(1)}%",
                textSecondaryColor,
                textPrimaryColor,
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
                textSecondaryColor,
                textPrimaryColor,
              ),
            ],
          ],
        ),
      );
    }

    // Economic Layout
    if (category == 'economic' ||
        event.actual != null ||
        event.consensus != null ||
        event.previous != null) {
      final actualVal = event.actual ?? '-';
      final consensusVal = event.consensus ?? event.forecast ?? '-';
      final previousVal = event.previous ?? '-';

      Color actualColor = textPrimaryColor;
      final actNum = _parseMetricValue(event.actual);
      final consNum = _parseMetricValue(event.consensus ?? event.forecast);
      if (actNum != null && consNum != null && actNum != consNum) {
        final nameLower = (event.name ?? event.reportName ?? '').toLowerCase();
        final lowerIsBetter = nameLower.contains('claims') || 
                              nameLower.contains('unemployment') || 
                              nameLower.contains('cpi') || 
                              nameLower.contains('ppi') || 
                              nameLower.contains('inflation') || 
                              nameLower.contains('deficit');
        
        final isBetter = lowerIsBetter ? (actNum < consNum) : (actNum > consNum);
        actualColor = isBetter ? AppColors.profitGreen : Colors.red;
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: subCardBgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cardBorderColor, width: 0.8),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildEconomicMetricColumn("Actual", actualVal, textSecondaryColor, textPrimaryColor, valueColor: actualColor, isActual: true),
            ),
            Container(
              width: 1,
              height: 24,
              color: cardBorderColor,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: _buildEconomicMetricColumn("Consensus", consensusVal, textSecondaryColor, textPrimaryColor),
              ),
            ),
            Container(
              width: 1,
              height: 24,
              color: cardBorderColor,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: _buildEconomicMetricColumn("Previous", previousVal, textSecondaryColor, textPrimaryColor),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: subCardBgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardBorderColor, width: 0.8),
      ),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: textSecondaryColor, fontSize: 13),
                children: _getDetailedTextSpans(textPrimaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color labelColor, Color defaultValColor, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: labelColor, fontSize: 13)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(color: valueColor ?? defaultValColor.withOpacity(0.8), fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
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
    return event.importance ?? event.impact ?? 1;
  }

  double? _parseMetricValue(String? value) {
    if (value == null) return null;
    final match = RegExp(r'[-+]?[0-9]*\.?[0-9]+').firstMatch(value);
    if (match != null) {
      double val = double.tryParse(match.group(0)!) ?? 0;
      final lowerVal = value.toLowerCase();
      if (lowerVal.contains('k')) {
        val *= 1000;
      } else if (lowerVal.contains('m')) {
        val *= 1000000;
      } else if (lowerVal.contains('b')) {
        val *= 1000000000;
      } else if (lowerVal.contains('t')) {
        val *= 1000000000000;
      }
      return val;
    }
    return null;
  }

  Widget _buildEconomicMetricColumn(String label, String value, Color labelColor, Color defaultValColor, {Color? valueColor, bool isActual = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(color: labelColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? defaultValColor,
            fontSize: 13,
            fontWeight: isActual ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showEconomicDetailsBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark ? Colors.white : Colors.black87;
    final textSecondaryColor = isDark ? Colors.grey : Colors.black54;
    final cardBgColor = isDark ? const Color(0xFF161922) : Colors.white;
    final cardBorderColor = isDark ? const Color(0xFF242936) : Colors.black.withOpacity(0.08);
    final bottomSheetBgColor = isDark ? const Color(0xFF161922) : Colors.white;
    final dividerColor = isDark ? const Color(0xFF242936) : Colors.black.withOpacity(0.08);
    final subCardBgColor = isDark ? const Color(0xFF1C2128) : Colors.black.withOpacity(0.04);

    showModalBottomSheet(
      context: context,
      backgroundColor: bottomSheetBgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        final actVal = event.actual;
        final consVal = event.consensus ?? event.forecast;
        final prevVal = event.previous;

        final double? actNum = _parseMetricValue(actVal);
        final double? consNum = _parseMetricValue(consVal);

        String? deviationText;
        Color deviationColor = textPrimaryColor;
        String? surpriseText;

        if (actNum != null && consNum != null) {
          final diff = actNum - consNum;
          final diffFormatted = diff.abs() >= 1000000000 
              ? "${(diff / 1000000000).toStringAsFixed(1)}B" 
              : diff.abs() >= 1000000 
                  ? "${(diff / 1000000).toStringAsFixed(1)}M" 
                  : diff.abs() >= 1000 
                      ? "${(diff / 1000).toStringAsFixed(1)}K" 
                      : diff.toStringAsFixed(1);
          
          final directionSymbol = diff > 0 ? "+" : (diff < 0 ? "-" : "");
          final magnitudeText = diffFormatted.replaceAll('-', '').replaceAll('+', '');
          
          deviationText = diff == 0 ? "0" : "$directionSymbol$magnitudeText";
          
          final nameLower = (event.name ?? event.reportName ?? '').toLowerCase();
          final lowerIsBetter = nameLower.contains('claims') || 
                                nameLower.contains('unemployment') || 
                                nameLower.contains('cpi') || 
                                nameLower.contains('ppi') || 
                                nameLower.contains('inflation') || 
                                nameLower.contains('deficit');
          
          final isBetter = lowerIsBetter ? (diff < 0) : (diff > 0);
          deviationColor = diff == 0 ? textSecondaryColor : (isBetter ? AppColors.profitGreen : Colors.red);

          if (consNum != 0) {
            final surprisePct = (diff / consNum) * 100;
            surpriseText = "${surprisePct > 0 ? '+' : ''}${surprisePct.toStringAsFixed(2)}%";
          }
        }

        String formattedDate = '';
        if (event.reportDate != null) {
          try {
            formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.parse(event.reportDate!));
          } catch (e) {
            formattedDate = event.reportDate!;
          }
        }

        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D5CFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "Economic Indicator",
                      style: TextStyle(color: Color(0xFF2D5CFF), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: SafeCountryFlag(
                          symbol: event.symbol,
                          country: event.country,
                          isoCode: event.isoCountryCode,
                          exchange: event.exchange ?? event.instrument?.exchange,
                          currency: event.currency,
                          width: 24,
                          height: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        event.country ?? event.exchange ?? event.instrument?.exchange ?? '',
                        style: TextStyle(color: textSecondaryColor, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                event.name ?? event.reportName ?? 'Economic Release',
                style: TextStyle(color: textPrimaryColor, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        "$formattedDate${event.time != null ? ' at ${event.time}' : ''}",
                        style: TextStyle(color: textSecondaryColor, fontSize: 13),
                      ),
                    ],
                  ),
                  Row(
                    children: List.generate(3, (index) {
                      final activeCount = event.importance ?? event.impact ?? 1;
                      final isHighlighted = activeCount > index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Image.asset(
                          isHighlighted ? 'assets/green_rabbit.png' : 'assets/rabbit_dark.png',
                          width: 16,
                          height: 16,
                        ),
                      );
                    }),
                  ),
                ],
              ),
              Divider(color: dividerColor, height: 32),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailMetricCard(
                      label: "ACTUAL",
                      value: actVal ?? '-',
                      valueColor: deviationColor,
                      isHighlighted: true,
                      isDark: isDark,
                      textPrimaryColor: textPrimaryColor,
                      textSecondaryColor: textSecondaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailMetricCard(
                      label: "CONSENSUS",
                      value: consVal ?? '-',
                      isDark: isDark,
                      textPrimaryColor: textPrimaryColor,
                      textSecondaryColor: textSecondaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailMetricCard(
                      label: "PREVIOUS",
                      value: prevVal ?? '-',
                      isDark: isDark,
                      textPrimaryColor: textPrimaryColor,
                      textSecondaryColor: textSecondaryColor,
                    ),
                  ),
                ],
              ),
              if (deviationText != null || surpriseText != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: subCardBgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardBorderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (deviationText != null)
                        Column(
                          children: [
                            Text("DEVIATION", style: TextStyle(color: textSecondaryColor, fontSize: 11, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            Text(
                              deviationText,
                              style: TextStyle(color: deviationColor, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      if (deviationText != null && surpriseText != null)
                        Container(width: 1, height: 30, color: dividerColor),
                      if (surpriseText != null)
                        Column(
                          children: [
                            Text("SURPRISE", style: TextStyle(color: textSecondaryColor, fontSize: 11, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            Text(
                              surpriseText,
                              style: TextStyle(color: deviationColor, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabelValueRow("Currency", event.currency ?? 'USD', textSecondaryColor, textPrimaryColor),
                  if (event.unit != null && event.unit!.isNotEmpty)
                    _buildLabelValueRow("Unit", event.unit!, textSecondaryColor, textPrimaryColor),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                "Disclaimer: Economic calendar data is sourced from major public economic reports and is shown for informational purposes. Past releases do not guarantee future trends.",
                style: TextStyle(color: textSecondaryColor, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailMetricCard({
    required String label,
    required String value,
    Color valueColor = Colors.white,
    bool isHighlighted = false,
    required bool isDark,
    required Color textPrimaryColor,
    required Color textSecondaryColor,
  }) {
    final defaultValColor = isHighlighted ? (isDark ? Colors.white : const Color(0xFF2D5CFF)) : textPrimaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isHighlighted 
            ? (isDark ? const Color(0xFF1C2128) : const Color(0xFF2D5CFF).withOpacity(0.08)) 
            : (isDark ? const Color(0xFF161922) : Colors.black.withOpacity(0.02)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted 
              ? const Color(0xFF2D5CFF).withOpacity(0.5) 
              : (isDark ? const Color(0xFF242936) : Colors.black.withOpacity(0.08)),
          width: isHighlighted ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: textSecondaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: valueColor == Colors.white ? defaultValColor : valueColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelValueRow(String label, String value, Color labelColor, Color defaultValColor) {
    return Row(
      children: [
        Text("$label: ", style: TextStyle(color: labelColor, fontSize: 13)),
        Text(value, style: TextStyle(color: defaultValColor, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class SafeCountryFlag extends StatelessWidget {
  final String? symbol;
  final String? country;
  final String? isoCode;
  final String? exchange;
  final String? currency;
  final double width;
  final double height;

  const SafeCountryFlag({
    super.key,
    this.symbol,
    this.country,
    this.isoCode,
    this.exchange,
    this.currency,
    required this.width,
    required this.height,
  });

  static const Map<String, String> _countryNameToCode = {
    'UNITED STATES': 'US',
    'UNITED KINGDOM': 'GB',
    'GREAT BRITAIN': 'GB',
    'GERMANY': 'DE',
    'FRANCE': 'FR',
    'JAPAN': 'JP',
    'CHINA': 'CN',
    'INDIA': 'IN',
    'CANADA': 'CA',
    'AUSTRALIA': 'AU',
    'BRAZIL': 'BR',
    'MEXICO': 'MX',
    'EGYPT': 'EG',
    'SAUDI ARABIA': 'SA',
    'UAE': 'AE',
    'UNITED ARAB EMIRATES': 'AE',
    'QATAR': 'QA',
    'KUWAIT': 'KW',
    'BAHRAIN': 'BH',
    'OMAN': 'OM',
    'ALBANIA': 'AL',
    'ANGOLA': 'AO',
    'EUROPEAN UNION': 'EU',
    'EUROPE': 'EU',
    'TAIWAN': 'TW',
    'MALAYSIA': 'MY',
    'ITALY': 'IT',
    'SPAIN': 'ES',
    'NETHERLANDS': 'NL',
    'BELGIUM': 'BE',
    'SWITZERLAND': 'CH',
    'SWEDEN': 'SE',
    'NORWAY': 'NO',
    'DENMARK': 'DK',
    'FINLAND': 'FI',
    'POLAND': 'PL',
    'TURKEY': 'TR',
    'RUSSIA': 'RU',
    'SOUTH KOREA': 'KR',
    'KOREA': 'KR',
    'SINGAPORE': 'SG',
    'HONG KONG': 'HK',
    'SOUTH AFRICA': 'ZA',
    'INDONESIA': 'ID',
    'THAILAND': 'TH',
    'ISRAEL': 'IL',
    'NEW ZEALAND': 'NZ',
    'AUSTRIA': 'AT',
    'GREECE': 'GR',
    'IRELAND': 'IE',
    'PORTUGAL': 'PT',
    'PHILIPPINES': 'PH',
    'VIETNAM': 'VN',
  };

  static const Map<String, String> _currencyToCountryCode = {
    'MYR': 'MY',
    'TWD': 'TW',
    'GBP': 'GB',
    'GBp': 'GB',
    'USD': 'US',
    'CAD': 'CA',
    'AUD': 'AU',
    'JPY': 'JP',
    'CNY': 'CN',
    'INR': 'IN',
    'HKD': 'HK',
    'SGD': 'SG',
    'ZAR': 'ZA',
    'BRL': 'BR',
    'KRW': 'KR',
    'SAR': 'SA',
    'AED': 'AE',
    'SEK': 'SE',
    'DKK': 'DK',
    'NOK': 'NO',
    'TRY': 'TR',
    'CHF': 'CH',
    'NZD': 'NZ',
    'ILS': 'IL',
    'PLN': 'PL',
    'MXN': 'MX',
    'EGP': 'EG',
    'RUB': 'RU',
    'EUR': 'EU',
  };

  static const Map<String, String> _exchangeToCountryCode = {
    'MYX': 'MY',
    'BURSA': 'MY',
    'KLSE': 'MY',
    'TWSE': 'TW',
    'TWO': 'TW',
    'TSEC': 'TW',
    'TPEX': 'TW',
    'MTA': 'IT',
    'MIL': 'IT',
    'BIT': 'IT',
    'NYSE': 'US',
    'NASDAQ': 'US',
    'AMEX': 'US',
    'BATS': 'US',
    'OTC': 'US',
    'LSE': 'GB',
    'GPW': 'PL',
    'WSE': 'PL',
    'TSE': 'JP',
    'TYO': 'JP',
    'ASX': 'AU',
    'TSX': 'CA',
    'TSXV': 'CA',
    'SEHK': 'HK',
    'HKEX': 'HK',
    'NSE': 'IN',
    'BSE': 'IN',
    'FWB': 'DE',
    'XETR': 'DE',
    'DB': 'DE',
    'SGX': 'SG',
    'JSE': 'ZA',
    'B3': 'BR',
    'SAO': 'BR',
    'SSE': 'CN',
    'SZSE': 'CN',
    'KRX': 'KR',
    'KOSDAQ': 'KR',
    'KOSE': 'KR',
    'TADAWUL': 'SA',
    'DFM': 'AE',
    'ADX': 'AE',
    'OMXS': 'SE',
    'STO': 'SE',
    'OMXC': 'DK',
    'CSE': 'DK',
    'HEX': 'FI',
    'HEL': 'FI',
    'OSE': 'NO',
    'OSL': 'NO',
    'BME': 'ES',
    'MAD': 'ES',
    'ATHEX': 'GR',
    'ASE': 'GR',
    'BIST': 'TR',
    'IDX': 'ID',
    'SET': 'TH',
    'SIX': 'CH',
    'SWX': 'CH',
    'VTX': 'CH',
    'MOEX': 'RU',
    'NZX': 'NZ',
    'TASE': 'IL',
    'ISE': 'IE',
    'ISEQ': 'IE',
    'ENX': 'FR',
    'EPA': 'FR',
    'AMS': 'NL',
    'EBR': 'BE',
    'ELI': 'PT',
  };

  @override
  Widget build(BuildContext context) {
    String code = isoCode?.trim().toUpperCase() ?? '';
    if (code == 'NULL') code = '';

    String normalizedInput = country?.trim().toUpperCase() ?? '';
    if (normalizedInput == 'NULL') normalizedInput = '';

    if (code.isEmpty || code.length < 2 || code.length > 3) {
      if (normalizedInput.isNotEmpty) {
        code = _countryNameToCode[normalizedInput] ?? normalizedInput;
      }
    }

    if (code.isEmpty || code.length < 2 || code.length > 3) {
      final cleanExchange = exchange?.trim().toUpperCase() ?? '';
      if (cleanExchange.isNotEmpty) {
        code = _exchangeToCountryCode[cleanExchange] ?? '';
      }
    }

    if (code.isEmpty || code.length < 2 || code.length > 3) {
      final cleanCurrency = currency?.trim().toUpperCase() ?? '';
      if (cleanCurrency.isNotEmpty) {
        code = _currencyToCountryCode[cleanCurrency] ?? '';
      }
    }

    if (code.isEmpty) {
      debugPrint("SafeCountryFlag Error: Failed to resolve flag code for symbol '$symbol'. (country: $country, isoCode: $isoCode, exchange: $exchange, currency: $currency)");
      return Container(
        width: width,
        height: height,
        color: Colors.grey[800],
      );
    }

    if (code == 'EU') {
      return CountryFlag.fromCurrencyCode(
        'EUR',
        theme: ImageTheme(
          width: width,
          height: height,
        ),
      );
    }

    final finalCode = code == 'UK' ? 'GB' : code;

    if (finalCode.length == 2 || finalCode.length == 3) {
      return CountryFlag.fromCountryCode(
        finalCode,
        theme: ImageTheme(
          width: width,
          height: height,
        ),
      );
    }

    // Fallback: render clean placeholder box if invalid code
    debugPrint("SafeCountryFlag Error: Invalid resolved flag code '$finalCode' for symbol '$symbol'. (country: $country, isoCode: $isoCode, exchange: $exchange, currency: $currency)");
    return Container(
      width: width,
      height: height,
      color: Colors.grey[800],
    );
  }
}
