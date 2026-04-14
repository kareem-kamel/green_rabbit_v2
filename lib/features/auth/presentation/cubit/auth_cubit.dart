import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repository/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;

  AuthCubit({required this.repository}) : super(AuthInitial());

  // --- REGISTER ---
  Future<void> register({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    emit(AuthLoading());
    try {
      await repository.register(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
      
      emit(AuthSuccess());
    } catch (e) {
      // Remove 'Exception: ' from the string so the UI just shows the pure message
      emit(AuthFailure(errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  // --- LOGIN ---
  Future<void> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    emit(AuthLoading());
    debugPrint('🚀 REAL API CALL: Logging in $email');

    try {
      await repository.login(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );
      
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  // --- LOGOUT ---
  Future<void> logout() async {
    try {
      await repository.logout();
      emit(AuthInitial());
    } catch (e) {
      debugPrint("Logout Error: $e");
      // Even if deleting the token fails locally, we usually want to force the user back to the login screen
      emit(AuthInitial()); 
    }
  }
}