import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/alert_cubit.dart';
import '../cubit/alert_state.dart';
import '../widgets/alert_tile.dart';

class AlertsListScreen extends StatefulWidget {
  const AlertsListScreen({super.key});

  @override
  State<AlertsListScreen> createState() => _AlertsListScreenState();
}

class _AlertsListScreenState extends State<AlertsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AlertCubit>().fetchAlerts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBg,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Manage Alerts",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded, color: AppColors.textGrey),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocBuilder<AlertCubit, AlertState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple));
          }

          final activeAlerts = state.alerts.where((a) => a.status == 'active').toList();
          final triggeredAlerts = state.alerts.where((a) => a.status == 'triggered' || a.status == 'expired').toList();

          return RefreshIndicator(
            onRefresh: () => context.read<AlertCubit>().fetchAlerts(),
            color: AppColors.primaryPurple,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSectionHeader("Active Alerts"),
                const SizedBox(height: 16),
                
                if (activeAlerts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text("No active alerts", style: TextStyle(color: AppColors.textGrey))),
                  ),
                  
                ...activeAlerts.map((alert) => AlertTile(
                  assetName: alert.instrument.symbol,
                  targetPrice: alert.targetPrice.toStringAsFixed(2),
                  isActive: true,
                  onToggle: (val) {
                    // Logic to update specific alert would go here
                  },
                  onDelete: () => context.read<AlertCubit>().deleteAlert(alert.id),
                )),
                
                const SizedBox(height: 32),
                _buildSectionHeader("Recent Triggers & Expired"),
                const SizedBox(height: 16),
                
                if (triggeredAlerts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text("No recent triggers", style: TextStyle(color: AppColors.textGrey))),
                  ),
                  
                ...triggeredAlerts.map((alert) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTriggeredLog(
                    alert.instrument.symbol, 
                    alert.typeDisplay, 
                    alert.triggeredPrice?.toStringAsFixed(2) ?? alert.targetPrice.toStringAsFixed(2),
                    alert.triggeredAt ?? alert.updatedAt,
                  ),
                )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textGrey,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTriggeredLog(String asset, String condition, String price, DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    String timeAgo = difference.inHours > 0 
        ? "${difference.inHours}h ago" 
        : "${difference.inMinutes}m ago";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: AppColors.textGrey, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "$asset $condition \$$price",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(timeAgo, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
        ],
      ),
    );
  }
}