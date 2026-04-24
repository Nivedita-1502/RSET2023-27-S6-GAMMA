import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../../../services/api_config.dart'; // ← centralized URL

const _bg      = Color(0xFFF5F6F8);
const _white   = Colors.white;
const _primary = Color(0xFF1A6B3C);
const _dark    = Color(0xFF0D1B12);
const _light   = Color(0xFF9EB5A8);


class ClothingPage extends StatefulWidget {
  const ClothingPage({super.key});

  @override
  State<ClothingPage> createState() => _ClothingPageState();
}

class _ClothingPageState extends State<ClothingPage> {
  final TextEditingController cityController = TextEditingController();

  String   weather     = "";
  double   temperature = 0;
  List     suggestions = [];
  bool     loading     = false;
  bool     hasResult   = false;
  String?  errorMsg;

  // Weather icon helper
  String _weatherIcon(String w) {
    switch (w.toLowerCase()) {
      case 'rain': case 'drizzle': return '🌧️';
      case 'thunderstorm':         return '⛈️';
      case 'clouds':               return '☁️';
      case 'clear':                return '☀️';
      case 'mist': case 'fog': case 'haze': return '🌫️';
      default:                     return '🌤️';
    }
  }

  Future<void> getClothingSuggestion() async {
    if (cityController.text.trim().isEmpty) return;

    setState(() {
      loading    = true;
      suggestions = [];
      hasResult  = false;
      errorMsg   = null;
    });

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/clothing_suggestion/${cityController.text.trim()}"),
      );
      final data = jsonDecode(response.body);

      if (data["status"] == "success") {
        setState(() {
          weather     = data["weather"];
          temperature = (data["temperature"] as num).toDouble();
          suggestions = data["suggestions"];
          hasResult   = true;
        });
      } else {
        setState(() => errorMsg = data["message"] ?? "Failed to fetch suggestions.");
      }
    } catch (e) {
      setState(() => errorMsg = "Connection error. Check backend.");
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Clothing Suggestion",
          style: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _dark,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header banner ───────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Text("👕", style: TextStyle(fontSize: 40)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "What to Wear?",
                          style: GoogleFonts.urbanist(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Get weather-based clothing advice",
                          style: GoogleFonts.urbanist(
                            fontSize: 12,
                            color: Colors.white60,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Search card ─────────────────────────────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Enter Destination",
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _light,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: cityController,
                    style: GoogleFonts.urbanist(fontSize: 15, color: _dark),
                    onSubmitted: (_) => getClothingSuggestion(),
                    decoration: InputDecoration(
                      hintText: "e.g. Munnar, Kochi, Wayanad...",
                      hintStyle: GoogleFonts.urbanist(
                          color: _light, fontSize: 14),
                      prefixIcon: const Icon(Icons.location_on_rounded,
                          color: _primary, size: 20),
                      filled: true,
                      fillColor: _bg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: _primary.withOpacity(.4)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Error
                  if (errorMsg != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        border: Border.all(color: Colors.red.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(errorMsg!,
                                style: TextStyle(
                                    color: Colors.red.shade800,
                                    fontSize: 13)),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : getClothingSuggestion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              "Get Clothing Advice",
                              style: GoogleFonts.urbanist(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Weather result card ─────────────────────────────────────────
            if (hasResult) ...[
              const SizedBox(height: 16),
              _card(
                child: Row(
                  children: [
                    Text(_weatherIcon(weather),
                        style: const TextStyle(fontSize: 52)),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: temperature.round().toString(),
                                style: GoogleFonts.urbanist(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  color: _dark,
                                ),
                              ),
                              TextSpan(
                                text: "°C",
                                style: GoogleFonts.urbanist(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: _light,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            weather,
                            style: GoogleFonts.urbanist(
                              color: _primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: Color(0xFF80E0AA), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              cityController.text.trim(),
                              style: GoogleFonts.urbanist(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _dark,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "Kerala, India",
                          style: GoogleFonts.urbanist(
                            fontSize: 12,
                            color: _light,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Suggestions card ──────────────────────────────────────────
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF5F1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.checkroom_rounded,
                              color: _primary, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Recommended Clothing",
                          style: GoogleFonts.urbanist(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _dark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...suggestions.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF5F1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: _primary,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.toString(),
                                  style: GoogleFonts.urbanist(
                                    fontSize: 14,
                                    color: _dark,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}