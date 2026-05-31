import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // 1. Import url_launcher

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  // 2. Helper method to open URLs and Email
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: isDark ? Colors.white : Colors.black, size: 20),
          // Replaced onPressed with onTap for consistency or kept onPressed
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help center',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        // 3. Search icon removed from here
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              "Don't hesitate to contact us whether you have a suggestion on our improvement, a complain to discuss or an issue to solve.",
              style: TextStyle(
                color: isDark ? Colors.white.withOpacity(0.7) : Colors.black87,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                // 4. Added URLs to each card. Note the "mailto:" for the email!
                _buildSocialCard(
                  context,
                  'X',
                  'assets/x.png',
                  Icons.close,
                  'https://x.com/GreenRabbitAi',
                ),
                _buildSocialCard(
                  context,
                  'Email',
                  'assets/gmail.png',
                  Icons.email_outlined,
                  'mailto:info@greenrabbit.ai', // "mailto:" triggers the email app
                ),
                _buildSocialCard(
                  context,
                  'Instagram',
                  'assets/instagram.png',
                  Icons.camera_alt_outlined,
                  'https://www.instagram.com/greenrabbitai/',
                ),
                _buildSocialCard(
                  context,
                  'Facebook',
                  'assets/facebook.png',
                  Icons.facebook,
                  'https://www.facebook.com/people/Green-Rabbit-Ai/61590006963552/',
                ),
              ],
            ),
            // 5. Form and Send Message button removed from here
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 6. Added "url" parameter and wrapped in an InkWell for tapping
  Widget _buildSocialCard(BuildContext context, String title, String assetPath,
      IconData fallbackIcon, String url) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchURL(url), // Trigger the launch URL function
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B1E2B) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildSocialIcon(assetPath, fallbackIcon),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon(String assetPath, IconData fallbackIcon) {
    return Image.asset(
      assetPath,
      width: 32,
      height: 32,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          Icon(fallbackIcon, size: 24, color: Colors.white),
    );
  }
}