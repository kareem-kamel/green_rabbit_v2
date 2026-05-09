import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/profile_repository_impl.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository repository;

  ProfileCubit({required this.repository}) : super(ProfileInitial());

  Future<void> getProfile() async {
    emit(ProfileLoading());
    try {
      final user = await repository.getProfile();
      emit(ProfileLoaded(user));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> updateProfile({String? fullName, String? country, String? phone}) async {
    try {
      final user = await repository.updateProfile(
        fullName: fullName,
        country: country,
        phone: phone,
      );
      emit(ProfileLoaded(user));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> updateAvatar(File imageFile) async {
    try {
      await repository.updateAvatar(imageFile);
      // Refresh profile to get new avatar URL
      await getProfile();
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> updatePreferences({
    String? language,
    String? theme,
    String? currency,
    Map<String, bool>? notifications,
  }) async {
    try {
      await repository.updatePreferences(
        language: language,
        theme: theme,
        currency: currency,
        notifications: notifications,
      );
      // Refresh profile to get updated preferences
      await getProfile();
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> submitOnboarding({required String experienceLevel, String? interestedIn}) async {
    emit(ProfileLoading());
    try {
      await repository.submitOnboarding(
        experienceLevel: experienceLevel,
        interestedIn: interestedIn,
      );
      await getProfile();
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> deleteAccount({required String password, required String reason, String? feedback}) async {
    emit(ProfileLoading());
    try {
      await repository.deleteAccount(
        password: password,
        reason: reason,
        feedback: feedback,
      );
      // Since the user is logged out after deletion, the app should handle navigation to Login
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> updateFcmToken({
    required String fcmToken,
    required String deviceType,
    required String deviceId,
    String? deviceName,
    String? appVersion,
    String? osVersion,
  }) async {
    try {
      await repository.updateFcmToken(
        fcmToken: fcmToken,
        deviceType: deviceType,
        deviceId: deviceId,
        deviceName: deviceName,
        appVersion: appVersion,
        osVersion: osVersion,
      );
    } catch (e) {
      // FCM errors are usually silent to avoid interrupting user experience
      print('FCM Token Update Error: $e');
    }
  }
}
