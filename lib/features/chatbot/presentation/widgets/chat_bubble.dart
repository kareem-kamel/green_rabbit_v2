import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/app_colors.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const ChatBubble({super.key, required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryPurple : AppColors.cardBg,
          gradient: isUser ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
          boxShadow: isUser ? [
            BoxShadow(
              color: AppColors.primaryPurple.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: MarkdownBody(
          data: message,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              color: isUser ? Colors.white : Colors.white.withOpacity(0.9),
              fontSize: 15,
              height: 1.4,
            ),
            strong: TextStyle(
              color: isUser ? Colors.white : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            h1: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            h2: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            h3: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            listBullet: const TextStyle(color: Colors.white70),
          ),
        ),
      ),
    );
  }
}