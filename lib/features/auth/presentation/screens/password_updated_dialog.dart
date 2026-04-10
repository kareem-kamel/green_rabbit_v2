import 'package:flutter/material.dart';
import 'package:green_rabbit/core/widgets/primary_button.dart';
import 'package:green_rabbit/features/auth/presentation/screens/login_screen.dart'; // Adjust path to your PrimaryButton

class PasswordUpdatedDialog extends StatelessWidget {
  const PasswordUpdatedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF16161E), // Dark card background from your design
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24), // Rounded corners
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Wrap content so it doesn't take the whole screen
          children: [
            // 1. Green Verified Checkmark
            const Icon(
              Icons.verified, 
              color: Color(0xFF22C55E), // Vibrant green color
              size: 80,
            ),
            const SizedBox(height: 24),
            
            // 2. Title
            const Text(
              'Password updated',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // 3. Subtitle
            const Text(
              'Your password has been successfully\nchanged. You can now securely access\nyour account.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            // 4. Reusable Primary Button
            PrimaryButton(
              text: 'Start Exploring Now',
              onPressed: () {
                // Here you clear the entire navigation history and take them to Login or Home!
                // Example:
                Navigator.pushAndRemoveUntil(
                  context, 
                  MaterialPageRoute(builder: (context) => const LoginScreen()), 
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}