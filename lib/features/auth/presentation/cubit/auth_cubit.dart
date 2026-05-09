import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repository/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;

  AuthCubit({required this.repository}) : super(AuthInitial());

  // --- CHECK AUTH (THE GATEKEEPER) ---
  // Call this when the app first starts!
  Future<void> checkAuth() async {
    emit(AuthLoading()); 

    try {
      // 1. Check if it's the first install/opening
      final isFirstTime = await repository.isFirstTime();
      if (isFirstTime) {
        emit(AuthFirstTime()); // Show Onboarding
        return;
      }

      // 2. If not first time, check if they are already logged in
      final isLoggedIn = await repository.checkAuthStatus();
      
      if (isLoggedIn) {
        emit(AuthSuccess()); // Go to Dashboard
      } else {
        emit(AuthInitial()); // Go to Login
      }
    } catch (e) {
      // If something crashes during the check, default to Login
      emit(AuthInitial());
    }
  }

  // --- LOGIN ---
  Future<void> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    emit(AuthLoading());
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
      
      // Usually, after register, you show the OTP screen or Success state
      emit(AuthSuccess()); 
    } catch (e) {
      emit(AuthFailure(errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  // --- LOGOUT ---
  Future<void> logout() async {
    await repository.logout();
    
    // After logout, we go to AuthInitial (Login), NOT AuthFirstTime (Onboarding)
    emit(AuthInitial()); 
  }

  // --- COMPLETE ONBOARDING ---
  // Call this when the user clicks "Get Started" on your Onboarding screen
  Future<void> completeOnboarding() async {
    await repository.setOnboardingComplete();
    emit(AuthInitial()); // Move them to the Login screen
  }
}