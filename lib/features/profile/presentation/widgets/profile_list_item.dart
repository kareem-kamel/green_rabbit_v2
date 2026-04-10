import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ProfileListItem extends StatelessWidget {
  final IconData? icon;
  final String? assetPath;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;
  final Color? iconColor;

  const ProfileListItem({
    super.key,
    this.icon,
    this.assetPath,
    required this.title,
    required this.onTap,
    this.trailing,
    this.iconColor,
  }) : assert(icon != null || assetPath != null);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? AppColors.surface : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceLight.withOpacity(0.5) : Colors.white70,
                shape: BoxShape.circle,
              ),
              child: assetPath != null
                  ? Image.asset(
                      assetPath!,
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                    )
                  : Icon(
                      icon!,
                      color: iconColor ?? (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
                      size: 20,
                    ),
            ),
            const SizedBox(width: 16),
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
              trailing!
            else
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black26,
                size: 20,
              ),

          ],
        ),
      ),
    );
  }
}
