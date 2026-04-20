import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/user_profile_model.dart';

abstract class ProfileRemoteDataSource {
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

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient apiClient;

  ProfileRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UserProfileModel> getProfile() async {
    final response = await apiClient.dio.get(AppConstants.userMe);
    return UserProfileModel.fromJson(response.data['data']['user']);
  }

  @override
  Future<UserProfileModel> updateProfile({String? fullName, String? country, String? phone}) async {
    final response = await apiClient.dio.put(
      AppConstants.userMe,
      data: {
        if (fullName != null) 'fullName': fullName,
        if (country != null) 'country': country,
        if (phone != null) 'phone': phone,
      },
    );
    return UserProfileModel.fromJson(response.data['data']['user']);
  }

  @override
  Future<String> updateAvatar(File imageFile) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'avatar.webp',
      ),
    });
    final response = await apiClient.dio.put(AppConstants.userAvatar, data: formData);
    return response.data['data']['avatarUrl'];
  }

  @override
  Future<UserPreferencesModel> updatePreferences({
    String? language,
    String? theme,
    String? currency,
    Map<String, bool>? notifications,
  }) async {
    final response = await apiClient.dio.put(
      AppConstants.userPreferences,
      data: {
        if (language != null) 'language': language,
        if (theme != null) 'theme': theme,
        if (currency != null) 'currency': currency,
        if (notifications != null) 'notifications': notifications,
      },
    );
    return UserPreferencesModel.fromJson(response.data['data']['preferences']);
  }

  @override
  Future<void> submitOnboarding({required String experienceLevel, String? interestedIn}) async {
    await apiClient.dio.post(
      AppConstants.userOnboarding,
      data: {
        'experienceLevel': experienceLevel,
        if (interestedIn != null) 'interestedIn': interestedIn,
      },
    );
  }

  @override
  Future<void> deleteAccount({required String password, required String reason, String? feedback}) async {
    await apiClient.dio.delete(
      AppConstants.userMe,
      data: {
        'password': password,
        'reason': reason,
        if (feedback != null) 'feedback': feedback,
      },
    );
  }

  @override
  Future<void> updateFcmToken({
    required String fcmToken,
    required String deviceType,
    required String deviceId,
    String? deviceName,
    String? appVersion,
    String? osVersion,
  }) async {
    await apiClient.dio.post(
      AppConstants.userFcmToken,
      data: {
        'fcmToken': fcmToken,
        'deviceType': deviceType,
        'deviceId': deviceId,
        if (deviceName != null) 'deviceName': deviceName,
        if (appVersion != null) 'appVersion': appVersion,
        if (osVersion != null) 'osVersion': osVersion,
      },
    );
  }
}
