import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AlertTile extends StatelessWidget {
  final String assetName;
  final String targetPrice;
  final bool isActive;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const AlertTile({
    super.key,
    required this.assetName,
    required this.targetPrice,
    required this.isActive,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
            child: const Icon(Icons.notifications_active_outlined, 
              color: AppColors.primaryPurple, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assetName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "Alert at \$$targetPrice",
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                ),
              ],
            ),
          ),
          // Custom Styled Switch
          Switch(
            value: isActive,
            onChanged: onToggle,
            activeThumbColor: AppColors.primaryPurple,
            activeTrackColor: AppColors.primaryPurple.withOpacity(0.3),
            inactiveThumbColor: AppColors.textGrey,
            inactiveTrackColor: Colors.white10,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}