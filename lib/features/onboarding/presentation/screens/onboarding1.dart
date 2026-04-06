import 'package:flutter/material.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';
import 'package:green_rabbit/features/onboarding/presentation/widgets/app_button.dart';
import 'package:green_rabbit/features/onboarding/presentation/widgets/onboarding_dot.dart';

class OnboardingPageOne extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const OnboardingPageOne({
    super.key,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── BACKGROUND IMAGE ──────────────────────────
          Image.asset('assets/images/onboarding_1.png', fit: BoxFit.cover),

          // ── DARK GRADIENT OVERLAY ─────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.3, 0.6, 1.0],
                colors: [
                  Colors.transparent,
                  Color(0xBB0F131A),
                  Color(0xFF0F131A),
                ],
              ),
            ),
          ),

          // ── SKIP BUTTON ───────────────────────────────
          Positioned(
            top: topInset + 12,
            right: 24,
            child: GestureDetector(
              onTap: onSkip,
              child: const Text(
                'Skip',
                style: TextStyle(
                  fontFamily: 'Urbanist',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // ── TITLE + SUBTITLE ──────────────────────────
          Positioned(
            left: 24,
            right: 24,
            bottom: 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Analytical power',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Get AI-driven insights on top assets. Know exactly\nwhen and where to move.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textGrey,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          // ── BOTTOM PANEL ──────────────────────────────
          Positioned(
            left: 24,
            right: 24,
            bottom: 24 + bottomInset,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dots — page 1 of 2
                const DotsIndicator(count: 2, currentIndex: 0),
                const SizedBox(height: 28),

                // Next Button
                AppButton(label: 'Next', onPressed: onNext),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
