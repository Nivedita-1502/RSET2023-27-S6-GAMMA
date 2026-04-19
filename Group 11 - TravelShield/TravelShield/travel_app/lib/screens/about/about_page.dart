import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _bg      = Color(0xFFF5F6F8);
const _white   = Colors.white;
const _primary = Color(0xFF1A6B3C);
const _dark    = Color(0xFF0D1B12);
const _light   = Color(0xFF9EB5A8);

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const _features = [
    {'icon': Icons.currency_rupee_rounded,    'color': Color(0xFF00897B), 'title': 'Fake Currency Detection',  'desc': 'Detect counterfeit notes using AI'},
    {'icon': Icons.qr_code_scanner_rounded,   'color': Color(0xFF1A6B3C), 'title': 'Malicious QR Detection',   'desc': 'Scan QR codes safely before paying'},
    {'icon': Icons.map_rounded,               'color': Color(0xFF0277BD), 'title': 'AI Trip Planner',          'desc': 'Generate personalised Kerala itineraries'},
    {'icon': Icons.translate_rounded,         'color': Color(0xFF5E35B1), 'title': 'Translator',               'desc': 'Break language barriers while travelling'},
    {'icon': Icons.price_check_rounded,       'color': Color(0xFFF57C00), 'title': 'Overprice Checker',        'desc': 'Verify fair pricing for services'},
    {'icon': Icons.emergency_rounded,         'color': Color(0xFFB83232), 'title': 'SOS Emergency',            'desc': 'Instant access to emergency services'},
    {'icon': Icons.newspaper_rounded,         'color': Color(0xFF0F4D6B), 'title': 'Travel Alerts',            'desc': 'District-level safety news and alerts'},
    {'icon': Icons.chat_bubble_rounded,       'color': Color(0xFF1A6B3C), 'title': 'AI Chatbot',               'desc': 'Kerala tourism assistant powered by AI'},
  ];

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
        title: Text('About App',
            style: GoogleFonts.urbanist(
                fontSize: 18, fontWeight: FontWeight.w800, color: _dark)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // ── App header ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A1F14), Color(0xFF1A6B3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(children: [
              const Icon(Icons.travel_explore_rounded, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text('TravelShield',
                  style: GoogleFonts.urbanist(
                      fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 4),
              Text("God's Own Country — Safe & Smart Travel",
                  style: GoogleFonts.urbanist(
                      fontSize: 12, color: Colors.white60, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Version 1.0.0',
                    style: GoogleFonts.urbanist(
                        fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // ── Features ────────────────────────────────────────────────────
          Text('Features',
              style: GoogleFonts.urbanist(
                  fontSize: 16, fontWeight: FontWeight.w800, color: _dark)),
          const SizedBox(height: 12),
          ..._features.map((f) => _featureTile(
              f['icon'] as IconData,
              f['color'] as Color,
              f['title'] as String,
              f['desc'] as String)),

          const SizedBox(height: 24),

          // ── Built with ──────────────────────────────────────────────────
          Text('Built With',
              style: GoogleFonts.urbanist(
                  fontSize: 16, fontWeight: FontWeight.w800, color: _dark)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10)
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _techChip('Flutter', Icons.phone_android_rounded, const Color(0xFF0277BD)),
                _techChip('FastAPI', Icons.api_rounded, const Color(0xFF00897B)),
                _techChip('Groq AI', Icons.psychology_rounded, const Color(0xFF5E35B1)),
                _techChip('ML', Icons.model_training_rounded, const Color(0xFFF57C00)),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _featureTile(IconData icon, Color color, String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 8)
        ],
      ),
      child: Row(children: [
        Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
                color: color.withOpacity(.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: GoogleFonts.urbanist(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
          Text(desc,
              style: GoogleFonts.urbanist(
                  fontSize: 12, color: _light, fontWeight: FontWeight.w500)),
        ])),
      ]),
    );
  }

  Widget _techChip(String label, IconData icon, Color color) {
    return Column(children: [
      Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: color.withOpacity(.1),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22)),
      const SizedBox(height: 6),
      Text(label,
          style: GoogleFonts.urbanist(
              fontSize: 11, fontWeight: FontWeight.w700, color: _dark)),
    ]);
  }
}