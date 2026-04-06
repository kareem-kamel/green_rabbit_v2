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
          color: Theme.of(context).brightness == Brightness.dark ? AppColors.searchBarBackground : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.textMuted, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: readOnly
                  ? Text(
                      hintText,
                      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textMuted : Colors.black38, fontSize: 13),
                    )
                  : TextField(
                      readOnly: readOnly,
                      controller: controller,
                      onChanged: onChanged,
                      style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.textMuted : Colors.black38),
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
