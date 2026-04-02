import 'package:flutter/material.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';
import 'package:green_rabbit/features/onboarding/presentation/widgets/app_button.dart';
import 'package:green_rabbit/features/onboarding/presentation/widgets/onboarding_dot.dart';

class OnboardingPageTwo extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onJoinAsGuest;

  const OnboardingPageTwo({
    super.key,
    required this.onGetStarted,
    required this.onJoinAsGuest,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── BACKGROUND IMAGE ──────────────────────────
          Image.asset('assets/images/onboarding_2.png', fit: BoxFit.cover),

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

          // ── TITLE + SUBTITLE ──────────────────────────
          Positioned(
            left: 24,
            right: 24,
            bottom: 220,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Stay ahead',
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
                  'Instant alerts for every market shift. Your price\ntargets, tracked.',
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
                // Dots — page 2 of 2
                const DotsIndicator(count: 2, currentIndex: 1),
                const SizedBox(height: 28),

                // Get Started Button
                AppButton(label: 'Get Started', onPressed: onGetStarted),
                const SizedBox(height: 14),

                // Join As A Guest Button
                AppButton(
                  label: 'Join As A Guest',
                  onPressed: onJoinAsGuest,
                  style: AppButtonStyle.outline,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
