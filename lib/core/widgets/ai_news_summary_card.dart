import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AiNewsSummaryCard extends StatelessWidget {
  final VoidCallback? onTap;
  const AiNewsSummaryCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          gradient: const LinearGradient(
            begin: Alignment(-0.72, 1.88),
            end: Alignment(1.26, -0.46),
            colors: [Color(0xFF5B4ACF), Color(0xFF0E1117)],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Image.asset(
                    'assets/icons/ainewssummary.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Summarize the news using Artificial Intelligence.',
                        style: TextStyle(
                          color: AppColors.textOffWhite,
                          fontSize: 16,
                          fontFamily: 'Urbanist',
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'What matters most to investors',
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 13,
                          fontFamily: 'Urbanist',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, color: Colors.white70, size: 20),
              ],
            ),
            Positioned(
              left: -16,
              top: -25,
              child: Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment(0.00, 0.50),
                    end: Alignment(1.00, 0.50),
                    colors: [Color(0xFFFF8D28), Color(0xFFFACC15)],
                  ),
                  // Use a very large radius to guarantee a perfect capsule/oval
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(100), bottomRight: Radius.circular(100), topRight: Radius.circular(100)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: Image.asset(
                        'assets/icons/aifreetrail.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Free Trial',
                      style: TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 10,
                        fontFamily: 'Urbanist',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
