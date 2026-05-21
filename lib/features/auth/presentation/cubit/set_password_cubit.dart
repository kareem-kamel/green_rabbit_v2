import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_rabbit/features/auth/data/repository/auth_repository.dart';
import 'set_password_state.dart';

class SetPasswordCubit extends Cubit<SetPasswordState> {
  final AuthRepository repository;

  SetPasswordCubit({required this.repository}) : super(SetPasswordInitial());

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmPassword,
  }) async {
    // 1. Validation
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      emit(SetPasswordError("Please fill in both fields."));
      return;
    }
    if (newPassword.length < 6) {
      emit(SetPasswordError("Password must be at least 6 characters."));
      return;
    }
    if (newPassword != confirmPassword) {
      emit(SetPasswordError("Passwords do not match."));
      return;
    }

    // 2. Loading State
    emit(SetPasswordLoading());

    debugPrint('=========================================');
    debugPrint('🚀 REAL API CALL: Resetting Password...');
    debugPrint('=========================================');

    try {
      await repository.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
        confirmNewPassword: confirmPassword,
      );
      
      // 3. Success State
      emit(SetPasswordSuccess());
    } catch (e) {
      emit(SetPasswordError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}