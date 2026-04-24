// lib/services/news_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart'; // ← import the config

// ─────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────

class NewsArticle {
  final String title;
  final String url;
  final String source;
  final String publishedAt;
  final String? description;

  const NewsArticle({
    required this.title,
    required this.url,
    required this.source,
    required this.publishedAt,
    this.description,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) => NewsArticle(
        title: json['title'] ?? '',
        url: json['url'] ?? '',
        source: json['source'] ?? '',
        publishedAt: json['published_at'] ?? '',
        description: json['description'],
      );

  String get timeAgo {
    try {
      final dt = DateTime.parse(publishedAt).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return publishedAt.length > 10 ? publishedAt.substring(0, 10) : publishedAt;
    }
  }
}

enum AlertLevel { high, medium, low, none }

class DistrictAlertData {
  final String district;
  final AlertLevel alertLevel;
  final String alertSummary;
  final List<NewsArticle> newsArticles;
  final DateTime fetchedAt;

  const DistrictAlertData({
    required this.district,
    required this.alertLevel,
    required this.alertSummary,
    required this.newsArticles,
    required this.fetchedAt,
  });

  factory DistrictAlertData.fromJson(Map<String, dynamic> json) {
    final levelStr = (json['alert_level'] ?? 'NONE').toString().toUpperCase();
    final level = AlertLevel.values.firstWhere(
      (e) => e.name.toUpperCase() == levelStr,
      orElse: () => AlertLevel.none,
    );
    return DistrictAlertData(
      district: json['district'] ?? '',
      alertLevel: level,
      alertSummary: json['alert_summary'] ?? '',
      newsArticles: (json['news_articles'] as List? ?? [])
          .map((a) => NewsArticle.fromJson(a as Map<String, dynamic>))
          .toList(),
      fetchedAt: DateTime.tryParse(json['fetched_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isSafe => alertLevel == AlertLevel.none || alertLevel == AlertLevel.low;
}

// ─────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────

class NewsService {
  static const Duration _timeout = Duration(seconds: 20);

  static Future<DistrictAlertData> fetchDistrictAlerts(String district) async {
    final uri = Uri.parse('$baseUrl/district-news') // ← uses baseUrl
        .replace(queryParameters: {'district': district});
    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return DistrictAlertData.fromJson(json);
    }
    throw Exception('Server error ${response.statusCode}: ${response.body}');
  }

  static Future<List<String>> fetchDistrictList() async {
    try {
      final uri = Uri.parse('$baseUrl/districts'); // ← uses baseUrl
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return List<String>.from(json['districts'] ?? []);
      }
    } catch (_) {}
    return _keralaDistricts;
  }

  static const List<String> _keralaDistricts = [
    'Thiruvananthapuram', 'Kollam', 'Pathanamthitta', 'Alappuzha',
    'Kottayam', 'Idukki', 'Ernakulam', 'Thrissur', 'Palakkad',
    'Malappuram', 'Kozhikode', 'Wayanad', 'Kannur', 'Kasaragod',
  ];
}