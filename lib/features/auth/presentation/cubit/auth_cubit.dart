import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_rabbit/core/constants/app_constants.dart';
import '../../data/repository/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;

  AuthCubit({required this.repository}) : super(AuthInitial());

  // --- CHECK AUTH (THE GATEKEEPER) ---
  // Call this when the app first starts!
  Future<void> checkAuth() async {
    emit(AuthChecking()); 

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
    debugPrint('AuthCubit: Emitting AuthLoading');
    emit(AuthLoading());
    try {
      debugPrint('AuthCubit: Calling repository.login');
      await repository.login(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );
      
      debugPrint('AuthCubit: Login success, emitting AuthSuccess');
      emit(AuthSuccess());
    } catch (e) {
      final parsedError = e.toString().replaceAll('Exception: ', '');
      debugPrint('AuthCubit: Login failed, emitting AuthFailure with msg: $parsedError');
      emit(AuthFailure(errorMessage: parsedError));
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
  // --- FORGOT PASSWORD ---
  Future<void> forgotPassword(String email, dynamic apiClient) async {
    try {
      final response = await apiClient.dio.post(
        AppConstants.forgotPassword,
        data: {"email": email.trim()},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("Failed to send reset code.");
      }
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e, 'An error occurred. Try again.'));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // --- RESET PASSWORD ---
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
    required String confirmNewPassword,
    required dynamic apiClient,
  }) async {
    try {
      final response = await apiClient.dio.post(
        AppConstants.resetPassword,
        data: {
          "email": email.trim(),
          "otp": otp,
          "newPassword": newPassword,
          "confirmNewPassword": confirmNewPassword,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("Failed to reset password.");
      }
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e, 'Invalid OTP or error resetting password.'));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // --- CHANGE PASSWORD ---
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
    required dynamic apiClient,
  }) async {
    try {
      final response = await apiClient.dio.post(
        AppConstants.changePassword,
        data: {
          "currentPassword": currentPassword,
          "newPassword": newPassword,
          "confirmNewPassword": confirmNewPassword,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("Failed to change password.");
      }
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e, 'An error occurred while changing password.'));
    } catch (e) {
      throw Exception(e.toString());
    }
  }
  
  _getErrorMessage(DioException e, String s) {}
}
  