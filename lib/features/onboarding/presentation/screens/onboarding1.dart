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
    final double safeBottom = MediaQuery.paddingOf(context).bottom;
    final double safeTop = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      extendBodyBehindAppBar: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double maxHeight = constraints.maxHeight;
          // تحديد ما إذا كانت الشاشة قصيرة رأسيًا (أقل من 700 بكسل)
          final bool isShortScreen = maxHeight < 700;

          return Stack(
            fit: StackFit.expand,
            children: [
              // ── BACKGROUND IMAGE ──────────────────────────
              // تم استخدام Alignment.center لضمان بقاء الصورة متناسقة عند تمدد المتصفح يميناً ويساراً
              Image.asset(
                'assets/images/onboarding_1.png',
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
              // هذا الجزء يضمن توزيع العناصر بشكل متناسق ومحمي من الـ Overflow تماماً
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 450, // حماية محاذاة العناصر على الويب والتابلت
                      ),
                      child: Column(
                        children: [
                          // 1. منطقة الـ Skip Button في الأعلى
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12.0),
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
                          ),
                          
                          // مساحة مرنة تدفع النصوص والتحكم للأسفل بتناسق
                          const Spacer(),

                          // 2. منطقة النصوص (Title + Subtitle)
                          Text(
                            'Analytical power',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Urbanist',
                              fontSize: isShortScreen ? 24 : 28, // تصغير ديناميكي بحسب الارتفاع
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.25,
                            ),
                          ),
                          SizedBox(height: isShortScreen ? 8 : 12),
                          Text(
                            'Get AI-driven insights on top assets. Know exactly when and where to move.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Urbanist',
                              fontSize: isShortScreen ? 13 : 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textGrey,
                              height: 1.5,
                            ),
                          ),

                          // مسافة مرنة بين النصوص وقسم الأزرار السفلي
                          SizedBox(height: isShortScreen ? 30 : 50),

                          // 3. منطقة التحكم السفلية (Dots + Button)
                          DotsIndicator(count: 2, currentIndex: 0),
                          SizedBox(height: isShortScreen ? 20 : 28),
                          
                          AppButton(label: 'Next', onPressed: onNext),
                          
                          // مسافة أمان ديناميكية سفلية تتكيف مع أبعاد نظام التشغيل (مثل نوتش الآيفون السفلي)
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