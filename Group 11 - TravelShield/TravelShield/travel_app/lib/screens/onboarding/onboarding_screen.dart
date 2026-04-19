// lib/screens/onboarding/onboarding_screen.dart
//
// Shows only on first app launch, never again after.
// Uses flutter_secure_storage (already in your pubspec.yaml).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../login/login_page.dart';

const _primary = Color(0xFF1A6B3C);
const _accent  = Color(0xFF25A05B);
const _dark    = Color(0xFF0D1B12);
const _white   = Colors.white;

// ── Onboarding data ───────────────────────────────────────────────────────────

class _OnboardPage {
  final String emoji;
  final String title;
  final String subtitle;
  final String description;
  final Color  bgColor;
  final Color  accentColor;
  final List<String> bulletPoints;

  const _OnboardPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.bgColor,
    required this.accentColor,
    required this.bulletPoints,
  });
}

const _pages = [
  _OnboardPage(
    emoji:       '🌿',
    title:       'Welcome to\nTravelShield',
    subtitle:    "God's Own Country, Safely.",
    description: 'Your all-in-one travel companion for exploring Kerala — safely, smartly, and confidently.',
    bgColor:     Color(0xFF0A1F14),
    accentColor: Color(0xFF25A05B),
    bulletPoints: [
      '🗺️  Explore 14 stunning Kerala districts',
      '🤖  AI-powered travel tools',
      '🛡️  Real-time safety & emergency features',
    ],
  ),
  _OnboardPage(
    emoji:       '🚨',
    title:       'SOS &\nEmergency',
    subtitle:    'Help is always one tap away.',
    description: 'In any emergency, TravelShield instantly locates you and connects you to nearby help.',
    bgColor:     Color(0xFF1A0A0A),
    accentColor: Color(0xFFE53935),
    bulletPoints: [
      '📍  Instant GPS location detection',
      '🏥  Find nearby hospitals & police stations',
      '📲  Send SOS via WhatsApp to emergency contact',
      '📞  One-tap access to 20+ emergency helplines',
    ],
  ),
  _OnboardPage(
    emoji:       '⚠️',
    title:       'Safety\nAlerts',
    subtitle:    'Stay informed, stay safe.',
    description: 'Get real-time district-level safety alerts and travel advisories across Kerala.',
    bgColor:     Color(0xFF0A0F1A),
    accentColor: Color(0xFF1565C0),
    bulletPoints: [
      '🌦️  Live weather updates for your location',
      '📰  District-wise travel alerts & news',
      '💡  Daily safety tips for Kerala travellers',
      '🔔  Instant notifications for emergencies',
    ],
  ),
  _OnboardPage(
    emoji:       '🤖',
    title:       'AI Travel\nTools',
    subtitle:    'Smart tools for smart travellers.',
    description: 'Powerful AI features that make your Kerala trip safer and more enjoyable.',
    bgColor:     Color(0xFF0F0A1A),
    accentColor: Color(0xFF7B1FA2),
    bulletPoints: [
      '💱  Currency checker',
      '👗  Clothing suggestions by weather',
      '🔍  QR code scanner & verifier',
      '🗣️  Language translator',
      '💰  Overprice checker for vehicles',
    ],
  ),
];

// ── Onboarding Screen ─────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _controller   = PageController();
  final _storage      = const FlutterSecureStorage();
  int   _currentPage  = 0;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Mark onboarding as seen and go to login ───────────────────────────────
 Future<void> _finish() async {
  await _storage.write(key: 'onboarding_done', value: 'true');
  if (!mounted) return;
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const LoginPage()),
  );
}
  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor: page.bgColor,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        color: page.bgColor,
        child: SafeArea(
          child: Column(
            children: [

              // ── Skip button ───────────────────────────────────────────────
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 20, 0),
                  child: _currentPage < _pages.length - 1
                      ? TextButton(
                          onPressed: _finish,
                          child: Text('Skip',
                              style: GoogleFonts.urbanist(
                                  color: Colors.white38,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                        )
                      : const SizedBox(height: 40),
                ),
              ),

              // ── Page content ──────────────────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) {
                    setState(() => _currentPage = i);
                    _fadeCtrl.reset();
                    _fadeCtrl.forward();
                  },
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => _PageContent(page: _pages[i]),
                ),
              ),

              // ── Dots + button ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [

                    // Dot indicators
                    Row(
                      children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 6),
                          width:  i == _currentPage ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _currentPage
                                ? page.accentColor
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),

                    // Next / Get Started button
                    GestureDetector(
                      onTap: _nextPage,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: EdgeInsets.symmetric(
                          horizontal: _currentPage == _pages.length - 1 ? 28 : 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: page.accentColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: page.accentColor.withOpacity(.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentPage == _pages.length - 1
                                  ? 'Get Started'
                                  : 'Next',
                              style: GoogleFonts.urbanist(
                                  color: _white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _currentPage == _pages.length - 1
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                              color: _white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Individual page content ───────────────────────────────────────────────────

class _PageContent extends StatelessWidget {
  final _OnboardPage page;
  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const SizedBox(height: 20),

          // Emoji in glowing circle
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: page.accentColor.withOpacity(.15),
              border: Border.all(
                  color: page.accentColor.withOpacity(.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: page.accentColor.withOpacity(.2),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Text(page.emoji,
                  style: const TextStyle(fontSize: 42)),
            ),
          ),

          const SizedBox(height: 28),

          // Title
          Text(
            page.title,
            style: GoogleFonts.urbanist(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: _white,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 10),

          // Subtitle badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: page.accentColor.withOpacity(.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: page.accentColor.withOpacity(.4), width: 1),
            ),
            child: Text(
              page.subtitle,
              style: GoogleFonts.urbanist(
                  color: page.accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            style: GoogleFonts.urbanist(
              fontSize: 15,
              color: Colors.white60,
              fontWeight: FontWeight.w500,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 28),

          // Divider line
          Container(height: 1, color: Colors.white10),

          const SizedBox(height: 24),

          // Bullet points
          ...page.bulletPoints.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    point.substring(0, point.indexOf(' ')),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      point.substring(point.indexOf(' ') + 1),
                      style: GoogleFonts.urbanist(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}