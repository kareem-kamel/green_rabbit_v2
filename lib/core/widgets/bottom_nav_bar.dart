import 'package:flutter/material.dart';
import '../theme/app_colors.dart' as core_colors;

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onItemTapped;
  final List<_BottomNavItem> items;
  final double fabGapWidth;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.items,
    this.fabGapWidth = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: core_colors.AppColors.navBarBg,
        border: Border(
          top: BorderSide(color: core_colors.AppColors.textWhite.withOpacity(0.06), width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _buildChildren(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildChildren() {
    final List<Widget> children = [];
    for (int i = 0; i < items.length; i++) {
      // Insert a gap in the middle to make room for the FAB if requested
      if (fabGapWidth > 0 && i == (items.length / 2).floor()) {
        children.add(SizedBox(width: fabGapWidth));
      }
      children.add(_buildNavItem(items[i], i));
    }
    return children;
  }

  Widget _buildNavItem(_BottomNavItem item, int index) {
    final bool isActive = selectedIndex == index;
    return GestureDetector(
      onTap: () => onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.icon != null) ...[
            Icon(
              item.icon!,
              color: isActive ? core_colors.AppColors.textWhite : core_colors.AppColors.textGrey,
              size: 24,
            ),
            const SizedBox(height: 4),
          ] else if (item.assetPath != null) ...[
            SizedBox(
              width: 20,
              height: 20,
              child: Image.asset(
                item.assetPath!,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            item.label,
            style: TextStyle(
              color: isActive ? core_colors.AppColors.textWhite : core_colors.AppColors.textGrey,
              fontSize: 10,
              fontFamily: 'Urbanist',
              fontWeight: FontWeight.w500,
              letterSpacing: -0.41,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem {
  final IconData? icon;
  final String? assetPath;
  final String label;
  const _BottomNavItem(this.icon, this.label) : assetPath = null;
  const _BottomNavItem.asset(this.assetPath, this.label) : icon = null;
}

// Helper to keep API ergonomic for callers
List<_BottomNavItem> buildBottomNavItems(List<(IconData, String)> tuples) {
  return tuples.map((t) => _BottomNavItem(t.$1, t.$2)).toList(growable: false);
}

List<_BottomNavItem> buildBottomNavLabels(List<String> labels) {
  return labels.map((l) => _BottomNavItem(null, l)).toList(growable: false);
}

List<_BottomNavItem> buildBottomNavAssets(List<(String, String)> tuples) {
  return tuples.map((t) => _BottomNavItem.asset(t.$1, t.$2)).toList(growable: false);
}
