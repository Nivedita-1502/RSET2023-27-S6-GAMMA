// lib/services/chatbot_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart'; // ← import the config

class ChatbotService {
  static const Duration _timeout = Duration(seconds: 30);

  // ── Public API ─────────────────────────────────────────────────────────────

  static Future<String> sendMessage({
    required String message,
    String? location,
  }) async {
    final uri = Uri.parse('$baseUrl/chat'); // ← uses baseUrl from api_config.dart

    final body = jsonEncode({
      'message': message,
      if (location != null && location.isNotEmpty) 'location': location,
    });

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['reply'] as String? ?? 'Sorry, I received an empty response.';
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final detail = errorData['detail'] ?? 'Unknown server error';
        throw ChatbotException('Server error (${response.statusCode}): $detail');
      }
    } on ChatbotException {
      rethrow;
    } catch (e) {
      throw ChatbotException(
        'Connection failed. Please check your internet connection and try again.',
      );
    }
  }

  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health')) // ← uses baseUrl from api_config.dart
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

// ── Custom Exception ──────────────────────────────────────────────────────────
class ChatbotException implements Exception {
  final String message;
  const ChatbotException(this.message);

  @override
  String toString() => message;
}