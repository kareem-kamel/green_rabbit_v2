import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:green_rabbit/core/constants/app_constants.dart';
import 'package:green_rabbit/core/network/api_client.dart';

class AuthRepository {
  final ApiClient apiClient;
  final FlutterSecureStorage storage;

  AuthRepository({required this.apiClient, required this.storage});

  // --- NEW: ONBOARDING HELPERS ---
  
  /// Marks that the user has seen the onboarding slides
  Future<void> setOnboardingComplete() async {
    await storage.write(key: 'isFirstTime', value: 'false');
  }

  /// Checks if this is the very first time the app is being opened
  Future<bool> isFirstTime() async {
    final value = await storage.read(key: 'isFirstTime');
    return value == null; // If null, they haven't finished onboarding yet
  }

  // --- REGISTER ---
  Future<void> register({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await apiClient.dio.post(
        AppConstants.register,
        data: {
          "fullName": "User Name", // Consider passing this as a parameter later
          "email": email.trim(),
          "password": password,
          "passwordConfirm": confirmPassword,
          "country": "AE",
          "phone": "+971501234567",
          "acceptTerms": true,
          "acceptPrivacy": true,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("Registration failed.");
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'An error occurred during registration.';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // --- VERIFY OTP ---
  Future<void> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await apiClient.dio.post(
        AppConstants.verifyEmail, 
        data: {"email": email, "otp": code},
      );

      if (response.data['success'] != true) {
        throw Exception("Invalid code. Please try again.");
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Invalid code. Try again.';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // --- LOGIN ---
  Future<void> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      final response = await apiClient.dio.post(
        AppConstants.login,
        data: {"email": email.trim(), "password": password},
      );

      final responseData = response.data['data'];

      if (responseData != null && responseData['accessToken'] != null) {
        final accessToken = responseData['accessToken'];
        final refreshToken = responseData['refreshToken'];

        // Save Token
        await storage.write(key: AppConstants.keyAccessToken, value: accessToken);
        
        // Save Remember Me choice
        await storage.write(key: 'rememberMe', value: rememberMe.toString());

        if (refreshToken != null) {
          await storage.write(key: AppConstants.keyRefreshToken, value: refreshToken);
        }
        
        // Mark onboarding as complete once they successfully log in
        await setOnboardingComplete();
        
      } else {
        throw Exception("Login successful, but no access token was found.");
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Invalid email or password.';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // --- CHECK AUTH STATUS ---
  Future<bool> checkAuthStatus() async {
    final rememberMeStr = await storage.read(key: 'rememberMe');
    final token = await storage.read(key: AppConstants.keyAccessToken);

    // If they didn't want to be remembered, wipe the token and return false
    if (rememberMeStr != 'true') {
      await storage.delete(key: AppConstants.keyAccessToken);
      return false;
    }

    return token != null && token.isNotEmpty;
  }

  // --- LOGOUT ---
  Future<void> logout() async {
    try {
      final refreshToken = await storage.read(key: AppConstants.keyRefreshToken); 

      if (refreshToken != null) {
        await apiClient.dio.post(
          '/api/auth/logout', 
          data: {"refreshToken": refreshToken},
        );
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      // Wipe sensitive data, but KEEP 'isFirstTime' so they don't see Onboarding again
      await storage.delete(key: AppConstants.keyAccessToken);
      await storage.delete(key: AppConstants.keyRefreshToken); 
      await storage.delete(key: 'rememberMe');
    }
  }
}