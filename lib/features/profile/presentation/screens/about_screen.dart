import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
          'About',
          style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Logo
            Center(
              child: Image.asset(
                'assets/about_logo.png',
                height: 200,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Our application leverages advanced AI algorithms to provide real-time financial insights and market analysis. We are committed to empowering investors with data-driven tools that simplify complex trading patterns and enhance decision-making. Experience the future of finance, where technology meets clarity.',
              textAlign: TextAlign.start,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Platform bridges the gap between advanced AI technology and community-driven insights. We empower investors to navigate complex markets with confidence by providing real-time data analysis, predictive trends, and a collaborative space for financial growth. Experience a smarter way to track, learn, and excel in your financial journey.',
              textAlign: TextAlign.start,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
