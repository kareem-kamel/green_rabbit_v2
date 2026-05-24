import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'social_auth.dart';
import '../cubit/auth_cubit.dart';

class SocialLoginSection extends StatelessWidget {
  final String text; // e.g. "Login With" or "Sign up With"

  const SocialLoginSection({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- 1. Divider Row ---
        Row(
          children: [
            const Expanded(
              child: Divider(color: Colors.white24, thickness: 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
            const Expanded(
              child: Divider(color: Colors.white24, thickness: 1),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // --- 2. Social Media Buttons ---
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SocialButton(
              svgPath: 'assets/icons/google_icon.svg',
              size: 24,
              onTap: () {
                context.read<AuthCubit>().signInWithGoogle();
              },
            ),
            const SizedBox(width: 24),
            SocialButton(
              icon: FontAwesomeIcons.apple,
              size: 28,
              onTap: () {
                // TODO: Apple sign in
              },
            ),
          ],
        ),
      ],
    );
  }
}
