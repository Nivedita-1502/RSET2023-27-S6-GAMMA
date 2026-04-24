import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/api_config.dart'; // ← centralized URL

const _bg      = Color(0xFFF5F6F8);
const _white   = Colors.white;
const _primary = Color(0xFF1A6B3C);
const _accent  = Color(0xFF25A05B);
const _dark    = Color(0xFF0D1B12);
const _light   = Color(0xFF9EB5A8);


class CurrencyPage extends StatefulWidget {
  const CurrencyPage({super.key});

  @override
  State<CurrencyPage> createState() => _CurrencyPageState();
}

class _CurrencyPageState extends State<CurrencyPage> {
  double probability = 0;
  String prediction  = "No scan yet";
  bool   isLoading   = false;
  bool   hasResult   = false;

  bool get _isReal => prediction == "Real Note";

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        isLoading  = true;
        prediction = "Scanning...";
        hasResult  = false;
      });

      final bytes   = await image.readAsBytes();
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/detect_currency"),
      );
      request.files.add(
        http.MultipartFile.fromBytes("file", bytes, filename: image.name),
      );

      final response     = await request.send();
      final responseData = await response.stream.bytesToString();
      final data         = jsonDecode(responseData);

      if (data["status"] == "success") {
        final realProb = (data["real_probability"] ?? 0) / 100;
        setState(() {
          probability = (realProb as double).clamp(0.0, 1.0);
          prediction  = data["prediction"] ?? "Unknown";
          hasResult   = true;
        });
      } else {
        setState(() {
          prediction = "Detection failed";
          hasResult  = true;
        });
      }
    } catch (e) {
      setState(() {
        prediction = "Error connecting to server";
        hasResult  = true;
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Color get _resultColor {
    if (!hasResult) return _light;
    if (prediction == "Real Note") return _primary;
    if (prediction == "Fake Note") return Colors.red.shade700;
    return Colors.orange.shade700;
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
          "Currency Scanner",
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
                  const Icon(Icons.currency_rupee_rounded,
                      color: Colors.white70, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Currency Authenticity",
                          style: GoogleFonts.urbanist(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Detect real vs fake currency notes",
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

            // ── Scan result card ────────────────────────────────────────────
            _card(
              child: Column(
                children: [

                  // Circular indicator
                  CircularPercentIndicator(
                    radius: 100,
                    lineWidth: 12,
                    percent: probability,
                    animation: true,
                    animateFromLastPercent: true,
                    circularStrokeCap: CircularStrokeCap.round,
                    progressColor: _resultColor,
                    backgroundColor: _bg,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${(probability * 100).toStringAsFixed(1)}%",
                          style: GoogleFonts.urbanist(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: _dark,
                          ),
                        ),
                        Text(
                          "confidence",
                          style: GoogleFonts.urbanist(
                            fontSize: 11,
                            color: _light,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: hasResult
                          ? _resultColor.withOpacity(.1)
                          : _bg,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: hasResult
                            ? _resultColor.withOpacity(.3)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasResult
                              ? (_isReal
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded)
                              : Icons.document_scanner_rounded,
                          color: _resultColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          prediction,
                          style: GoogleFonts.urbanist(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _resultColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (hasResult) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _resultColor.withOpacity(.07),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _isReal
                            ? "✅ This note appears to be genuine. Confidence level is high."
                            : "⚠️ This note may be counterfeit. Please verify with a bank.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.urbanist(
                          fontSize: 13,
                          color: _resultColor,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Upload card ─────────────────────────────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Upload Currency Image",
                    style: GoogleFonts.urbanist(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _dark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Take a clear photo of the note in good lighting",
                    style: GoogleFonts.urbanist(
                      fontSize: 12,
                      color: _light,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_rounded,
                              color: Colors.white),
                      label: Text(
                        isLoading ? "Scanning..." : "Choose Image",
                        style: GoogleFonts.urbanist(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: isLoading ? null : pickImage,
                    ),
                  ),
                ],
              ),
            ),

            // ── Tips card ───────────────────────────────────────────────────
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FAF4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _primary.withOpacity(.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lightbulb_rounded,
                        color: _white, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Tips for best results",
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _primary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "• Place the note on a flat, dark surface\n"
                          "• Ensure good lighting with no shadows\n"
                          "• Capture the full note clearly in frame",
                          style: GoogleFonts.urbanist(
                            fontSize: 12,
                            color: const Color(0xFF2E5E42),
                            fontWeight: FontWeight.w500,
                            height: 1.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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