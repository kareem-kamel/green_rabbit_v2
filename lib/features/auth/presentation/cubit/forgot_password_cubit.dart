import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_rabbit/features/auth/data/repository/auth_repository.dart';
import 'forgot_password_state.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final AuthRepository repository;

  ForgotPasswordCubit({required this.repository}) : super(ForgotPasswordInitial());

  Future<void> sendResetCode(String email) async {
    // Basic validation
    if (email.trim().isEmpty) {
      emit(ForgotPasswordError("Please enter your email address"));
      return;
    }

    emit(ForgotPasswordLoading());

    debugPrint('=========================================');
    debugPrint('🚀 REAL API CALL: Sending reset code to $email');
    debugPrint('=========================================');

    try {
      await repository.forgotPassword(email);
      if (isClosed) return;
      emit(ForgotPasswordSuccess());
    } catch (e) {
      if (isClosed) return;
      emit(ForgotPasswordError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}