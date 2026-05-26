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
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _fullNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();

  String _selectedCountry = 'Egypt';
  final List<String> _countries = [
    'Egypt',
    'Saudi Arabia',
    'UAE',
    'Qatar',
    'Kuwait',
    'Bahrain',
    'Oman',
    'USA',
    'UK',
    'Canada',
  ];

  // ScrollController to programmatically scroll to focused field
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Email → scroll just enough to show all 3 fields + button above keyboard
    _fullNameFocus.addListener(_onFocusChange);
    _emailFocus.addListener(_onFocusChange);
    _phoneFocus.addListener(_onFocusChange);
    // Password / Confirm → scroll to bottom so button stays visible
    _passwordFocus.addListener(_onFocusChange);
    _confirmFocus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_fullNameFocus.hasFocus ||
        _emailFocus.hasFocus ||
        _phoneFocus.hasFocus ||
        _passwordFocus.hasFocus ||
        _confirmFocus.hasFocus) {
      _scrollToShowForm();
    }
  }

  /// All fields scroll to the same offset — hides the header and
  /// reveals all fields + Sign Up button above the keyboard.
  void _scrollToShowForm() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        120, // pushes header out, shows fields + button
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // ── Key fix: read viewInsets here so the scaffold reacts to keyboard ──
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      // ✅ IMPORTANT: false so we manually handle padding via viewInsets
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.scaffoldBg,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthNeedsVerification) {
            // 1. Optional: Show a quick success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please verify your email.'),
                backgroundColor: Colors.green,
              ),
            );

            // 2. 🚀 NAVIGATE TO OTP SCREEN
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VerifyOtpScreen(
                  email:
                      _emailController.text, // Pass the email they just typed!
                  isForgotPasswordFlow:
                      false, // 👇 Make sure this is FALSE for Signup!
                ),
              ),
            );
          } else if (state is AuthFailure) {
            // Show error message if backend rejects the signup
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
              // ✅ This is the core fix:
              // When keyboard appears, bottom padding grows → content scrolls up
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                top: topPadding,
                bottom: keyboardHeight > 0
                    ? keyboardHeight // keyboard is open
                    : bottomPadding, // keyboard is closed (safe area)
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),

                      // ── 1. Header ──────────────────────────────────────
                      Text(
                        'Create your account',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
                      const SizedBox(height: 32),

                      // ── 1. Full Name Field ─────────────────────────────
                      AuthTextField(
                        label: 'Full Name',
                        hintText: 'John Doe',
                        controller: _fullNameController,
                        focusNode: _fullNameFocus,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_emailFocus),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // ── 2. Email Field ─────────────────────────────────
                      AuthTextField(
                        label: 'Email',
                        hintText: 'Content@gmail.com',
                        controller: _emailController,
                        focusNode: _emailFocus,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_phoneFocus),
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
                      const SizedBox(height: 20),

                      // ── 3. Phone Field ─────────────────────────────────
                      AuthTextField(
                        label: 'Phone Number',
                        hintText: '+1 234 567 890',
                        controller: _phoneController,
                        focusNode: _phoneFocus,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_passwordFocus),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // ── 4. Country Selection ────────────────────────────
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Country',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCountry,
                                isExpanded: true,
                                dropdownColor: const Color(0xFF1A1D21),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white54,
                                ),
                                items: _countries.map((String country) {
                                  return DropdownMenuItem<String>(
                                    value: country,
                                    child: Text(country),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedCountry = newValue;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── 5. Password Field ──────────────────────────────
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
                          if (!value.contains(RegExp(r'[A-Z]'))) {
                            return 'Must contain at least one uppercase letter';
                          }
                          if (!value.contains(RegExp(r'[0-9]'))) {
                            return 'Must contain at least one number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // ── 6. Confirm Password Field ──────────────────────
                      AuthTextField(
                        label: 'Confirm Password',
                        hintText: '********',
                        isPassword: true,
                        controller: _confirmPasswordController,
                        focusNode: _confirmFocus,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) =>
                            FocusScope.of(context).unfocus(),
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
                      const SizedBox(height: 32),

                      // ── 7. Sign Up Button ──────────────────────────────
                      PrimaryButton(
                        text: 'Sign Up',
                        isLoading: state is AuthLoading,
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            FocusScope.of(context).unfocus();

                            // Map country name to 2-letter ISO code
                            final countryCodes = {
                              'Egypt': 'EG',
                              'Saudi Arabia': 'SA',
                              'UAE': 'AE',
                              'Qatar': 'QA',
                              'Kuwait': 'KW',
                              'Bahrain': 'BH',
                              'Oman': 'OM',
                              'USA': 'US',
                              'UK': 'GB',
                              'Canada': 'CA',
                            };

                            context.read<AuthCubit>().register(
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                              confirmPassword: _confirmPasswordController.text
                                  .trim(),
                              fullName: _fullNameController.text.trim(),
                              phone: _phoneController.text.trim(),
                              country: countryCodes[_selectedCountry] ?? 'EG',
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 40),

                      // ── 6. Social Login Section ──────────────────────────
                      const SocialLoginSection(text: 'Sign up With'),
                      const SizedBox(height: 40),

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
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// REUSABLE SOCIAL BUTTON
// ─────────────────────────────────────────────
