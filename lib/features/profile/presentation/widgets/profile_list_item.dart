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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withOpacity(0.5),
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
                      color: iconColor ?? Colors.white70,
                      size: 20,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (trailing != null)
              trailing!
            else
              const Icon(
                Icons.chevron_right,
                color: Colors.white24,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
