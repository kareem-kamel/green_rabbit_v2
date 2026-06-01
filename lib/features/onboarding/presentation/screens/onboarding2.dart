import 'package:flutter/material.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';
import 'package:green_rabbit/features/onboarding/presentation/widgets/app_button.dart';
import 'package:green_rabbit/features/onboarding/presentation/widgets/onboarding_dot.dart';

class OnboardingPageTwo extends StatelessWidget {
  final VoidCallback onGetStarted;

  const OnboardingPageTwo({
    super.key,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    final double safeBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      extendBodyBehindAppBar: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double maxHeight = constraints.maxHeight;
          // فحص ما إذا كانت الشاشة قصيرة رأسيًا لحماية الواجهة من الـ Overflow
          final bool isShortScreen = maxHeight < 700;

          return Stack(
            fit: StackFit.expand,
            children: [
              // ── BACKGROUND IMAGE ──────────────────────────
              Image.asset(
                'assets/images/onboarding_2.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),

              // ── DARK GRADIENT OVERLAY ─────────────────────
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.2, 0.55, 1.0],
                    colors: [
                      Colors.transparent,
                      Color(0xCC0F131A),
                      Color(0xFF0F131A),
                    ],
                  ),
                ),
              ),

              // ── SAFE CONTENT LAYER ────────────────────────
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 450, // لحماية التصميم من التمدد العرضي البشع على الويب والتابلت
                      ),
                      child: Column(
                        children: [
                          // مساحة مرنة تدفع المحتوى بالكامل للأسفل بتناسق
                          const Spacer(),

                          // 1. منطقة النصوص (Title + Subtitle)
                          Text(
                            'Stay ahead',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Urbanist',
                              fontSize: isShortScreen ? 24 : 28, // تصغير مرن للخط بحسب ارتفاع الشاشة
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.25,
                            ),
                          ),
                          SizedBox(height: isShortScreen ? 8 : 12),
                          Text(
                            'Instant alerts for every market shift. Your price targets, tracked.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Urbanist',
                              fontSize: isShortScreen ? 13 : 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textGrey,
                              height: 1.5,
                            ),
                          ),

                          // مسافة ديناميكية تتكيف مع حجم الشاشة المتاح
                          SizedBox(height: isShortScreen ? 30 : 50),

                          // 2. منطقة التحكم السفلية (Dots + Get Started Button)
                          const DotsIndicator(count: 2, currentIndex: 1), // الصفحة 2 من 2
                          SizedBox(height: isShortScreen ? 20 : 28),
                          
                          AppButton(
                            label: 'Get Started', 
                            onPressed: onGetStarted,
                          ),
                          
                          // مسافة أمان سفلية متوافقة مع أنظمة التشغيل المختلفة ومقاساتها
                          SizedBox(height: safeBottom > 0 ? safeBottom : 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}