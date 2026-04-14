import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_rabbit/core/di/injection_container.dart';
import 'package:green_rabbit/features/auth/data/api/auth_api.dart';
import 'package:green_rabbit/features/auth/data/repository/auth_repository.dart';
import 'package:green_rabbit/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:green_rabbit/features/auth/presentation/screens/login_screen.dart';
import 'package:green_rabbit/features/onboarding/presentation/screens/onboarding2.dart';
import 'package:green_rabbit/features/onboarding/presentation/screens/onboarding1.dart';
import 'package:green_rabbit/shared/widgets/main_wrapper.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  void _goToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _skipToLastPage() {
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _getStarted() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
            builder: (context) => BlocProvider(
              // The professional way: Ask your injection container for the Cubit!
              create: (context) => sl<AuthCubit>(), 
              child: const LoginScreen(),
            ),
          ),
    );
  }

  void _joinAsGuest() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainWrapper()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      physics:
          const NeverScrollableScrollPhysics(), // controlled programmatically
      children: [
        OnboardingPageOne(onNext: _goToNextPage, onSkip: _skipToLastPage),
        OnboardingPageTwo(
          onGetStarted: _getStarted,
          onJoinAsGuest: _joinAsGuest,
        ),
      ],
    );
  }
}
