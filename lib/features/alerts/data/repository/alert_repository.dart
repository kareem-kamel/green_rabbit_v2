import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/alert_model.dart';

class AlertRepository {
  String get _baseUrl => dotenv.get('BASE_URL');
  String get _alertsEndpoint => dotenv.get('ALERTS_ENDPOINT');
  String get _token => dotenv.get('API_TOKEN');

  Future<List<AlertModel>> fetchAlerts() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$_alertsEndpoint'),
        headers: {
          'Authorization': 'Bearer $_token',
          'X-Pinggy-No-Screen': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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
      final response = await http.post(
        Uri.parse('$_baseUrl$_alertsEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
          'X-Pinggy-No-Screen': 'true',
        },
        body: json.encode(alert.toJson()),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
