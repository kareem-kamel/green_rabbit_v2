import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_rabbit/features/auth/data/repository/auth_repository.dart';
import 'verify_otp_state.dart';
// Import your repository!


class VerifyOtpCubit extends Cubit<VerifyOtpState> {
  final AuthRepository repository; // Inject the real repository

  VerifyOtpCubit({required this.repository}) : super(VerifyOtpInitial());

  // 👇 Now it takes BOTH email and code
  Future<void> verifyCode( {required String email, required String code}) async {
    if (code.length < 6) {
      emit(VerifyOtpError("Please enter the complete 6-digit code."));
      return;
    }

    emit(VerifyOtpLoading());

    debugPrint('=========================================');
    debugPrint('🚀 REAL API CALL: Verifying code $code for $email');
    debugPrint('=========================================');

    try {
      // Call the real backend
      await repository.verifyEmailCode(email: email, code: code);
      
      // If it doesn't crash, it was a success!
      emit(VerifyOtpSuccess());
    } catch (e) {
      // Clean up the error message
      emit(VerifyOtpError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // You can link your resendCode function to the repository later!
  Future<void> resendCode(String email) async {
    debugPrint('🚀 API CALL: Resending code to $email');
    // await repository.resendOtp(email: email);
  }
}