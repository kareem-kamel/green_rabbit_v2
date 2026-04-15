import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/alert_model.dart';

class AlertRepository {
  String get _baseUrl => dotenv.get('BASE_URL');
  String get _alertsEndpoint => dotenv.get('ALERTS_ENDPOINT');
  String get _token => 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI4N2Y3MDI4MC0wNWQzLTQwOTAtOTRmZS00MjVjNGIyOGY5Y2UiLCJlbWFpbCI6ImFobWVkNDExMTQ0QGdtYWlsLmNvbSIsInRpZXIiOiJmcmVlIiwibGFuZyI6ImVuIiwidHYiOjEsImlhdCI6MTc3NjIxMDYzMSwiZXhwIjoxNzc2MjE0MjMxfQ.2Ad77By0DH_1FEvBcJZBBE8O';

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
