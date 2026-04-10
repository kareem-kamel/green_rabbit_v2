import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'forgot_password_state.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit() : super(ForgotPasswordInitial());

  Future<void> sendResetCode(String email) async {
    // Basic validation
    if (email.trim().isEmpty) {
      emit(ForgotPasswordError("Please enter your email address"));
      return;
    }

    // Tell the UI to show the loading spinner in your PrimaryButton
    emit(ForgotPasswordLoading());

    debugPrint('=========================================');
    debugPrint('🚀 MOCK API CALL: Sending reset code to $email');
    debugPrint('=========================================');

    try {
      // Fake network delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Tell the UI it worked!
      emit(ForgotPasswordSuccess());
    } catch (e) {
      emit(ForgotPasswordError(e.toString()));
    }
  }
}