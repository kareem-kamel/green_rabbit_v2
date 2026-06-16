
import 'package:flutter/material.dart';
import 'package:green_rabbit/features/auth/presentation/widget/auth_text_field.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

// Used when app first starts to check auth status
class AuthChecking extends AuthState {}

// Used when a login/register request is actively processing
class AuthLoading extends AuthState {}

class AuthFirstTime extends AuthState {}

// Emitted when a user has registered but needs to verify their email
class AuthNeedsVerification extends AuthState {}

// Emitted when a user has logged in successfully, but needs to complete the Preferences flow
class AuthNeedsPreferences extends AuthState {}

class AuthSuccess extends AuthState {
  // final UserModel user;
  // AuthSuccess({required this.user});
}



class AuthFailure extends AuthState {
  final String errorMessage;
  final bool isOffline;
  AuthFailure({required this.errorMessage, this.isOffline = false});
}
class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscureText = true;
  bool _hasInteracted = false;
  
  // 1. Add a backup FocusNode
  late FocusNode _effectiveFocusNode;

  @override
  void initState() {
    super.initState();
    // 2. If the parent (like Login) doesn't pass a focus node, we create one automatically!
    _effectiveFocusNode = widget.focusNode ?? FocusNode();
    _effectiveFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_effectiveFocusNode.hasFocus) {
      if (!_hasInteracted) {
        setState(() {
          _hasInteracted = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChange);
    // 3. Only safely dispose it if we were the ones who created it
    if (widget.focusNode == null) {
      _effectiveFocusNode.dispose();
    }
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
          
          // 4. Important: Use the effective focus node here!
          focusNode: _effectiveFocusNode, 
          
          obscureText: widget.isPassword ? _obscureText : false,
          style: const TextStyle(color: Colors.white),
          scrollPadding: const EdgeInsets.only(bottom: 120),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white38),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blueAccent), 
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
                      _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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