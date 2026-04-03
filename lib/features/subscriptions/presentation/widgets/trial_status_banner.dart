import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TrialStatusBanner extends StatelessWidget {
  final int daysLeft;
  final VoidCallback onTap;

  const TrialStatusBanner({
    super.key,
    required this.daysLeft,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Hourglass Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_bottom, color: Colors.black, size: 24),
            ),
            const SizedBox(width: 16),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$daysLeft days left in your free trial',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Upgrade to continue using Pro features.',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black45, size: 24),
          ],
        ),
      ),
    );
  }
}
