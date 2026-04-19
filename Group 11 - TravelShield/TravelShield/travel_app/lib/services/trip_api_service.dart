import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trip_model.dart';
import 'user_session.dart';
import 'api_config.dart'; // ← import the config

class TripApiService {
  static final TripApiService _instance = TripApiService._internal();
  factory TripApiService() => _instance;
  TripApiService._internal();

  String get _email => UserSession.email;
  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  // ── Trips ──────────────────────────────────────────────────

  Future<List<TripModel>> getTrips() async {
    final res = await http.get(
      Uri.parse('$baseUrl/trips?email=${Uri.encodeComponent(_email)}'),
      headers: _headers,
    );
    final data = jsonDecode(res.body);
    if (data['status'] == 'success') {
      return (data['trips'] as List)
          .map((e) => TripModel.fromJson(e))
          .toList();
    }
    throw Exception(data['message'] ?? 'Failed to load trips');
  }

  Future<TripModel> createTrip(Map<String, dynamic> tripData) async {
    tripData['user_email'] = _email;
    final res = await http.post(
      Uri.parse('$baseUrl/trips'),
      headers: _headers,
      body: jsonEncode(tripData),
    );
    final data = jsonDecode(res.body);
    if (data['status'] == 'success') {
      return TripModel.fromJson({...tripData, 'id': data['id']});
    }
    throw Exception(data['message'] ?? 'Failed to create trip');
  }

  Future<void> deleteTrip(int tripId) async {
    await http.delete(
      Uri.parse(
          '$baseUrl/trips/$tripId?email=${Uri.encodeComponent(_email)}'),
      headers: _headers,
    );
  }

  Future<void> updateTrip(int tripId, Map<String, dynamic> updates) async {
    updates['user_email'] = _email;
    await http.patch(
      Uri.parse('$baseUrl/trips/$tripId'),
      headers: _headers,
      body: jsonEncode(updates),
    );
  }

  // ── Destinations ──────────────────────────────────────────

  Future<List<String>> getDestinations() async {
    final res = await http.get(
      Uri.parse('$baseUrl/districts'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final raw = List<String>.from(data['districts'] ?? []);
      return raw.toSet().toList()..sort();
    }
    throw Exception('Failed to load destinations');
  }

  // ── Itinerary ──────────────────────────────────────────────

  Future<Map<String, dynamic>> generateItinerary({
    required String destination,
    required String startDate,
    required String endDate,
    required String purpose,
    required int travelersCount,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/itinerary/generate'),
      headers: _headers,
      body: jsonEncode({
        'destination': destination,
        'start_date': startDate,
        'end_date': endDate,
        'purpose': purpose,
        'travelers_count': travelersCount,
      }),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('Failed to generate itinerary: ${res.statusCode}');
  }
}