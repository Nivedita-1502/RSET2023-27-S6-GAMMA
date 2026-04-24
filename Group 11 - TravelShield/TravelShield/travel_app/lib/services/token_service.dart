// lib/services/token_service.dart
//
// Handles JWT token storage, retrieval, expiry check, and auto logout.
// Uses flutter_secure_storage — add to pubspec.yaml:
//   flutter_secure_storage: ^9.0.0

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../screens/login/login_page.dart'; // ← add this

class TokenService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';

  // ── Save token after login ──────────────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // ── Get token for API requests ──────────────────────────────────────────────
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // ── Delete token on logout ──────────────────────────────────────────────────
  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // ── Check if token is expired ───────────────────────────────────────────────
  static Future<bool> isTokenExpired() async {
    final token = await getToken();
    if (token == null) return true;

    try {
      // JWT = header.payload.signature — decode the payload
      final parts = token.split('.');
      if (parts.length != 3) return true;

      // Base64 decode the payload
      final payload = parts[1];
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64.decode(normalized));
      final data = jsonDecode(decoded) as Map<String, dynamic>;

      // Check expiry timestamp
      final exp = data['exp'] as int?;
      if (exp == null) return true;

      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().toUtc().isAfter(expiry);
    } catch (_) {
      return true;
    }
  }

  // ── Auto logout: call this on app startup ───────────────────────────────────
  static Future<void> checkAndLogoutIfExpired(BuildContext context) async {
    if (await isTokenExpired()) {
      await clearToken();
      if (context.mounted) {
// Instead of:
Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);

// Use:
Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (_) => const LoginPage()),
  (_) => false,
);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please login again.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // ── Get auth headers for API requests ──────────────────────────────────────
  static Future<Map<String, String>> authHeaders() async {
    final token = await getToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }
}