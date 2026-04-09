import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Privacy Policy',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: January 2026',
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black45, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Data Collection',
              'We collect information you provide directly to us, such as your name, email, and financial preferences, to personalize your experience.',
            ),
            _buildSection(
              context,
              'AI Processing',
              'Our AI algorithms analyze your market interactions locally and securely to provide tailored insights without sharing your personal identity with third parties.',
            ),
            _buildSection(
              context,
              'Security',
              'We implement industry-standard encryption (AES-256) to protect your data from unauthorized access or disclosure.',
            ),
            _buildSection(
              context,
              'Third-Party Services',
              'We do not sell your personal data. We only share anonymized data with trusted service providers to improve our app performance.',
            ),
            _buildSection(
              context,
              'Your Rights',
              'You have the right to access, update, or delete your personal information at any time through your account settings.',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('• ', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 20)),
              ),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87, fontSize: 16, height: 1.5),
                    children: [
                      TextSpan(
                        text: '$title: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: content),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
