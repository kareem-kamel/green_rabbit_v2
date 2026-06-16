import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';
import 'package:green_rabbit/core/widgets/primary_button.dart';
import 'package:green_rabbit/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:green_rabbit/features/auth/presentation/widget/social_login_section.dart';
import '../widget/auth_text_field.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_onFieldFocus);
    _passwordFocus.addListener(_onFieldFocus);
    _confirmFocus.addListener(_onFieldFocus);
  }

  /// Responsive programmatic scrolling: Instead of a hardcoded 120px offset, 
  /// we dynamically calculate how much to scroll based on device screen height.
  void _onFieldFocus() {
    final currentFocus = FocusScope.of(context).focusedChild;
    if (currentFocus == null || !currentFocus.hasFocus) return;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_scrollController.hasClients) return;
      
      final screenHeight = MediaQuery.of(context).size.height;
      // Scroll more aggressively on smaller screens, gently on larger screens
      double scrollOffset = screenHeight < 700 ? 140.0 : 90.0;

      _scrollController.animateTo(
        scrollOffset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocus.removeListener(_onFieldFocus);
    _passwordFocus.removeListener(_onFieldFocus);
    _confirmFocus.removeListener(_onFieldFocus);
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;
    
    // Adaptive responsive parameters
    final isShortScreen = screenHeight < 700;
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.scaffoldBg,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthNeedsVerification) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please verify your email.'),
                backgroundColor: Colors.green,
              ),
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VerifyOtpScreen(
                  email: _emailController.text,
                  isForgotPasswordFlow: false,
                ),
              ),
            );
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                top: topPadding,
                bottom: keyboardHeight > 0 ? keyboardHeight : bottomPadding,
              ),
              // Center layout horizontally to enforce perfect look on Tablets/Desktops
              child: Center(
                child: ConstrainedBox(
                  // Restricts card scaling width on massive screens
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: isShortScreen ? 16 : 32),

                          // ── 1. Header ──────────────────────────────────────
                          Text(
                            'Create your account',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isShortScreen ? 28 : 32, // Adaptive typography
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Powerful market insights are just a few steps away.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                  height: 1.5,
                                ),
                          ),
                          
                          SizedBox(height: isShortScreen ? 20 : 32),

                          // ── 2. Email Field ─────────────────────────────────
                          AuthTextField(
                            label: 'Email',
                            hintText: 'Content@gmail.com',
                            controller: _emailController,
                            focusNode: _emailFocus,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).requestFocus(_passwordFocus),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              final emailRegex = RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              );
                              if (!emailRegex.hasMatch(value)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // ── 3. Password Field ──────────────────────────────
                          AuthTextField(
                            label: 'Password',
                            hintText: '********',
                            isPassword: true,
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            nextFocusNode: _confirmFocus,
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).requestFocus(_confirmFocus),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 8) {
                                return 'Must be at least 8 characters';
                              }
                              if (!value.contains(RegExp(r'[A-Z]')) ||
                                  !value.contains(RegExp(r'[a-z]'))) {
                                return 'Must contain uppercase and lowercase';
                              }
                              if (!value.contains(RegExp(r'[0-9]'))) {
                                return 'Must contain at least one number';
                              }
                              return null;
                            },
                          ),

                          _buildPasswordRules(),
                          const SizedBox(height: 16),

                          // ── 4. Confirm Password Field ──────────────────────
                          AuthTextField(
                            label: 'Confirm Password',
                            hintText: '********',
                            isPassword: true,
                            controller: _confirmPasswordController,
                            focusNode: _confirmFocus,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          
                          SizedBox(height: isShortScreen ? 24 : 32),

                          // ── 5. Sign Up Button ──────────────────────────────
                          PrimaryButton(
                            text: 'Sign Up',
                            isLoading: state is AuthLoading,
                            onPressed: () {
                              FocusScope.of(context).unfocus();

                              if (_formKey.currentState!.validate()) {
                                context.read<AuthCubit>().register(
                                      email: _emailController.text.trim(),
                                      password: _passwordController.text.trim(),
                                      confirmPassword:
                                          _confirmPasswordController.text.trim(),
                                    );
                              }
                            },
                          ),
                          
                          SizedBox(height: isShortScreen ? 24 : 40),

                          // ── 6. Social Login Section ──────────────────────────
                          const SocialLoginSection(text: 'Sign up With'),
                          
                          SizedBox(height: isShortScreen ? 24 : 40),

                          // ── 8. Have an account? ────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Have an account? ',
                                style: TextStyle(color: Colors.white70),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── HELPER METHODS FOR PASSWORD RULES ───────────────────────────────

  Widget _buildPasswordRules() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _passwordController,
      builder: (context, value, child) {
        final password = value.text;

        final hasMinLength = password.length >= 8;
        final hasUpperAndLower = password.contains(RegExp(r'[A-Z]')) &&
            password.contains(RegExp(r'[a-z]'));
        final hasNumber = password.contains(RegExp(r'[0-9]'));

        return Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRuleRow('Must be at least 8 characters', hasMinLength),
              const SizedBox(height: 6),
              _buildRuleRow(
                'Must contain at least one uppercase and lowercase letter',
                hasUpperAndLower,
              ),
              const SizedBox(height: 6),
              _buildRuleRow('Must contain at least one number', hasNumber),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRuleRow(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.cancel,
          color: isMet ? Colors.green : Colors.white38,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded( // Prevents long text from cutting or overflowing horizontally
          child: Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.green : Colors.white38,
              fontSize: 12,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}