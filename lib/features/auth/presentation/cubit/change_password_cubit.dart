import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_rabbit/features/auth/data/repository/auth_repository.dart';
import 'change_password_state.dart';
import 'package:green_rabbit/core/errors/failures.dart';

class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  final AuthRepository repository;

  ChangePasswordCubit({required this.repository}) : super(ChangePasswordInitial());

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    // Validation
    if (currentPassword.isEmpty || newPassword.isEmpty || confirmNewPassword.isEmpty) {
      emit(ChangePasswordError("Please fill in all fields."));
      return;
    }
    if (newPassword.length < 6) {
      emit(ChangePasswordError("New password must be at least 6 characters."));
      return;
    }
    if (newPassword != confirmNewPassword) {
      emit(ChangePasswordError("New passwords do not match."));
      return;
    }

    emit(ChangePasswordLoading());

    debugPrint('=========================================');
    debugPrint('🚀 REAL API CALL: Changing Password...');
    debugPrint('=========================================');

    try {
      await repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );
      
      if (isClosed) return;
      emit(ChangePasswordSuccess());
    } on NoInternetFailure catch (e) {
      if (isClosed) return;
      emit(ChangePasswordError(e.message, isOffline: true));
    } catch (e) {
      if (isClosed) return;
      emit(ChangePasswordError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
