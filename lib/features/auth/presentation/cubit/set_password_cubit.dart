import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'set_password_state.dart';

class SetPasswordCubit extends Cubit<SetPasswordState> {
  SetPasswordCubit() : super(SetPasswordInitial());

  Future<void> changePassword(String newPassword, String confirmPassword) async {
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
    debugPrint('🚀 MOCK API CALL: Changing Password...');
    debugPrint('=========================================');

    try {
      // Fake network delay
      await Future.delayed(const Duration(seconds: 2));
      
      // 3. Success State
      emit(SetPasswordSuccess());
    } catch (e) {
      emit(SetPasswordError(e.toString()));
    }
  }
}