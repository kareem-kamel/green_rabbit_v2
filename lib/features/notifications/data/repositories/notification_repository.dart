import 'package:green_rabbit/core/constants/app_constants.dart';
import 'package:green_rabbit/core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  String get _endpoint => AppConstants.notificationsEndpoint;

  Future<List<NotificationModel>> fetchNotifications() async {
    try {
      final response = await _apiClient.dio.get(_endpoint);

      if (response.statusCode == 200) {
        final data = response.data;
        print('--- [NOTIFICATIONS API RESPONSE] ---');
        print(data);
        if (data['success'] == true && data['data'] != null) {
          final List notificationsJson = data['data']['notifications'] ?? [];
          return notificationsJson.map((json) => NotificationModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      final response = await _apiClient.dio.put('$_endpoint/$id/read');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiClient.dio.put('$_endpoint/read-all');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNotification(String id) async {
    try {
      final response = await _apiClient.dio.delete('$_endpoint/$id');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> registerDeviceToken({
    required String fcmToken,
    required String deviceType,
    required String deviceId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        AppConstants.userFcmToken,
        data: {
          'fcmToken': fcmToken,
          'deviceType': deviceType,
          'deviceId': deviceId,
        },
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<int> fetchUnreadCount() async {
    try {
      final response = await _apiClient.dio.get('${AppConstants.notificationsEndpoint}/unread-count');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data['data']['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
