import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_rabbit/core/theme/app_colors.dart';
import 'package:green_rabbit/core/widgets/primary_button.dart';
import 'package:green_rabbit/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:green_rabbit/features/auth/presentation/screens/register_screen.dart';
import 'package:green_rabbit/features/auth/presentation/screens/preferences_screen.dart';
import 'package:green_rabbit/features/auth/presentation/widget/auth_text_field.dart';
import 'package:green_rabbit/shared/widgets/main_wrapper.dart';
import 'package:green_rabbit/features/auth/presentation/widget/social_login_section.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'package:green_rabbit/core/widgets/no_internet_dialog.dart';

class LoginScreen extends StatefulWidget {
  final bool isFromSignup;
  const LoginScreen({super.key, required this.isFromSignup});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. حساب أبعاد الشاشة ديناميكيًا للتعامل مع الشاشات القصيرة (مثل الكيبورد المفتوح أو الهواتف القديمة)
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final bool isShortScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            if (state.isOffline) {
              // Show the global non-dismissible No Internet dialog
              NoInternetDialog.show(context);
            } else {
              // Non-network error: show a simple SnackBar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.errorMessage,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          } else if (state is AuthSuccess || state is AuthNeedsPreferences) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Welcome!'),
                backgroundColor: Colors.green,
              ),
            );

            if (state is AuthNeedsPreferences || widget.isFromSignup) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const PreferencesScreen()),
                (route) => false,
              );
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const MainWrapper()),
                (route) => false,
              );
            }
          }
        },
        builder: (context, state) {
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: Center(
                // 2. حماية الشاشات الكبيرة (الويب والتابلت) من التمدد العرضي البشع
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 440, // العرض المثالي لكروت تسجيل الدخول عالمياً
                  ),
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: isShortScreen ? 12.0 : 24.0, // تقليل البادينج الرأسي للشاشات الصغيرة
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 3. مسافات مرنة تتكيف مع طول الشاشة
                          SizedBox(height: isShortScreen ? 20 : 40),

                          // --- 1. Header Text ---
                          Text(
                            'Welcome back!',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isShortScreen ? 28 : null, // تصغير الخط قليلاً إذا كانت الشاشة قصيرة
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please enter your details to access your dashboard.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                          ),
                          
                          SizedBox(height: isShortScreen ? 24 : 40),

                          // --- 2. Form Fields ---
                          AuthTextField(
                            label: 'Email',
                            hintText: 'Content@gmail.com',
                            controller: _emailController,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              final emailRegex = RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              );
                              if (!emailRegex.hasMatch(value.trim())) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          AuthTextField(
                            label: 'Password',
                            hintText: '********',
                            isPassword: true,
                            controller: _passwordController,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (_formKey.currentState!.validate()) {
                                context.read<AuthCubit>().login(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text.trim(),
                                  rememberMe: _rememberMe,
                                  isFromSignup: widget.isFromSignup,
                                );
                              }
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.trim().length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // --- 3. Remember Me & Forget Password ---
                          // تم تعديل هذا الصف لحمايته من الـ Overflow عند تكبير خط الهاتف من الإعدادات
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        side: const BorderSide(color: Colors.white54),
                                        activeColor: AppColors.primaryPurple,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Flexible(
                                      child: Text(
                                        'Remember me',
                                        style: TextStyle(color: Colors.white70),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8), // مسافة أمان فاصلة
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Forget password?',
                                  style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: isShortScreen ? 24 : 32),

                          // --- 4. Login Button ---
                          PrimaryButton(
                            text: 'Login',
                            isLoading: state is AuthLoading,
                            onPressed: () {
                              FocusScope.of(context).unfocus();
                              if (_formKey.currentState!.validate()) {
                                context.read<AuthCubit>().login(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text.trim(),
                                  rememberMe: _rememberMe,
                                  isFromSignup: widget.isFromSignup,
                                );
                              }
                            },
                          ),
                          
                          SizedBox(height: isShortScreen ? 24 : 40),

                          // --- 5. Social Login Section ---
                          const SocialLoginSection(text: 'Login With'),
                          
                          SizedBox(height: isShortScreen ? 32 : 48),

                          // --- 7. Sign Up Row ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account ? ",
                                style: TextStyle(color: Colors.white70),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const RegisterScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
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
}