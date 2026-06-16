import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_rabbit/core/constants/app_constants.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../data/repository/auth_repository.dart';
import 'auth_state.dart';
import 'package:green_rabbit/core/errors/failures.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;

  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  AuthCubit({required this.repository}) : super(AuthInitial());

  // --------------------------------------------------
  // CHECK AUTH (APP STARTUP GATEKEEPER)
  // --------------------------------------------------

  Future<void> checkAuth() async {
    emit(AuthChecking());

    try {
      final isFirstTime = await repository.isFirstTime();

      if (isClosed) return;

      if (isFirstTime) {
        emit(AuthFirstTime());
        return;
      }

      final isLoggedIn = await repository.checkAuthStatus();

      if (isClosed) return;

      if (isLoggedIn) {
        emit(AuthSuccess());
      } else {
        emit(AuthInitial());
      }
    } catch (e) {
      debugPrint('checkAuth error: $e');
      if (isClosed) return;
      emit(AuthInitial());
    }
  }

  // --------------------------------------------------
  // LOGIN
  // --------------------------------------------------

  Future<void> login({
    required String email,
    required String password,
    required bool rememberMe,
    bool isFromSignup = false,
  }) async {
    emit(AuthLoading());

    try {
      final bool onboardingDone = await repository.login(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );

      if (isClosed) return;

      if (!onboardingDone || isFromSignup) {
        emit(AuthNeedsPreferences());
      } else {
        emit(AuthSuccess());
      }
    } on NoInternetFailure catch (e) {
      if (isClosed) return;
      emit(AuthFailure(errorMessage: e.message, isOffline: true));
    } catch (e) {
      final parsedError = e.toString().replaceAll('Exception: ', '');

      if (isClosed) return;
      emit(AuthFailure(errorMessage: parsedError));
    }
  }

  // --------------------------------------------------
  // REGISTER
  // --------------------------------------------------

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

      if (isClosed) return;
      emit(AuthNeedsVerification());
    } on NoInternetFailure catch (e) {
      if (isClosed) return;
      emit(AuthFailure(errorMessage: e.message, isOffline: true));
    } catch (e) {
      if (isClosed) return;
      emit(
        AuthFailure(errorMessage: e.toString().replaceAll('Exception: ', '')),
      );
    }
  }

  // --------------------------------------------------
  // GOOGLE SIGN IN
  // --------------------------------------------------

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());

    // Step 1: Open the native Google picker — catch SDK-level failures here.
    GoogleSignInAccount? googleUser;
    try {
      googleUser = await _googleSignIn.signIn();
    } on PlatformException catch (e) {
      // Google SDK throws PlatformException for network_error / sign_in_failed
      if (!isClosed) {
        if (e.code == 'network_error' || e.code == 'sign_in_failed') {
          emit(AuthFailure(
            errorMessage: 'No internet connection. Please try again.',
            isOffline: true,
          ));
        } else {
          emit(AuthFailure(errorMessage: e.message ?? 'Google Sign-In failed.'));
        }
      }
      return;
    } on SocketException {
      // Low-level socket error — device is offline
      if (!isClosed) {
        emit(AuthFailure(
          errorMessage: 'No internet connection. Please try again.',
          isOffline: true,
        ));
      }
      return;
    } catch (e) {
      debugPrint('Google Sign-In picker error: $e');
      if (!isClosed) {
        emit(AuthFailure(errorMessage: e.toString().replaceAll('Exception: ', '')));
      }
      return;
    }

    // User cancelled the picker
    if (googleUser == null) {
      if (!isClosed) emit(AuthInitial());
      return;
    }

    if (isClosed) return;

    // Step 2: Exchange Google token with our backend
    try {
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        if (!isClosed) {
          emit(AuthFailure(errorMessage: 'Failed to retrieve Google ID token.'));
        }
        return;
      }

      final bool onboardingDone = await repository.signInWithGoogle(idToken);

      if (isClosed) return;

      if (!onboardingDone) {
        emit(AuthNeedsPreferences());
      } else {
        emit(AuthSuccess());
      }
    } on NoInternetFailure catch (e) {
      // Backend call failed due to no connectivity
      if (!isClosed) {
        emit(AuthFailure(errorMessage: e.message, isOffline: true));
      }
    } catch (e) {
      debugPrint('Google Sign-In backend error: $e');
      if (!isClosed) {
        emit(AuthFailure(errorMessage: e.toString().replaceAll('Exception: ', '')));
      }
    }
  }

  // --------------------------------------------------
  // LOGOUT
  // --------------------------------------------------

  Future<void> logout() async {
    try {
      // Google logout
      await _googleSignIn.signOut();

      // Optional:
      // await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('Google Sign Out error: $e');
    }

    // Clear local/backend session
    await repository.logout();

    if (isClosed) return;

    // Navigate user back to Login
    emit(AuthInitial());
  }

  // --------------------------------------------------
  // CLEAR LOCAL SESSION
  // --------------------------------------------------

  Future<void> clearLocalSession() async {
    await repository.clearLocalSession();

    if (isClosed) return;

    emit(AuthInitial());
  }

  // --------------------------------------------------
  // COMPLETE ONBOARDING
  // --------------------------------------------------

  Future<void> completeOnboarding() async {
    await repository.setOnboardingComplete();

    emit(AuthInitial());
  }

  // --------------------------------------------------
  // FORGOT PASSWORD
  // --------------------------------------------------

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

  // --------------------------------------------------
  // RESET PASSWORD
  // --------------------------------------------------

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
      throw Exception(
        _getErrorMessage(e, 'Invalid OTP or error resetting password.'),
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // --------------------------------------------------
  // CHANGE PASSWORD
  // --------------------------------------------------

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
      throw Exception(
        _getErrorMessage(e, 'An error occurred while changing password.'),
      );
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // --------------------------------------------------
  // SET AUTHENTICATED MANUALLY
  // --------------------------------------------------
  void setAuthenticated({required bool onboardingDone}) {
    if (onboardingDone) {
      emit(AuthSuccess());
    } else {
      emit(AuthNeedsPreferences());
    }
  }

  // --------------------------------------------------
  // ERROR PARSER
  // --------------------------------------------------

  String _getErrorMessage(DioException e, String fallback) {
    if (e.error is AppFailure) {
      throw e.error as AppFailure;
    }
    return e.response?.data?['error']?['message'] ?? e.message ?? fallback;
  }
}
