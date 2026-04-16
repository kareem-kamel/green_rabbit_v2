import 'dart:io';
import '../models/user_profile_model.dart';
import '../sources/profile_remote_data_source.dart';

abstract class ProfileRepository {
  Future<UserProfileModel> getProfile();
  Future<UserProfileModel> updateProfile({String? fullName, String? country, String? phone});
  Future<String> updateAvatar(File imageFile);
  Future<UserPreferencesModel> updatePreferences({
    String? language,
    String? theme,
    String? currency,
    Map<String, bool>? notifications,
  });
  Future<void> submitOnboarding({required String experienceLevel, String? interestedIn});
  Future<void> deleteAccount({required String password, required String reason, String? feedback});
  Future<void> updateFcmToken({
    required String fcmToken,
    required String deviceType,
    required String deviceId,
    String? deviceName,
    String? appVersion,
    String? osVersion,
  });
}

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserProfileModel> getProfile() {
    return remoteDataSource.getProfile();
  }

  @override
  Future<UserProfileModel> updateProfile({String? fullName, String? country, String? phone}) {
    return remoteDataSource.updateProfile(fullName: fullName, country: country, phone: phone);
  }

  @override
  Future<String> updateAvatar(File imageFile) {
    return remoteDataSource.updateAvatar(imageFile);
  }

  @override
  Future<UserPreferencesModel> updatePreferences({
    String? language,
    String? theme,
    String? currency,
    Map<String, bool>? notifications,
  }) {
    return remoteDataSource.updatePreferences(
      language: language,
      theme: theme,
      currency: currency,
      notifications: notifications,
    );
  }

  @override
  Future<void> submitOnboarding({required String experienceLevel, String? interestedIn}) {
    return remoteDataSource.submitOnboarding(experienceLevel: experienceLevel, interestedIn: interestedIn);
  }

  @override
  Future<void> deleteAccount({required String password, required String reason, String? feedback}) {
    return remoteDataSource.deleteAccount(password: password, reason: reason, feedback: feedback);
  }

  @override
  Future<void> updateFcmToken({
    required String fcmToken,
    required String deviceType,
    required String deviceId,
    String? deviceName,
    String? appVersion,
    String? osVersion,
  }) {
    return remoteDataSource.updateFcmToken(
      fcmToken: fcmToken,
      deviceType: deviceType,
      deviceId: deviceId,
      deviceName: deviceName,
      appVersion: appVersion,
      osVersion: osVersion,
    );
  }
}
