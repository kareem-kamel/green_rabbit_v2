import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../widgets/profile_list_item.dart';
import '../../../subscriptions/presentation/cubit/subscription_cubit.dart';
import '../../../subscriptions/presentation/cubit/subscription_state.dart';
import '../../../subscriptions/presentation/widgets/trial_status_banner.dart';
import '../../../subscriptions/data/models/subscription_model.dart';
import 'subscription_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.settings_outlined, color: Colors.white70, size: 20),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocBuilder<SubscriptionCubit, SubscriptionState>(
        builder: (context, state) {
          SubscriptionModel? currentSub;
          if (state is SubscriptionLoaded) {
            currentSub = state.currentSubscription;
          }

          final bool isTrialActive = currentSub != null && currentSub.status == 'active' && currentSub.isTrial;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isTrialActive) ...[
                  const SizedBox(height: 10),
                  TrialStatusBanner(
                    daysLeft: currentSub.daysRemaining,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                    },
                  ),
                ],
                const SizedBox(height: 10),
                
                // --- Green Rabbit Banner ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Image.asset('assets/crown_gold.png', width: 24, height: 24, fit: BoxFit.contain),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Green Rabbit',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.premiumGold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Get 50% off', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // --- User Info Card ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 35,
                            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=mahmoud'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Mahmoud Ali',
                                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    Icon(Icons.edit_outlined, color: Colors.white.withOpacity(0.6), size: 18),
                                  ],
                                ),
                                const Text(
                                  'mahmoudali@gmail.com',
                                  style: TextStyle(color: Colors.white54, fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.4), size: 14),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Limited AI access',
                                          style: TextStyle(color: Colors.white38, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                                      },
                                      child: const Text(
                                        'Get Pro',
                                        style: TextStyle(color: AppColors.premiumGold, fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // --- Account Section ---
                _buildSectionHeader('Account'),
                ProfileListItem(
                  assetPath: 'assets/crown_gray.png',
                  title: 'Premium membership',
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.premiumGold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/crown_black.png', width: 14, height: 14, fit: BoxFit.contain),
                        const SizedBox(width: 4),
                        const Text('Get Premium', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                  },
                ),
                const SizedBox(height: 12),
                ProfileListItem(
                  icon: Icons.payment,
                  title: 'Payment & Billing',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                  },
                ),
                
                const SizedBox(height: 24),
                
                // --- Settings Section ---
                _buildSectionHeader('Settings'),
                ProfileListItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings & Notification',
                  onTap: () {},
                ),
                
                const SizedBox(height: 24),
                
                // --- Support Section ---
                _buildSectionHeader('Support'),
                ProfileListItem(
                  icon: Icons.help_outline,
                  title: 'Help center',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                ProfileListItem(
                  icon: Icons.star_border,
                  title: 'Rate us',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                ProfileListItem(
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () {},
                ),
                
                const SizedBox(height: 40),
                
                // --- Log Out Button ---
                InkWell(
                  onTap: () {
                    context.read<AuthCubit>().logout();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.logout, color: Colors.redAccent, size: 24),
                        SizedBox(width: 16),
                        Text(
                          'Log Out',
                          style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.normal),
      ),
    );
  }
}
