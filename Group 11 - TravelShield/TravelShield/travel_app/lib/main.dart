// lib/main.dart
// Added: onboarding check on app startup
// If first launch → show onboarding → then login
// If returning user → go straight to login

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/onboarding/onboarding_screen.dart';  // ← NEW
import 'screens/login/login_page.dart';
import 'screens/home/main_navigation.dart';
import 'screens/home/tools/currency_page.dart';
import 'screens/home/tools/qr_scanner_page.dart';
import 'screens/home/tools/translator_page.dart';
import 'screens/home/tools/clothing_page.dart';
import 'screens/home/tools/price_checker_page.dart';
import 'screens/settings/settings_page.dart';
import 'screens/about/about_page.dart';
import 'screens/trip_planner/trip_planner_screen.dart';
import 'screens/sos/sos_page.dart';

void main() {
  runApp(const KeralaApp());
}

class KeralaApp extends StatelessWidget {
  const KeralaApp({super.key});

  @override
  Widget build(BuildContext context) {
   return MaterialApp(
  debugShowCheckedModeBanner: false,
  home: const _StartupRouter(),  // ← keep this
  routes: {
    // ← REMOVE the "/" entry
    "/home":       (context) => const MainNavigation(),
    "/currency":   (context) => const CurrencyPage(),
    "/qr":         (context) => const QRScannerPage(),
    "/translator": (context) => const TranslatorPage(),
    "/clothing":   (context) => const ClothingPage(),
    "/settings":   (context) => const SettingsPage(),
    "/about":      (context) => const AboutPage(),
    "/trip":       (context) => const TripPlannerScreen(),
    "/sos":        (context) => const SOSPage(),
    "/price":      (context) => const PriceCheckerPage(),
  },
);
  }
}

// ── Startup router: checks if onboarding has been seen ───────────────────────

class _StartupRouter extends StatefulWidget {
  const _StartupRouter();

  @override
  State<_StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<_StartupRouter> {
  final _storage = const FlutterSecureStorage();
  Widget? _screen;

  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final done = await _storage.read(key: 'onboarding_done');
    if (!mounted) return;
    setState(() {
      // If onboarding never seen → show onboarding
      // Otherwise → go straight to login
      _screen = done == 'true'
          ? const LoginPage()
          : const OnboardingScreen();
          
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show blank green screen while checking storage
    return _screen ?? const Scaffold(
      backgroundColor: Color(0xFF1A6B3C),
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

