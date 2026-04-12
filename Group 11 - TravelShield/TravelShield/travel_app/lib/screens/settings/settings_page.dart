import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../services/api_config.dart';
import '../../services/token_service.dart';
import '../../services/user_session.dart';
import '../login/login_page.dart'; // ← add this

const _bg      = Color(0xFFF5F6F8);
const _white   = Colors.white;
const _primary = Color(0xFF1A6B3C);
const _dark    = Color(0xFF0D1B12);
const _light   = Color(0xFF9EB5A8);

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notifications = true;

  // ── Delete Account ──────────────────────────────────────────────────────────
  Future<void> _deleteAccount() async {
    // Step 1: Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 26),
          const SizedBox(width: 10),
          Text('Delete Account',
              style: GoogleFonts.urbanist(
                  fontWeight: FontWeight.w800, fontSize: 16, color: _dark)),
        ]),
        content: Text(
          'This will permanently delete your account and all your trip data. This action cannot be undone.',
          style: GoogleFonts.urbanist(fontSize: 13, color: _light),
        ),
        actions: [
          // Cancel button
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.urbanist(
                    color: _primary, fontWeight: FontWeight.w700)),
          ),
          // Delete button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: GoogleFonts.urbanist(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Step 2: Call backend to delete account
    try {
      final headers = await TokenService.authHeaders();
      final response = await http.delete(
        Uri.parse("$baseUrl/account"),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (data["status"] == "success") {
        // Step 3: Clear token and session locally
        await TokenService.clearToken();
        UserSession.clear();

        // Step 4: Redirect to login page
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (_) => const LoginPage()),
  (_) => false,
);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account has been deleted.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "Failed to delete account."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Connection error. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
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
        title: Text('Settings',
            style: GoogleFonts.urbanist(
                fontSize: 18, fontWeight: FontWeight.w800, color: _dark)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          _sectionLabel('PREFERENCES'),
          const SizedBox(height: 10),
          _settingsCard(children: [
            _switchTile(
              icon: Icons.notifications_active_rounded,
              color: _primary,
              title: 'Travel Alerts',
              subtitle: 'Get notified about district alerts',
              value: _notifications,
              onChanged: (v) => setState(() => _notifications = v),
            ),
          ]),

          const SizedBox(height: 24),

          _sectionLabel('APP INFO'),
          const SizedBox(height: 10),
          _settingsCard(children: [
            _infoTile(Icons.info_outline_rounded, _primary, 'Version', '1.0.0'),
            _divider(),
            _infoTile(Icons.shield_rounded, const Color(0xFF5E35B1), 'Privacy Policy', 'View policy'),
            _divider(),
            _infoTile(Icons.description_rounded, const Color(0xFF0277BD), 'Terms & Conditions', 'View terms'),
          ]),

          const SizedBox(height: 24),

          // ── Danger Zone ──────────────────────────────────────────────────────
          _sectionLabel('DANGER ZONE'),
          const SizedBox(height: 10),
          _settingsCard(children: [
            _dangerTile(
              icon: Icons.delete_forever_rounded,
              title: 'Delete Account',
              subtitle: 'Permanently delete your account and data',
              onTap: _deleteAccount,
            ),
          ]),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF5F1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _primary.withOpacity(.15)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, color: _primary, size: 18),
              const SizedBox(width: 12),
              Expanded(child: Text(
                'More settings like language and theme will be available in future updates.',
                style: GoogleFonts.urbanist(
                    fontSize: 12, color: _primary, fontWeight: FontWeight.w500),
              )),
            ]),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: GoogleFonts.urbanist(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: text == 'DANGER ZONE' ? Colors.red.shade300 : _light,
          letterSpacing: 0.8));

  Widget _settingsCard({required List<Widget> children}) => Container(
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 14,
              offset: const Offset(0, 4))],
        ),
        child: Column(children: children),
      );

  Widget _divider() => Divider(
      height: 1, indent: 64, endIndent: 16, color: Colors.grey.shade100);

  Widget _switchTile({
    required IconData icon, required Color color,
    required String title, required String subtitle,
    required bool value, required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: color.withOpacity(.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 14),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.urbanist(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
              Text(subtitle, style: GoogleFonts.urbanist(
                  fontSize: 12, color: _light, fontWeight: FontWeight.w500)),
            ])),
        Switch(value: value, onChanged: onChanged, activeColor: _primary),
      ]),
    );
  }

  Widget _infoTile(IconData icon, Color color, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: color.withOpacity(.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 14),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.urbanist(
                  fontSize: 14, fontWeight: FontWeight.w700, color: _dark)),
              Text(subtitle, style: GoogleFonts.urbanist(
                  fontSize: 12, color: _light, fontWeight: FontWeight.w500)),
            ])),
        Icon(Icons.chevron_right_rounded, color: _light, size: 18),
      ]),
    );
  }

  // ── Danger tile (red styled) ────────────────────────────────────────────────
  Widget _dangerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: Colors.red.withOpacity(.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: Colors.red, size: 18)),
          const SizedBox(width: 14),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.urbanist(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: Colors.red)),
                Text(subtitle, style: GoogleFonts.urbanist(
                    fontSize: 12, color: Colors.red.shade300,
                    fontWeight: FontWeight.w500)),
              ])),
          Icon(Icons.chevron_right_rounded, color: Colors.red.shade200, size: 18),
        ]),
      ),
    );
  }
}