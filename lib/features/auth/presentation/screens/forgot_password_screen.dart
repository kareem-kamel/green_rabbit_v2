import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_rabbit/core/theme/app_colors.dart'; // Adjust if needed
import 'package:green_rabbit/core/widgets/primary_button.dart'; // Your shared button
import 'package:green_rabbit/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:green_rabbit/features/auth/presentation/cubit/forgot_password_state.dart';
import 'package:green_rabbit/features/auth/presentation/screens/verify_otp_screen.dart';
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ForgotPasswordCubit(),
      child: Scaffold(
        backgroundColor: const Color(0xFF121212), // Your dark scaffold background
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Forgot Password?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          titleSpacing: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
              listener: (context, state) {
                // Handle Success
                if (state is ForgotPasswordSuccess) {
                  // 1. Show the success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Verification code sent successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // 2. Navigate to the Verify Screen and pass the email!
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VerifyOtpScreen(
                        email: _emailController.text, // 👈 Passing the email here
                      ),
                    ),
                  );
                } 
                // Handle Error
                else if (state is ForgotPasswordError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              builder: (context, state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Subtitle
                    const Text(
                      "No worries. Enter your registered email and we'll send you a secure code.",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Email Label
                    const Text(
                      'Email',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Email TextField
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Content@gmail.com',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.transparent,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF8B5CF6)), // Purple border
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Reusable Primary Button
                    PrimaryButton(
                      text: 'Send Code',
                      // Button shows loading spinner if state is Loading
                      isLoading: state is ForgotPasswordLoading, 
                      onPressed: () {
                        // Unfocus the keyboard
                        FocusScope.of(context).unfocus(); 
                        // Trigger the cubit
                        context.read<ForgotPasswordCubit>().sendResetCode(
                          _emailController.text,
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}