import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';  // ← import the config

class ApiService {

  // SIGNUP
  static Future signup(Map<String, dynamic> data) async {

    final response = await http.post(
      Uri.parse("$baseUrl/signup"),  // ← uses baseUrl from api_config.dart
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    return jsonDecode(response.body);
  }

  // LOGIN
  static Future login(String email, String password) async {

    final response = await http.post(
      Uri.parse("$baseUrl/login"),  // ← uses baseUrl from api_config.dart
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password
      }),
    );

    return jsonDecode(response.body);
  }

}