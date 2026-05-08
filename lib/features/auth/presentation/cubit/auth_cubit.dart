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

  // Call this when the app first starts!
  Future<void> checkAuth() async {
    emit(AuthLoading()); // Show splash screen or spinner
    
    try {
      final isLoggedIn = await repository.checkAuthStatus();
      
      if (isLoggedIn) {
        // User has a token and wanted to be remembered!
        emit(AuthSuccess()); 
      } else {
        // No token, or "Remember Me" was false
        emit(AuthInitial()); 
      }
    } catch (e) {
      emit(AuthInitial());
    }
  }

  // --- LOGOUT ---
  Future<void> logout() async {
    // 1. Call the repository to do the heavy lifting
    await repository.logout();
    
    // 2. Tell the app the user is gone!
    // Because your main.dart is listening to this Cubit, emitting AuthInitial 
    // will instantly snap the app back to the Onboarding/Login screen!
    emit(AuthInitial()); 
  }
}