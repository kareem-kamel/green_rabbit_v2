import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:green_rabbit/core/constants/app_constants.dart';
import 'package:green_rabbit/core/network/api_client.dart';
// Adjust path based on your folder structure

class AuthRepository {
  final ApiClient apiClient;
  final FlutterSecureStorage storage;

  AuthRepository({required this.apiClient, required this.storage});

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
          "fullName": "kareem kamel",
          "email": email.trim(),
          "password": password,
          "passwordConfirm": confirmPassword,
          "country": "AE",
          "phone": "+971501234567",
          "acceptTerms": true,
          "acceptPrivacy":
              true, // Make sure this matches your backend's exact key!
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception("Registration failed.");
      }
    } on DioException catch (e) {
      // Extract the exact error message the backend team sends (e.g., "Email already in use")
      final errorMessage =
          e.response?.data['message'] ??
          'An error occurred during registration.';
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
        AppConstants
            .verifyEmail, // You will need to add this to AppConstants! (e.g., '/api/auth/verify-email')
        data: {"email": email, "otp": code},
      );

      // If the API returns a success message, we are good!
      if (response.data['success'] != true) {
        throw Exception("Invalid code. Please try again.");
      }
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data['message'] ?? 'Invalid code. Try again.';
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

      // Grab the 'data' object from the response
      final responseData = response.data['data'];

      if (responseData != null && responseData['accessToken'] != null) {
        final accessToken = responseData['accessToken'];
        final refreshToken =
            responseData['refreshToken']; // Good to grab this now!
        final userStatus =
            responseData['user']['status']; // e.g., "pending_onboarding"

        // Save the tokens securely!
        await storage.write(
          key: AppConstants.keyAccessToken,
          value: accessToken,
        );
        await storage.write(key: 'rememberMe', value: rememberMe.toString());

        if (refreshToken != null) {
          await storage.write(
            key: AppConstants.keyRefreshToken,
            value: refreshToken,
          );
        }

        // Optional: Save user status to storage so your app knows where to route them on startup
        if (userStatus != null) {
          await storage.write(
            key: AppConstants.keyUserStatus,
            value: userStatus,
          );
        }
      } else {
        throw Exception("Login successful, but no access token was found.");
      }
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data['message'] ?? 'Invalid email or password.';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // --- CHECK AUTH STATUS ---
  Future<bool> checkAuthStatus() async {
    // 1. Did the user check "Remember Me"?
    final rememberMeStr = await storage.read(key: 'rememberMe');

    // If they explicitly unchecked it, we don't remember them on next app start.
    if (rememberMeStr == 'false') {
      await storage.delete(key: AppConstants.keyAccessToken);
      return false;
    }

    // 2. Check if the token exists
    final token = await storage.read(key: AppConstants.keyAccessToken);
    return token != null; // Returns true if logged in, false if not
  }

  // --- LOGOUT ---
  Future<void> logout() async {
    try {
      // Clear all secure storage (tokens, user status, etc.)
      await storage.deleteAll();
      // Optional: If your backend has a /logout endpoint to invalidate the token, call it here:
      // await apiClient.dio.post('/auth/logout');
    } catch (e) {
      throw Exception("Failed to logout securely.");
    }
  }
}
