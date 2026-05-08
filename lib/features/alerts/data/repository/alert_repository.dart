import 'package:green_rabbit/core/constants/app_constants.dart';
import 'package:green_rabbit/core/network/api_client.dart';
import '../models/alert_model.dart';

class AlertRepository {
  final ApiClient _apiClient;

  AlertRepository(this._apiClient);

  String get _alertsEndpoint => AppConstants.alertsEndpoint;

  Future<List<AlertModel>> fetchAlerts() async {
    try {
      final response = await _apiClient.dio.get(_alertsEndpoint);

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

  Future<bool> createAlert(AlertModel alert) async {
    try {
      final response = await _apiClient.dio.post(
        _alertsEndpoint,
        data: alert.toJson(),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

