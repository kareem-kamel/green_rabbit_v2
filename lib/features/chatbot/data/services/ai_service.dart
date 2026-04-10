import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  final String _baseUrl = "https://api.apidog.com/v1/chat"; // Replace with your actual endpoint
  final String _apiKey = "YOUR_API_KEY";

  Future<String> getAIResponse(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          "message": prompt,
          "context": "You are a professional trading assistant focused on crypto and stocks.",
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['reply'] ?? "I couldn't process that. Try again.";
      } else {
        return "Connection error. Please check your network.";
      }
    } catch (e) {
      return "Something went wrong. Error: $e";
    }
  }
}