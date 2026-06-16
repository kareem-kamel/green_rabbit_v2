import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:green_rabbit/core/constants/app_constants.dart';
import 'package:green_rabbit/core/network/api_client.dart';
import 'package:green_rabbit/core/errors/failures.dart';

class AuthRepository {
  final ApiClient apiClient;
  final FlutterSecureStorage storage;

  AuthRepository({required this.apiClient, required this.storage});

  // Helper method to extract detailed error messages from JSON payload
  String _extractMessageFromData(dynamic data, String defaultMessage) {
    if (data is Map) {
      if (data['error'] is Map) {
        // Try to get specific field validation detail first
        if (data['error']['details'] is Map &&
            data['error']['details'].isNotEmpty) {
          return data['error']['details'].values.first.toString();
        }
        if (data['error']['message'] != null) {
          return data['error']['message'].toString();
        }
      }
      if (data['message'] != null) {
        return data['message'].toString();
      }
    } else if (data is String && data.isNotEmpty) {
      // Sometimes backend returns raw error text
      return data.length > 100 ? defaultMessage : data;
    }
    return defaultMessage;
  }

  // Helper method to safely extract error message from DioException
  String _getErrorMessage(DioException e, String defaultMessage) {
    if (e.error is AppFailure) {
      throw e.error as AppFailure;
    }
    try {
      return _extractMessageFromData(e.response?.data, defaultMessage);
    } catch (_) {}
    return defaultMessage;
  }

  // Helper method to check if the response was technically a 200 OK but had "success": false
  void _checkResponseSuccess(Response response, String defaultError) {
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(defaultError);
    }
    if (response.data is Map && response.data['success'] == false) {
      throw Exception(_extractMessageFromData(response.data, defaultError));
    }
  }

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

  Future<void> saveUserOnboarding({
    required String experienceLevel,
    required List<String> interestedIn,
  }) async {
    try {
      final response = await apiClient.dio.post(
        AppConstants.userOnboarding,
        data: {
          "experienceLevel":
              experienceLevel, // Backend expects exactly "Beginner", "Intermediate", or "Expert"
          "interestedIn": interestedIn.join(
            ',',
          ), // Backend expects a comma-separated string, NOT a JSON Array
        },
      );

      _checkResponseSuccess(response, "Failed to save preferences.");

      // Also mark local storage as complete
      await setOnboardingComplete();
    } on DioException catch (e) {
      debugPrint('🚨 ONBOARDING 400 ERROR RAW DATA: ${e.response?.data}');
      throw Exception(_getErrorMessage(e, 'Failed to save preferences.'));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // --- REGISTER ---
  Future<void> register({
    required String email,
    required String password,
    required String confirmPassword,
    String? fullName,
    String? phone,
    String? country,
    // Placeholder until we add a full name field in the UI
  }) async {
    try {
      final response = await apiClient.dio.post(
        AppConstants.register,
        data: {
          "fullName": fullName ?? "New User", 
          "email": email.trim(),
          "password": password,
          "passwordConfirm": confirmPassword,
          "country": country ?? "US", 
          "phone": phone ?? "0000000000",
          "acceptTerms": true,
          "acceptPrivacy": true,
        },
      );

      _checkResponseSuccess(response, "Registration failed.");
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(e, 'An error occurred during registration.'),
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // --- VERIFY OTP ---
  Future<bool> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    try {
      final response = await apiClient.dio.post(
        AppConstants.verifyEmail,
        data: {"email": email, "otp": code},
      );

      _checkResponseSuccess(response, "Invalid code. Please try again.");

      final responseData = response.data is Map
          ? (response.data['data'] ?? response.data)
          : null;

      if (responseData is Map &&
          (responseData['accessToken'] != null ||
              responseData['token'] != null)) {
        final accessToken =
            responseData['accessToken'] ?? responseData['token'];
        final refreshToken =
            responseData['refreshToken'] ?? responseData['refresh_token'];

        // Save Token
        await storage.write(
          key: AppConstants.keyAccessToken,
          value: accessToken,
        );

        // Save Remember Me choice
        await storage.write(key: 'rememberMe', value: 'true');

        if (refreshToken != null) {
          await storage.write(
            key: AppConstants.keyRefreshToken,
            value: refreshToken,
          );
        }

        // Check if onboarding is done
        bool onboardingDone = false;
        if (responseData['user'] != null && responseData['user']['onboardingDone'] != null) {
          onboardingDone = responseData['user']['onboardingDone'] == true;
        } else if (responseData['user'] != null && responseData['user']['status'] == 'pending_onboarding') {
          onboardingDone = false;
        } else if (responseData['onboardingDone'] != null) {
          onboardingDone = responseData['onboardingDone'] == true;
        }

        return onboardingDone;
      }
      return false;
    } on DioException catch (e) {
      throw Exception(_getErrorMessage(e, 'Invalid code. Try again.'));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // --- LOGIN ---
  Future<bool> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      debugPrint('AuthRepository: Attempting login...');
      final response = await apiClient.dio.post(
        AppConstants.login,
        data: {"email": email.trim(), "password": password},
      );
      debugPrint('AuthRepository: Login request successful');

      _checkResponseSuccess(
        response,
        "Login successful, but an error occurred.",
      );

      debugPrint('AuthRepository: Full Response Data: ${response.data}');
      final responseData = response.data is Map
          ? (response.data['data'] ?? response.data)
          : null;
      debugPrint('AuthRepository: Extracted responseData: $responseData');

      if (responseData is Map &&
          (responseData['accessToken'] != null ||
              responseData['token'] != null)) {
        final accessToken =
            responseData['accessToken'] ?? responseData['token'];
        final refreshToken =
            responseData['refreshToken'] ?? responseData['refresh_token'];

        // Save Token
        await storage.write(
          key: AppConstants.keyAccessToken,
          value: accessToken,
        );

        // Save Remember Me choice
        await storage.write(key: 'rememberMe', value: rememberMe.toString());

        if (refreshToken != null) {
          await storage.write(
            key: AppConstants.keyRefreshToken,
            value: refreshToken,
          );
        }

        // Mark onboarding as complete once they successfully log in
        await setOnboardingComplete();
        debugPrint('AuthRepository: Login completed');

        // Check if onboarding is done
        bool onboardingDone = false;
        if (responseData['user'] != null && responseData['user']['onboardingDone'] != null) {
           onboardingDone = responseData['user']['onboardingDone'] == true;
        } else if (responseData['user'] != null && responseData['user']['status'] == 'pending_onboarding') {
           onboardingDone = false;
        } else if (responseData['onboardingDone'] != null) {
           onboardingDone = responseData['onboardingDone'] == true;
        }

        return onboardingDone;
      } else {
        debugPrint(
          'AuthRepository: Failed to find token in responseData: $responseData',
        );
        throw Exception(
          "Login successful, but no access token was found in the response.",
        );
      }
    } on DioException catch (e) {
      debugPrint(
        'AuthRepository: DioException caught! Parsing error message...',
      );
      final msg = _getErrorMessage(e, 'Invalid email or password.');
      debugPrint('AuthRepository: Parsed error message: $msg');
      throw Exception(msg);
    } catch (e) {
      debugPrint('AuthRepository: Generic exception caught: $e');
      throw Exception(e.toString());
    }
  }

  // --- GOOGLE SIGN IN ---
  Future<bool> signInWithGoogle(String idToken) async {
    try {
      debugPrint('AuthRepository: Attempting Google Login...');
      final response = await apiClient.dio.post(
        AppConstants.signInWithGoogle,
        data: {"idToken": idToken, "rememberMe": true},
      );
      debugPrint('AuthRepository: Google Login request successful');
      print('AuthRepository: Full Response Data: ${response.data}');

      _checkResponseSuccess(response, "Google sign in failed.");

      final responseData = response.data is Map
          ? (response.data['data'] ?? response.data)
          : null;

      if (responseData is Map &&
          (responseData['accessToken'] != null ||
              responseData['token'] != null)) {
        final accessToken =
            responseData['accessToken'] ?? responseData['token'];
        final refreshToken =
            responseData['refreshToken'] ?? responseData['refresh_token'];

        // Save Token
        await storage.write(
          key: AppConstants.keyAccessToken,
          value: accessToken,
        );
        await storage.write(key: 'rememberMe', value: 'true');

        if (refreshToken != null) {
          await storage.write(
            key: AppConstants.keyRefreshToken,
            value: refreshToken,
          );
        }

        await setOnboardingComplete();
        debugPrint('AuthRepository: Google Login completed');

        // Check if onboarding is done
        bool onboardingDone = false;
        if (responseData['user'] != null && responseData['user']['onboardingDone'] != null) {
           onboardingDone = responseData['user']['onboardingDone'] == true;
        } else if (responseData['user'] != null && responseData['user']['status'] == 'pending_onboarding') {
           onboardingDone = false;
        } else if (responseData['onboardingDone'] != null) {
           onboardingDone = responseData['onboardingDone'] == true;
        }

        return onboardingDone;
      } else {
        throw Exception(
          "No access token was found in the Google login response.",
        );
      }
    } on DioException catch (e) {
      final msg = _getErrorMessage(e, 'Google sign in failed.');
      throw Exception(msg);
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
      final refreshToken = await storage.read(
        key: AppConstants.keyRefreshToken,
      );

      if (refreshToken != null) {
        await apiClient.dio.post(
          AppConstants.logout,
          data: {"refreshToken": refreshToken},
        );
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      await clearLocalSession();
    }
  }

  // --- CLEAR LOCAL SESSION (No API Call) ---
  Future<void> clearLocalSession() async {
    // Wipe sensitive data, but KEEP 'isFirstTime' so they don't see Onboarding again
    await storage.delete(key: AppConstants.keyAccessToken);
    await storage.delete(key: AppConstants.keyRefreshToken);
    await storage.delete(key: 'rememberMe');
  }

  // --- FORGOT PASSWORD ---
  Future<void> forgotPassword(String email) async {
    try {
      final response = await apiClient.dio.post(
        AppConstants.forgotPassword,
        data: {"email": email.trim()},
      );

      _checkResponseSuccess(response, "Failed to send reset code.");
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

      _checkResponseSuccess(response, "Failed to reset password.");
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(e, 'Invalid OTP or error resetting password.'),
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // --- CHANGE PASSWORD ---
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmNewPassword,
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

      _checkResponseSuccess(response, "Failed to change password.");
    } on DioException catch (e) {
      throw Exception(
        _getErrorMessage(e, 'An error occurred while changing password.'),
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
