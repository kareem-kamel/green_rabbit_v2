import 'package:flutter/material.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';
import '../../data/models/alert_model.dart';
import 'package:green_rabbit/features/market/data/models/market_instrument.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for display based on API docs
    final alerts = [
      AlertModel(
        id: 'a1b2c3d4-e5f6-7890-abcd-ef0123456789',
        instrument: _mockInstrument('AAPL', 'Apple Inc.'),
        targetPrice: 200,
        type: 'price_above',
        typeDisplay: 'Price goes above \$200.00',
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      AlertModel(
        id: 'b2c3d4e5-f6a7-8901-bcde-f01234567890',
        instrument: _mockInstrument('NVDA', 'NVIDIA Corp.'),
        targetPrice: 100,
        type: 'price_below',
        typeDisplay: 'Price goes below \$100.00',
        status: 'triggered',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        triggeredAt: DateTime.now().subtract(const Duration(days: 5)),
        triggeredPrice: 99.87,
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Price Alerts',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Show dialog to create new alert
            },
            icon: Icon(Icons.add_circle_outline, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: alerts.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: alerts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return _buildAlertCard(context, alert);
              },
            ),
    );
  }

  MarketInstrument _mockInstrument(String symbol, String name) {
    // This uses a raw Map for fromJson since the real constructor might change
    return _instrumentFromMap({
      'id': symbol,
      'symbol': symbol,
      'name': name,
      'type': 'stock',
      'price': 150.0,
      'change': 2.5,
      'changePercent': 1.2,
      'logoUrl': 'https://cdn.greenrabbit.app/logos/${symbol.toLowerCase()}.png',
    });
  }

  dynamic _instrumentFromMap(Map<String, dynamic> map) {
    // Return an instance of MarketInstrument if possible, or just a mock
    return MarketInstrument.fromJson(map);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_alert_outlined, size: 64, color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black12),
          const SizedBox(height: 16),
          Text(
            'No price alerts set',
            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.black38, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4C3BC9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Create New Alert', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, AlertModel alert) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isActive = alert.status == 'active';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? const Color(0xFF4C3BC9).withOpacity(0.3) : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Image.network(
                    alert.instrument.logoUrl ?? '',
                    width: 24, height: 24,
                    errorBuilder: (_, __, ___) => const Icon(Icons.show_chart, color: Colors.grey, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert.instrument.symbol, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(alert.instrument.name, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  alert.status.toUpperCase(),
                  style: TextStyle(color: isActive ? Colors.blue : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05), height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Condition', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(alert.typeDisplay, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14)),
                ],
              ),
              if (alert.triggeredAt != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Triggered on', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      '${alert.triggeredAt!.day}/${alert.triggeredAt!.month} at \$${alert.triggeredPrice}',
                      style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
                    ),
                  ],
                )
              else
                IconButton(
                  onPressed: () {
                    // API: Delete alert
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
