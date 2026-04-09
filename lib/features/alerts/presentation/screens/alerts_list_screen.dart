import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/alert_cubit.dart';
import '../cubit/alert_state.dart';
import '../widgets/alert_tile.dart';

class AlertsListScreen extends StatelessWidget {
  const AlertsListScreen({super.key});

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
          // For now, we'll show a sample list. 
          // Later, you'll add a 'List<AlertModel> savedAlerts' to your AlertState.
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSectionHeader("Active Alerts"),
              const SizedBox(height: 16),
              
              // Sample Alert Tile using your existing style logic
              AlertTile(
                assetName: "BTC / USDT",
                targetPrice: "68,500.00",
                isActive: true,
                onToggle: (val) {
                  // Logic to toggle specific alert would go here
                },
                onDelete: () {},
              ),
              
              AlertTile(
                assetName: "ETH / USDT",
                targetPrice: "3,450.25",
                isActive: false,
                onToggle: (val) {},
                onDelete: () {},
              ),
              
              const SizedBox(height: 32),
              _buildSectionHeader("Recent Triggers"),
              const SizedBox(height: 16),
              _buildTriggeredLog("Silver", "Move Above", "113.22"),
            ],
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

  Widget _buildTriggeredLog(String asset, String condition, String price) {
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
          Text(
            "$asset $condition \$$price",
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const Spacer(),
          const Text("2h ago", style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
        ],
      ),
    );
  }
}