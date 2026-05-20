import 'package:green_rabbit/core/constants/app_constants.dart';
import 'package:green_rabbit/core/network/api_client.dart';
import '../models/alert_model.dart';

class AlertRepository {
  final ApiClient _apiClient;

  AlertRepository(this._apiClient);

  String get _alertsEndpoint => AppConstants.alertsEndpoint;

  Future<List<AlertModel>> fetchAlerts() async {
    try {
      final response = await _apiClient.dio.get(
        _alertsEndpoint,
        queryParameters: {
          'status': 'all',
          'page': 1,
          'limit': 50,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          final List alertsJson = data['data']['alerts'] ?? [];
          return alertsJson.map((json) => AlertModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch alerts: $e');
    }
  }

  Future<AlertModel?> createAlert(Map<String, dynamic> alertData) async {
    try {
      final response = await _apiClient.dio.post(
        _alertsEndpoint,
        data: alertData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null && data['data']['alert'] != null) {
          return AlertModel.fromJson(data['data']['alert']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteAlert(String alertId) async {
    try {
      final response = await _apiClient.dio.delete(
        '$_alertsEndpoint/$alertId',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

