import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_rabbit/core/di/injection_container.dart' as di;
import 'package:green_rabbit/features/auth/data/repository/auth_repository.dart';
import 'package:green_rabbit/features/auth/presentation/cubit/verify_otp_cubit.dart';
import 'package:green_rabbit/features/auth/presentation/cubit/verify_otp_state.dart';
import 'package:green_rabbit/features/auth/presentation/screens/login_screen.dart';
import 'package:green_rabbit/features/auth/presentation/screens/set_password_screen.dart';
import 'package:pinput/pinput.dart';
import 'package:green_rabbit/core/widgets/primary_button.dart'; // Your shared button

class VerifyOtpScreen extends StatefulWidget {
  final String
  email;
  final bool isForgotPasswordFlow; // We pass the email from the previous screen to show it in the text!

  const VerifyOtpScreen({super.key, required this.email, required this.isForgotPasswordFlow});

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
      textStyle: const TextStyle(
        fontSize: 20,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
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
      create: (context) => VerifyOtpCubit(repository: di.sl<AuthRepository>()),
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Verify your identity',
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
            child: BlocConsumer<VerifyOtpCubit, VerifyOtpState>(
              listener: (context, state) {
                if (state is VerifyOtpSuccess) {
                  // 1. Show the success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Verification Successful!'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // 2. 🔀 DYNAMIC ROUTING BASED ON THE FLOW
                  if (widget.isForgotPasswordFlow == true) {
                    // LOGIC 2: Forgot Password Flow -> Go to Set Password
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        // Make sure to pass the email so SetPasswordScreen knows WHOSE password to change!
                        builder: (context) =>
                            SetPasswordScreen(email: widget.email),
                      ),
                    );
                  } else {
                    // LOGIC 1: Signup Flow -> Go to Preferences/Onboarding
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Email verified successfully! Please log in.',
                        ),
                        backgroundColor: Colors.green,
                        duration: Duration(
                          seconds: 4,
                        ), // Leave it on screen a bit longer
                      ),
                    );

                    // 2. Wipe the stack and send them to Login
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (Route<dynamic> route) =>
                          false, // This destroys all previous screens
                    );
                  }
                } else if (state is VerifyOtpError) {
                  // Don't forget to show errors if the code is wrong!
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                return Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.center, // Centered content
                  children: [
                    const SizedBox(height: 16),
                    // Instructions Text
                    Text(
                      "We sent a 6-digit code to ${widget.email}.\nPlease enter it below to continue.",
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Resend Timer Text
                    GestureDetector(
                      onTap: _canResend
                          ? () {
                              startTimer();
                              context.read<VerifyOtpCubit>().resendCode(
                                widget.email,
                              );
                            }
                          : null,
                      child: RichText(
                        text: TextSpan(
                          text: 'Resend code in ',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: _canResend ? 'Now' : '$_start sec',
                              style: TextStyle(
                                color: _canResend
                                    ? const Color(0xFF8B5CF6)
                                    : const Color(
                                        0xFF5B8BFF,
                                      ), // Blue/Purple from design
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
                        // 👇 FIX 1: Auto-submit using strictly named parameters
                        context.read<VerifyOtpCubit>().verifyCode(
                          email: widget.email,
                          code: pin,
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Reusable Primary Button
                    PrimaryButton(
                      text: 'Confirm Code',
                      isLoading: state is VerifyOtpLoading,
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        context.read<VerifyOtpCubit>().verifyCode(
                          email: widget
                              .email, // Pass the email the user signed up with!
                          code: _pinController.text,
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
