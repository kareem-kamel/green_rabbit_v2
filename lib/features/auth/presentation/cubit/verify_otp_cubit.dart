import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'verify_otp_state.dart';

class VerifyOtpCubit extends Cubit<VerifyOtpState> {
  VerifyOtpCubit() : super(VerifyOtpInitial());

  Future<void> verifyCode(String code) async {
    // Check if the user filled all 6 boxes
    if (code.length < 6) {
      emit(VerifyOtpError("Please enter the complete 6-digit code."));
      return;
    }

    emit(VerifyOtpLoading());

    debugPrint('=========================================');
    debugPrint('🚀 MOCK API CALL: Verifying code: $code');
    debugPrint('=========================================');

    try {
      await Future.delayed(const Duration(seconds: 2)); // Fake network delay
      
      // Mock validation: Only 123456 works for our test
      if (code == "123456") {
        emit(VerifyOtpSuccess());
      } else {
        emit(VerifyOtpError("Invalid code. Try 123456 for testing."));
      }
    } catch (e) {
      emit(VerifyOtpError(e.toString()));
    }
  }

  // Mock function for the Resend button
  Future<void> resendCode(String email) async {
    debugPrint('🚀 MOCK API CALL: Resending code to $email');
    // You could emit a state here to show a "Code Resent!" snackbar if you want
  }
}