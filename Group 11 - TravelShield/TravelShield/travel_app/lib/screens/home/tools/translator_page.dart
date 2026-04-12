import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_fonts/google_fonts.dart';
import '../../../services/api_config.dart'; // ← centralized URL

const _bg      = Color(0xFFF5F6F8);
const _white   = Colors.white;
const _primary = Color(0xFF1A6B3C);
const _accent  = Color(0xFF25A05B);
const _dark    = Color(0xFF0D1B12);
const _light   = Color(0xFF9EB5A8);


class TranslatorPage extends StatefulWidget {
  const TranslatorPage({super.key});

  @override
  State<TranslatorPage> createState() => _TranslatorPageState();
}

class _TranslatorPageState extends State<TranslatorPage> {
  final TextEditingController textController = TextEditingController();
  final stt.SpeechToText speech = stt.SpeechToText();

  String translatedText = "";
  bool isListening = false;
  String direction = "en_ml";

  Future<void> translateText() async {
    String text = textController.text.trim();
    if (text.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/assistant/translate"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "text": text,
          "lang": direction == "ml_en" ? "en" : "ml"
        }),
      );

      final data = jsonDecode(response.body);
      setState(() {
        translatedText = data["translated_text"] ?? "No result.";
      });
    } catch (e) {
      setState(() {
        translatedText = "Connection error. Check backend.";
      });
    }
  }

  void startListening() async {
    bool available = await speech.initialize();
    if (!available) return;
    setState(() => isListening = true);
    String speechLang = direction == "ml_en" ? "ml-IN" : "en-US";
    speech.listen(
      localeId: speechLang,
      onResult: (result) {
        setState(() => textController.text = result.recognizedWords);
      },
    );
  }

  void stopListening() {
    speech.stop();
    setState(() => isListening = false);
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
          "Language Translator",
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

            // ── Direction card ──────────────────────────────────────────────
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
                        child: const Icon(Icons.translate_rounded,
                            color: _primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Language Direction",
                        style: GoogleFonts.urbanist(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _dark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6F8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _primary.withOpacity(.15)),
                    ),
                    child: DropdownButton<String>(
                      value: direction,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: _primary),
                      items: [
                        DropdownMenuItem(
                          value: "en_ml",
                          child: Text("English  →  Malayalam",
                              style: GoogleFonts.urbanist(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _dark)),
                        ),
                        DropdownMenuItem(
                          value: "ml_en",
                          child: Text("Malayalam  →  English",
                              style: GoogleFonts.urbanist(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _dark)),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          direction = value!;
                          translatedText = "";
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Input card ──────────────────────────────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Enter Text",
                    style: GoogleFonts.urbanist(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: textController,
                    maxLines: 4,
                    onTap: () => setState(() => translatedText = ""),
                    style: GoogleFonts.urbanist(
                        fontSize: 15, color: _dark),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF5F6F8),
                      hintText: direction == "en_ml"
                          ? "Type in English..."
                          : "Malayalam ലെ ടൈപ്പ് ചെയ്യുക...",
                      hintStyle: GoogleFonts.urbanist(
                          color: _light, fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Buttons ─────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    icon: isListening
                        ? Icons.mic_off_rounded
                        : Icons.mic_rounded,
                    label: isListening ? "Stop" : "Speak",
                    onTap: isListening ? stopListening : startListening,
                    outlined: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(
                    icon: Icons.translate_rounded,
                    label: "Translate",
                    onTap: translateText,
                    outlined: false,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Output card ─────────────────────────────────────────────────
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
                        child: const Icon(Icons.language_rounded,
                            color: _primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Translated Text",
                        style: GoogleFonts.urbanist(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _dark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: translatedText.isEmpty
                          ? const Color(0xFFF5F6F8)
                          : const Color(0xFFEEF5F1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: translatedText.isEmpty
                            ? Colors.transparent
                            : _primary.withOpacity(.2),
                      ),
                    ),
                    child: Text(
                      translatedText.isEmpty
                          ? "Translation will appear here..."
                          : translatedText,
                      style: GoogleFonts.urbanist(
                        fontSize: 15,
                        color: translatedText.isEmpty ? _light : _dark,
                        fontWeight: translatedText.isEmpty
                            ? FontWeight.w400
                            : FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  // ── Reusable card container ────────────────────────────────────────────────
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

  // ── Reusable action button ─────────────────────────────────────────────────
  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool outlined,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: outlined ? _white : _primary,
          borderRadius: BorderRadius.circular(14),
          border: outlined
              ? Border.all(color: _primary, width: 1.5)
              : null,
          boxShadow: outlined
              ? null
              : [
                  BoxShadow(
                    color: _primary.withOpacity(.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: outlined ? _primary : _white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: outlined ? _primary : _white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}