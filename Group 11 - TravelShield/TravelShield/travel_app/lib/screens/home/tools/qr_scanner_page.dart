import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/api_config.dart'; // ← centralized URL

const _bg      = Color(0xFFF5F6F8);
const _white   = Colors.white;
const _primary = Color(0xFF1A6B3C);
const _dark    = Color(0xFF0D1B12);
const _light   = Color(0xFF9EB5A8);


class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  bool   scanned     = false;
  String resultText  = "Align QR code inside the frame";
  bool?  isSafe;   // null = no result yet, true = safe, false = malicious

  final ImagePicker picker = ImagePicker();

  // ── Check QR ──────────────────────────────────────────────────────────────
  Future<void> checkQR(String text) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/check_qr"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": text}),
      );
      final data = jsonDecode(response.body);
      setState(() {
        scanned    = true;
        isSafe     = data["result"] == "safe";
        resultText = isSafe! ? "SAFE QR CODE" : "MALICIOUS QR CODE";
      });
    } catch (e) {
      setState(() {
        scanned    = true;
        isSafe     = null;
        resultText = "Server connection error";
      });
    }
  }

  // ── Pick image ─────────────────────────────────────────────────────────────
  Future<void> pickQRImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final bytes   = await image.readAsBytes();
    final request = http.MultipartRequest(
        "POST", Uri.parse("$baseUrl/detect_qr_image"));
    request.files.add(
        http.MultipartFile.fromBytes("file", bytes, filename: image.name));

    final response     = await request.send();
    final responseData = await response.stream.bytesToString();
    final data         = jsonDecode(responseData);

    if (data["status"] == "success") {
      checkQR(data["text"]);
    } else {
      setState(() {
        scanned    = true;
        isSafe     = null;
        resultText = data["message"] ?? "Could not read QR from image.";
      });
    }
  }

  // ── Reset ──────────────────────────────────────────────────────────────────
  void resetScanner() {
    setState(() {
      scanned    = false;
      isSafe     = null;
      resultText = "Align QR code inside the frame";
    });
  }

  Color get _resultColor {
    if (isSafe == null) return _light;
    return isSafe! ? _primary : Colors.red.shade700;
  }

  IconData get _resultIcon {
    if (isSafe == null) return Icons.error_outline_rounded;
    return isSafe! ? Icons.verified_rounded : Icons.warning_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      appBar: AppBar(
        backgroundColor: _dark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "QR Security Scanner",
          style: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _white,
          ),
        ),
      ),
      body: Column(
        children: [

          // ── Camera section ─────────────────────────────────────────────────
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                // Camera feed
                MobileScanner(
                  onDetect: (barcodeCapture) {
                    if (scanned) return;
                    final barcodes = barcodeCapture.barcodes;
                    if (barcodes.isNotEmpty) {
                      final code = barcodes.first.rawValue;
                      if (code != null) checkQR(code);
                    }
                  },
                ),

                // Dark overlay outside frame
                Positioned.fill(
                  child: CustomPaint(painter: _OverlayPainter()),
                ),

                // Scanner frame
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: scanned
                            ? (isSafe == true
                                ? Colors.greenAccent
                                : isSafe == false
                                    ? Colors.redAccent
                                    : Colors.orangeAccent)
                            : Colors.white,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: scanned
                        ? Container(
                            decoration: BoxDecoration(
                              color: (isSafe == true
                                      ? Colors.green
                                      : Colors.red)
                                  .withOpacity(.15),
                              borderRadius: BorderRadius.circular(17),
                            ),
                            child: Center(
                              child: Icon(
                                _resultIcon,
                                color: isSafe == true
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                size: 80,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),

                // Guide text
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Text(
                    scanned ? resultText : "Align QR Code inside the frame",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.urbanist(
                      color: scanned ? _resultColor : Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Result panel ───────────────────────────────────────────────────
          Container(
            color: _white,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            child: Column(
              children: [

                // Status card
                if (scanned)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _resultColor.withOpacity(.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: _resultColor.withOpacity(.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _resultColor.withOpacity(.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_resultIcon,
                              color: _resultColor, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resultText,
                                style: GoogleFonts.urbanist(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _resultColor,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isSafe == true
                                    ? "This QR code is safe to open."
                                    : isSafe == false
                                        ? "Do not open this QR code!"
                                        : "Could not verify this QR code.",
                                style: GoogleFonts.urbanist(
                                  fontSize: 12,
                                  color: _light,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: _btn(
                        icon: Icons.refresh_rounded,
                        label: "Scan Again",
                        onTap: resetScanner,
                        outlined: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _btn(
                        icon: Icons.image_rounded,
                        label: "Pick Image",
                        onTap: pickQRImage,
                        outlined: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn({
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
          border: outlined ? Border.all(color: _primary, width: 1.5) : null,
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

// ── Dark overlay painter (dims area outside scan frame) ──────────────────────
class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(.55);
    final frameSize = 240.0;
    final left   = (size.width  - frameSize) / 2;
    final top    = (size.height - frameSize) / 2;
    final frame  = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, frameSize, frameSize),
      const Radius.circular(20),
    );
    final full = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()..addRRect(frame);
    final path = Path.combine(PathOperation.difference, full, hole);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}