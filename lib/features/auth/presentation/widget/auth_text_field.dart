import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AuthTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final bool isPassword;
  final TextEditingController controller;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final void Function(String)? onFieldSubmitted;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.isPassword = false,
    this.textInputAction = TextInputAction.next,
    this.focusNode,
    this.nextFocusNode,
    this.validator,
    this.onFieldSubmitted,
    this.keyboardType,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: widget.isPassword ? _obscureText : false,
          style: const TextStyle(color: Colors.white),
          scrollPadding: const EdgeInsets.only(bottom: 120),
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: (value) {
            if (widget.onFieldSubmitted != null) {
              widget.onFieldSubmitted!(value);
            } else if (widget.nextFocusNode != null) {
              FocusScope.of(context).requestFocus(widget.nextFocusNode);
            } else if (widget.textInputAction == TextInputAction.done) {
              FocusScope.of(context).unfocus();
            }
          },
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white38),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryPurple),
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white54,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
