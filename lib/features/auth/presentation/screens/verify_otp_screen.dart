import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_rabbit/features/auth/presentation/cubit/verify_otp_cubit.dart';
import 'package:green_rabbit/features/auth/presentation/cubit/verify_otp_state.dart';
import 'package:green_rabbit/features/auth/presentation/screens/set_password_screen.dart';
import 'package:pinput/pinput.dart';
import 'package:green_rabbit/core/widgets/primary_button.dart'; // Your shared button


class VerifyOtpScreen extends StatefulWidget {
  final String email; // We pass the email from the previous screen to show it in the text!

  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final TextEditingController _pinController = TextEditingController();
  
  // Timer variables
  Timer? _timer;
  int _start = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    setState(() {
      _start = 30;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_start == 0) {
        setState(() {
          timer.cancel();
          _canResend = true;
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Styling the Pinput boxes to match your design
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 56,
      textStyle: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: const Color(0xFF8B5CF6)), // Your purple color
    );

    return BlocProvider(
      create: (context) => VerifyOtpCubit(),
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Verify your identity',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          centerTitle: false,
          titleSpacing: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: BlocConsumer<VerifyOtpCubit, VerifyOtpState>(
              listener: (context, state) {
                if (state is VerifyOtpSuccess) {
                  // 1. Optional: Show a quick success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Verification Successful!'), 
                      backgroundColor: Colors.green,
                    ),
                  );

                  // 2. Navigate to the Set Password Screen!
                  // We use pushReplacement so the user can't accidentally 
                  // swipe back to the OTP screen once they are verified.
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SetPasswordScreen(), 
                    ),
                  );
                } 
                // Handle the case where they typed the wrong code
                else if (state is VerifyOtpError) {
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
                  crossAxisAlignment: CrossAxisAlignment.center, // Centered content
                  children: [
                    const SizedBox(height: 16),
                    // Instructions Text
                    Text(
                      "We sent a 6-digit code to ${widget.email}.\nPlease enter it below to continue.",
                      textAlign: TextAlign.left,
                      style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 40),

                    // Resend Timer Text
                    GestureDetector(
                      onTap: _canResend ? () {
                        startTimer();
                        context.read<VerifyOtpCubit>().resendCode(widget.email);
                      } : null,
                      child: RichText(
                        text: TextSpan(
                          text: 'Resend code in ',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                          children: [
                            TextSpan(
                              text: _canResend ? 'Now' : '$_start sec',
                              style: TextStyle(
                                color: _canResend ? const Color(0xFF8B5CF6) : const Color(0xFF5B8BFF), // Blue/Purple from design
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 6-Digit Pinput
                    Pinput(
                      length: 6,
                      controller: _pinController,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      cursor: Container(
                        width: 2,
                        height: 24,
                        color: const Color(0xFF8B5CF6),
                      ),
                      onCompleted: (pin) {
                        // Auto-submit when the 6th digit is typed!
                        context.read<VerifyOtpCubit>().verifyCode(pin);
                      },
                    ),
                    
                    const SizedBox(height: 40),

                    // Reusable Primary Button
                    PrimaryButton(
                      text: 'Confirm Code',
                      isLoading: state is VerifyOtpLoading,
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        context.read<VerifyOtpCubit>().verifyCode(_pinController.text);
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