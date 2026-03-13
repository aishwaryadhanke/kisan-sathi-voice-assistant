// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

/// ✅ Change this to your laptop's Wi-Fi IPv4 address
/// Example: http://10.112.44.247:8000
/// Make sure backend is running with: uvicorn app.main:app --host 0.0.0.0 --port 8000
const String backendBaseUrl = 'http://10.151.220.247:8000';


class ApiService {
  final http.Client _client = http.Client();

  /// 🔹 Text-only query (uses /voice-query-text)
  Future<Map<String, dynamic>> sendTextQuery(String text) async {
    final uri = Uri.parse('$backendBaseUrl/voice-query-text');

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Backend error: ${response.statusCode} ${response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// 🔹 Voice query (for future use — audio upload)
  Future<Map<String, dynamic>> sendVoiceQuery(List<int> audioBytes) async {
    final uri = Uri.parse('$backendBaseUrl/voice-query');

    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'audio',
          audioBytes,
          filename: 'audio.wav',
        ),
      );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception(
        'Backend error: ${response.statusCode} ${response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
