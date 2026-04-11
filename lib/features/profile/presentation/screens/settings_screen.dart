import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

import 'currency_selection_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import '../widgets/rating_bottom_sheet.dart';



import '../cubit/settings_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsScreen extends StatefulWidget {

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Settings',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                
                // --- Green Rabbit Banner ---
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? AppColors.surface : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                       Image.asset(
                        'assets/crown_gold.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Green Rabbit',
                          style: TextStyle(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFB800), Color(0xFFFF8A00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Get 50% off',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                _buildSectionHeader('App preferences'),
                _buildSettingsGroup(context, [
                  _buildSettingsTile(
                    context,
                    icon: Icons.attach_money,
                    title: 'Default currency (${state.currency})',
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CurrencySelectionScreen(currentCurrency: state.currency),
                        ),
                      );
                      if (result != null && result is String) {
                        context.read<SettingsCubit>().setCurrency(result);
                      }
                    },
                  ),
    
                  _buildSettingsTile(
                    context,
                    icon: Icons.notifications_none_outlined,
                    title: 'Notification',
                    trailing: _buildSwitch(
                      state.notificationsEnabled,
                      (val) => context.read<SettingsCubit>().toggleNotifications(val),
                    ),
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.wb_sunny_outlined,
                    title: 'Light mode',
                    trailing: _buildSwitch(
                      state.lightModeEnabled,
                      (val) => context.read<SettingsCubit>().toggleLightMode(val),
                    ),
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.laptop_windows_outlined, 
                    title: 'Prevent screen awake',
                    trailing: _buildSwitch(
                      state.preventScreenAwake,
                      (val) => context.read<SettingsCubit>().togglePreventScreenAwake(val),
                    ),
                  ),
                ]),
                
                const SizedBox(height: 24),
                _buildSectionHeader('AI Preferences'),
                _buildSettingsGroup(context, [
                  _buildSettingsTile(
                    context,
                    icon: Icons.notifications_active_outlined, 
                    title: 'AI Alerts Frequency',
                    trailing: Text(
                      state.alertFrequency.split('(')[0].trim(),
                      style: const TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                    onTap: () => _showAlertFrequencyBottomSheet(context, state.alertFrequency),
                  ),
                ]),
    
                const SizedBox(height: 24),
                _buildSectionHeader('Security'),
                _buildSettingsGroup(context, [
                  _buildSettingsTile(
                    context,
                    icon: Icons.lock_outline,
                    title: 'App lock',
                    trailing: _buildSwitch(
                      state.appLockEnabled,
                      (val) => context.read<SettingsCubit>().toggleAppLock(val),
                    ),
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.key_outlined,
                    title: 'Remember password',
                    trailing: _buildSwitch(
                      state.rememberPassword,
                      (val) => context.read<SettingsCubit>().toggleRememberPassword(val),
                    ),
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.shield_outlined,
                    title: 'Privacy policy',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
                    },
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.description_outlined,
                    title: 'Terms of sevices',
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()));
                    },
                  ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.star_border,
                    title: 'Rate us',
                    onTap: () => RatingBottomSheet.show(context),
                  ),
                ]),
                const SizedBox(height: 48),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.surface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          int idx = entry.key;
          Widget child = entry.value;
          if (idx == children.length - 1) return child;
          return Column(
            children: [
              child,
              Padding(
                padding: const EdgeInsets.only(left: 52),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.6) : Colors.black54, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (trailing != null)
                trailing
              else
                Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black26,
                  size: 14,
                ),
            ],
          ),
        ),
      ),
    );
  }


  void _showAlertFrequencyBottomSheet(BuildContext context, String currentAlertFrequency) {
    final options = ['Instant (Real-time)', 'Digest (Daily)', 'Important only'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F111A) : Colors.white,
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
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('AI Alerts Frequency', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('Choose how often you want our AI to notify you about market opportunities.', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54, fontSize: 13)),
                  const SizedBox(height: 24),
                  ...options.map((opt) {
                    final isSelected = currentAlertFrequency == opt;
                    return InkWell(
                      onTap: () {
                        context.read<SettingsCubit>().setAlertFrequency(opt);
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1B1E2B) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? const Color(0xFF4C3BC9) : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05))),
                        ),
                        child: Row(
                          children: [
                            Text(opt, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 15)),
                            const Spacer(),
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: isSelected ? const Color(0xFF4C3BC9) : (Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black26),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildSwitch(bool value, ValueChanged<bool> onChanged) {
    return Transform.scale(
      scale: 0.8,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: const Color(0xFF4C3BC9), // specific indigo/blue from theme
        inactiveThumbColor: Colors.white70,
        inactiveTrackColor: Colors.white.withOpacity(0.1),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
