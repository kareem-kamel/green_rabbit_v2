import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';
import 'package:green_rabbit/core/widgets/primary_button.dart';
import 'package:green_rabbit/features/auth/presentation/cubit/preferences_cubit.dart';
import 'package:green_rabbit/features/auth/presentation/widget/selectable_card.dart';

// import 'package:green_rabbit/core/widgets/primary_button.dart'; // Add your custom button import

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _interests = [
    'Crypto',
    'Stocks',
    'Forex',
    'Metals',
    'ETFs',
    'Bonds',
    'Commodities',
    'Funds',
  ];

  final List<String> _experienceLevels = ['Beginner', 'Intermediate', 'Expert'];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Provide the Cubit to this screen
    return BlocProvider(
      create: (context) => PreferencesCubit(),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg, // AppColors.scaffoldBg
        body: SafeArea(
          child: Column(
            children: [
              // --- 1. Top Bar (Skip & Progress) ---
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // TODO: Navigate to Home immediately
                      },
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Stack(
                      children: [
                        // الخلفية
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.textWhite,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        // الجزء المتقدم (Progress)
                        FractionallySizedBox(
                          widthFactor: _currentPage == 0 ? 0.5 : 1.0,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // --- 2. The Pages ---
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics:
                      const NeverScrollableScrollPhysics(), // Disables manual swiping
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [_buildInterestsPage(), _buildExperiencePage()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- PAGE 1: INTERESTS ---
  Widget _buildInterestsPage() {
    return BlocBuilder<PreferencesCubit, PreferencesState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What are you interested in?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Select The Assets You'd Like To Track To Personalize Your Experience.",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // The Grid of Interests
              Expanded(
                child: GridView.builder(
                  itemCount: _interests.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.5, // Controls the height of the buttons
                  ),
                  itemBuilder: (context, index) {
                    final interest = _interests[index];
                    final isSelected = state.selectedInterests.contains(
                      interest,
                    );
                    return SelectableCard(
                      text: interest,
                      isSelected: isSelected,
                      onTap: () => context
                          .read<PreferencesCubit>()
                          .toggleInterest(interest),
                    );
                  },
                ),
              ),

              // Continue Button
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: PrimaryButton(
                  text: 'Continue',
                  // If the list is empty, pass null to disable the button!
                  onPressed: state.selectedInterests.isEmpty ? null : _nextPage,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- PAGE 2: EXPERIENCE ---
  Widget _buildExperiencePage() {
    return BlocBuilder<PreferencesCubit, PreferencesState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "What's your experience level?",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "This Helps Our AI Tailor Market Reports To Match Your Knowledge.",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // The List of Experience Levels
              Expanded(
                child: ListView.separated(
                  itemCount: _experienceLevels.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final level = _experienceLevels[index];
                    final isSelected = state.experienceLevel == level;
                    return SelectableCard(
                      text: level,
                      isSelected: isSelected,
                      onTap: () =>
                          context.read<PreferencesCubit>().setExperience(level),
                    );
                  },
                ),
              ),

              // Finish Button
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: PrimaryButton(
                  text: 'Start Your Experience Now',
                  // If the list is empty, pass null to disable the button!
                  onPressed: state.experienceLevel.isEmpty 
                    ? null 
                    : () {
                        context.read<PreferencesCubit>().savePreferences();
                        // TODO: Navigate to Home Dashboard
                      },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
