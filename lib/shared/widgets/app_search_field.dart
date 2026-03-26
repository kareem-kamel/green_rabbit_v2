import 'package:flutter/material.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';
import 'package:green_rabbit/core/theme/app_theme.dart';

class AppSearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final TextEditingController? controller;

  const AppSearchField({
    super.key,
    this.hintText = 'Search here...',
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.searchBarBackground,
          borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.textMuted, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: readOnly
                  ? Text(
                      hintText,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    )
                  : TextField(
                      readOnly: readOnly,
                      controller: controller,
                      onChanged: onChanged,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
            ),
            const Icon(Icons.tune, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
