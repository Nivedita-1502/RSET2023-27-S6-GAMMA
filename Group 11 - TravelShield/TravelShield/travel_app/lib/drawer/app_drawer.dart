import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/user_session.dart';
import '../screens/alerts/district_alert_screen.dart';

const _primary = Color(0xFF1A6B3C);
const _accent  = Color(0xFF25A05B);
const _dark    = Color(0xFF0D1B12);
const _light   = Color(0xFF9EB5A8);
const _bg      = Color(0xFFF5F6F8);

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user  = UserSession.currentUser;
    final name  = user["first_name"] ?? user["name"] ?? "Traveler";
    final email = user["email"] ?? "guest@travel.com";
    final initials = name.isNotEmpty ? name[0].toUpperCase() : "T";

    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [

          // ── Header ───────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A1F14), Color(0xFF1A6B3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.travel_explore, size: 28, color: Colors.white70),
                  const SizedBox(width: 10),
                  Text('TravelShield',
                    style: GoogleFonts.urbanist(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 20),
                Row(children: [
                  // Initials avatar
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(.15),
                      border: Border.all(color: Colors.white38, width: 2),
                    ),
                    child: Center(child: Text(initials,
                      style: GoogleFonts.urbanist(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: GoogleFonts.urbanist(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(email, style: GoogleFonts.urbanist(
                      color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                  ])),
                ]),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── AI Features ───────────────────────────────────────────────────
          _sectionLabel('AI FEATURES'),

          _drawerItem(context, icon: Icons.currency_exchange_rounded,
            label: 'Currency Checker', color: const Color(0xFF00897B),
            route: '/currency'),

          _drawerItem(context, icon: Icons.qr_code_scanner_rounded,
            label: 'QR Scanner', color: const Color(0xFF1A6B3C),
            route: '/qr'),

          _drawerItem(context, icon: Icons.checkroom_rounded,
            label: 'Clothing Suggestion', color: const Color(0xFF5E35B1),
            route: '/clothing'),

          _drawerItem(context, icon: Icons.translate_rounded,
            label: 'Translator', color: const Color(0xFF0277BD),
            route: '/translator'),

          _drawerItem(context, icon: Icons.price_check_rounded,
            label: 'Overprice Checker', color: const Color(0xFFF57C00),
            route: '/price'),

          _divider(),

          // ── Travel ────────────────────────────────────────────────────────
          _sectionLabel('TRAVEL'),

          _drawerItem(context, icon: Icons.map_rounded,
            label: 'Trip Planner', color: const Color(0xFF1A6B3C),
            route: '/trip'),

          _drawerItemWidget(context,
            icon: Icons.newspaper_rounded,
            label: 'TravelShield Alerts',
            color: const Color(0xFF0F4D6B),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const DistrictAlertScreen()));
            }),

          _divider(),

          // ── Other ─────────────────────────────────────────────────────────
          _sectionLabel('OTHER'),

          _drawerItem(context, icon: Icons.settings_rounded,
            label: 'Settings', color: Colors.grey,
            route: '/settings'),

          _drawerItem(context, icon: Icons.info_outline_rounded,
            label: 'About App', color: Colors.grey,
            route: '/about'),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
    child: Text(text,
      style: GoogleFonts.urbanist(
        fontSize: 11, fontWeight: FontWeight.w700,
        color: _light, letterSpacing: 0.8)),
  );

  Widget _divider() => const Divider(height: 1, indent: 20, endIndent: 20);

  Widget _drawerItem(BuildContext context, {
    required IconData icon, required String label,
    required Color color, required String route,
  }) => _drawerItemWidget(context, icon: icon, label: label, color: color,
    onTap: () { Navigator.pop(context); Navigator.pushNamed(context, route); });

  Widget _drawerItemWidget(BuildContext context, {
    required IconData icon, required String label,
    required Color color, required VoidCallback onTap,
  }) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    leading: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 18)),
    title: Text(label, style: GoogleFonts.urbanist(
      fontSize: 14, fontWeight: FontWeight.w600, color: _dark)),
    onTap: onTap,
  );
}