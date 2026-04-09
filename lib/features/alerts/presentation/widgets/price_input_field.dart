import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PriceInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const PriceInputField({
    super.key, 
    required this.controller, 
    required this.label
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          cursorColor: AppColors.primaryPurple,
          decoration: InputDecoration(
            prefixText: "\$ ",
            prefixStyle: const TextStyle(color: AppColors.primaryPurple, fontSize: 24),
            filled: true,
            fillColor: AppColors.cardBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primaryPurple, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}