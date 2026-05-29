import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';
import 'package:green_rabbit/shared/widgets/feature_guide_overlay.dart';
import '../../data/models/alert_model.dart';
import '../cubit/alert_cubit.dart';
import '../cubit/alert_state.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlertCubit>().fetchAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlertCubit, AlertState>(
      builder: (context, state) {
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
                icon: Icon(Icons.help_outline, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => FeatureGuideOverlay(
                      type: GuideType.alerts,
                      onDismiss: () => Navigator.pop(context),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildInfoCard(context),
                    const SizedBox(height: 24),
                    if (state.alerts.isEmpty)
                      _buildEmptyState(context)
                    else
                      ...state.alerts.map((alert) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildAlertCard(context, alert),
                      )),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4C3BC9).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4C3BC9).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF4C3BC9), size: 20),
              const SizedBox(width: 8),
              Text(
                "How alerts work",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 16
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Stay on top of the market by setting price, percentage, or volume alerts. We'll notify you instantly when your conditions are met.",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87, 
              fontSize: 13, 
              height: 1.4
            ),
          ),
        ],
      ),
    );
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
                    context.read<AlertCubit>().deleteAlert(alert.id);
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
