import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../services/api_config.dart'; // ← import the config

const _bg      = Color(0xFFF5F6F8);
const _white   = Colors.white;
const _primary = Color(0xFF1A6B3C);
const _dark    = Color(0xFF0D1B12);
const _light   = Color(0xFF9EB5A8);

class OTPVerificationPage extends StatefulWidget {
  final String email;
  final VoidCallback onVerified;

  const OTPVerificationPage({
    super.key,
    required this.email,
    required this.onVerified,
  });

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  bool _loading   = false;
  bool _resending = false;
  String? _error;

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_otp.length < 6) {
      setState(() => _error = 'Please enter the complete 6-digit OTP');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/otp/verify'), // ← uses baseUrl
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, 'otp': _otp}),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        widget.onVerified();
      } else {
        setState(() { _error = data['message']; _loading = false; });
      }
    } catch (_) {
      setState(() { _error = 'Connection error. Try again.'; _loading = false; });
    }
  }

  Future<void> _resend() async {
    setState(() { _resending = true; _error = null; });
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/otp/send'), // ← uses baseUrl
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP resent to ${widget.email}'),
              backgroundColor: _primary));
      } else {
        setState(() => _error = data['message']);
      }
    } catch (_) {
      setState(() => _error = 'Failed to resend OTP');
    } finally {
      setState(() => _resending = false);
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
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF5F1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: _primary, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Verify Email',
            style: GoogleFonts.urbanist(
                fontSize: 18, fontWeight: FontWeight.w800, color: _dark)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            const SizedBox(height: 20),

            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF5F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_unread_rounded,
                  color: _primary, size: 36),
            ),

            const SizedBox(height: 24),

            Text('Check Your Email',
                style: GoogleFonts.urbanist(
                    fontSize: 24, fontWeight: FontWeight.w800, color: _dark)),

            const SizedBox(height: 10),

            Text(
              'We sent a 6-digit verification code to',
              style: GoogleFonts.urbanist(fontSize: 14, color: _light),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              widget.email,
              style: GoogleFonts.urbanist(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _primary),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 36),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (i) => _OTPBox(
                controller: _controllers[i],
                focusNode: _focusNodes[i],
                onChanged: (val) {
                  if (val.isNotEmpty && i < 5) {
                    _focusNodes[i + 1].requestFocus();
                  } else if (val.isEmpty && i > 0) {
                    _focusNodes[i - 1].requestFocus();
                  }
                  setState(() => _error = null);
                },
              )),
            ),

            const SizedBox(height: 16),

            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Color(0xFFE53935), size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!,
                      style: GoogleFonts.urbanist(
                          color: const Color(0xFFE53935), fontSize: 13))),
                ]),
              ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _loading ? null : _verify,
                child: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text('Verify & Create Account',
                        style: GoogleFonts.urbanist(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: _white)),
              ),
            ),

            const SizedBox(height: 20),

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text("Didn't receive the code? ",
                  style: GoogleFonts.urbanist(color: _light, fontSize: 13)),
              GestureDetector(
                onTap: _resending ? null : _resend,
                child: Text(
                  _resending ? 'Sending...' : 'Resend',
                  style: GoogleFonts.urbanist(
                      color: _primary, fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ]),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _OTPBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OTPBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48, height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.urbanist(
            fontSize: 22, fontWeight: FontWeight.w800, color: _dark),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: _white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primary, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}