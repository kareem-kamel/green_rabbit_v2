import 'package:flutter/material.dart';
// Note: If you have an AppColors file for your borders, make sure it is imported here!
// import 'package:green_rabbit/core/theme/app_colors.dart';

class AuthTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;
  final bool isPassword;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.focusNode,
    this.nextFocusNode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.validator,
    this.isPassword = false,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscureText = true;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    // Listen to the focus node to know when they leave the field
    widget.focusNode?.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    // If the keyboard focus leaves this field, they are done typing.
    // Now we can safely turn on the real-time validation!
    if (widget.focusNode != null && !widget.focusNode!.hasFocus) {
      if (!_hasInteracted) {
        setState(() {
          _hasInteracted = true;
        });
      }
    }
  }

  @override
  void dispose() {
    // Always clean up listeners to prevent memory leaks
    widget.focusNode?.removeListener(_onFocusChange);
    super.dispose();
  }

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
          
          // ── The Magic Logic ──
          // Keep disabled at first, switch to real-time after they leave!
          autovalidateMode: _hasInteracted 
              ? AutovalidateMode.onUserInteraction 
              : AutovalidateMode.disabled,
              
          validator: widget.validator,
          textInputAction: widget.textInputAction,

          onFieldSubmitted: (value) {
            if (widget.onFieldSubmitted != null) {
              widget.onFieldSubmitted!(value);
            }

            if (widget.nextFocusNode != null) {
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
              borderSide: const BorderSide(color: Colors.blueAccent), // Change to AppColors.primaryPurple if you have it!
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
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