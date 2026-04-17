import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../widgets/profile_list_item.dart';
import '../../../subscriptions/presentation/cubit/subscription_cubit.dart';
import '../../../subscriptions/presentation/cubit/subscription_state.dart';
import '../../../subscriptions/presentation/widgets/trial_status_banner.dart';
import '../../../subscriptions/data/models/subscription_model.dart';
import '../cubit/profile_cubit.dart';
import 'subscription_screen.dart';
import 'settings_screen.dart';
import 'edit_profile_screen.dart';
import 'about_screen.dart';
import '../widgets/rating_bottom_sheet.dart';
import '../../../alerts/presentation/pages/alerts_page.dart';
import 'help_center_screen.dart';




class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.settings_outlined, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54, size: 20),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double horizontalPadding = constraints.maxWidth > 900 
              ? (constraints.maxWidth - 800) / 2 
              : 20.0;

          return BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, profileState) {
              return BlocBuilder<SubscriptionCubit, SubscriptionState>(
                builder: (context, state) {
                  SubscriptionModel? currentSub;
                  if (state is SubscriptionLoaded) {
                    currentSub = state.currentSubscription;
                  }

                  final bool isTrialActive = currentSub != null && currentSub.status == 'active' && currentSub.isTrial;

                  return SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 800),
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
                                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.surface : Colors.black,
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
                                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.surface : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 35,
                                          backgroundImage: NetworkImage(profileState.avatarUrl),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    profileState.name,
                                                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                                                  ),
                                                  GestureDetector(
                                                    onTap: () {
                                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                                                    },
                                                    child: Icon(Icons.edit_outlined, color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.6) : Colors.black45, size: 18),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                profileState.email,
                                                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54, fontSize: 13),
                                              ),
                                              const SizedBox(height: 8),
                                              if (currentSub != null && currentSub.status == 'active')
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Image.asset('assets/crown_gold.png', width: 14, height: 14, fit: BoxFit.contain),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          '${currentSub.planName} Account',
                                                          style: const TextStyle(color: AppColors.premiumGold, fontSize: 13, fontWeight: FontWeight.w600),
                                                        ),
                                                      ],
                                                    ),
                                                    GestureDetector(
                                                      onTap: () {
                                                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                                                      },
                                                      child: const Text(
                                                        'View Details',
                                                        style: TextStyle(color: AppColors.premiumGold, fontSize: 13, fontWeight: FontWeight.w500),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              else
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(Icons.lock_outline, color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.4) : Colors.black26, size: 14),
                                                        const SizedBox(width: 4),
                                                        const Text(
                                                          'Limited AI access',
                                                          style: TextStyle(color: AppColors.textGrey, fontSize: 12),
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
                                    if (currentSub != null && currentSub.status == 'active') ...[
                                      const SizedBox(height: 20),
                                      Divider(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.black.withOpacity(0.05), height: 1),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildStat(context, '101', 'Posts'),
                                          _buildStat(context, '2', 'Followers'),
                                          _buildStat(context, '5', 'Following'),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              const SizedBox(height: 32),

                              // --- Account Section ---
                              _buildSectionHeader(context, 'Account'),

                              ProfileListItem(
                                assetPath: 'assets/crown_gray.png',
                                title: 'Premium membership',
                                trailing: (currentSub != null && currentSub.status == 'active')
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF16A34A).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.5)),
                                        ),
                                        child: const Text(
                                          'Active',
                                          style: TextStyle(color: Color(0xFF4ADE80), fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      )
                                    : ElevatedButton(
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
                                icon: Icons.notifications_active_outlined,
                                title: 'Price Alerts',
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsPage()));
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
                              _buildSectionHeader(context, 'Settings'),

                              ProfileListItem(
                                icon: Icons.settings_outlined,
                                title: 'Settings & Notification',
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                                },
                              ),

                              const SizedBox(height: 24),

                              // --- Support Section ---
                              _buildSectionHeader(context, 'Support'),

                              ProfileListItem(
                                icon: Icons.help_outline,
                                title: 'Help center',
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen()));
                                },
                              ),

                              const SizedBox(height: 12),
                              ProfileListItem(
                                icon: Icons.star_border,
                                title: 'Rate us',
                                onTap: () => RatingBottomSheet.show(context),
                              ),
                              const SizedBox(height: 12),
                              ProfileListItem(
                                icon: Icons.info_outline,
                                title: 'About',
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
                                },
                              ),

                              const SizedBox(height: 40),

                              // --- Log Out Button ---
                              InkWell(
                                onTap: () => _showLogoutBottomSheet(context),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark ? AppColors.surface : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Theme.of(context).dividerColor),
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
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.black38, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87, fontSize: 18, fontWeight: FontWeight.normal),
      ),
    );
  }
  
  void _showLogoutBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0E1117) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout, color: Colors.redAccent, size: 32),
              ),
              const SizedBox(height: 24),
              Text(
                'Logging Out',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to log out from your account?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<AuthCubit>().logout();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Log Out', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

