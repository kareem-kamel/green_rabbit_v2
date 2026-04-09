import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart'; // 👈 1. Import the new SVG package

class SocialButton extends StatelessWidget {
  // We make these optional so you can provide one OR the other
  final FaIconData? icon; 
  final String? svgPath; // 👈 2. Add a path for the SVG image
  final double size;      // Rename iconSize to just size for consistency
  final VoidCallback onTap;
  final Color? iconColor; // Allow custom colors for icons (default to white)

  const SocialButton({
    super.key,
    this.icon,
    this.svgPath, // Receive the SVG path here
    required this.size,
    required this.onTap,
    this.iconColor = Colors.white, // Default single-color icons to white
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        width: 50,
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E), // Your dark background circle
          shape: BoxShape.circle,
        ),
        child: Center(
          // 👈 3. THE SMART LOGIC 👈
          child: svgPath != null
              ? // A. If an SVG path was provided, use SvgPicture
                SvgPicture.asset(
                  svgPath!,
                  height: size, // Keep the image crisp at the right size
                  width: size,
                  // NOTE: Do NOT apply a 'color' here, or it will override
                  // the Google colors and turn the whole logo solid!
                )
              : // B. Otherwise, fall back to the FontAwesome Icon
                FaIcon(
                  icon ?? FontAwesomeIcons.question, // Fallback icon if both null
                  color: iconColor,
                  size: size,
                ),
        ),
      ),
    );
  }
}