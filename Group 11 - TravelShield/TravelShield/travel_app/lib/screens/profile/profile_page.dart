import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../services/user_session.dart';
import '../../services/api_config.dart'; // ← import the config

const _bg      = Color(0xFFF5F6F8);
const _white   = Colors.white;
const _primary = Color(0xFF1A6B3C);
const _dark    = Color(0xFF0D1B12);
const _light   = Color(0xFF9EB5A8);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  String _formatDob(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw);
      const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return raw.length > 10 ? raw.substring(0, 10) : raw;
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log Out?',
            style: GoogleFonts.urbanist(fontWeight: FontWeight.w800, fontSize: 17, color: _dark)),
        content: Text('Are you sure you want to log out?',
            style: GoogleFonts.urbanist(fontSize: 14, color: _light)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.urbanist(color: _light, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              UserSession.clear();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context, rootNavigator: true)
                    .pushNamedAndRemoveUntil('/', (route) => false);
              });
            },
            child: Text('Log Out',
                style: GoogleFonts.urbanist(color: _white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _openEdit() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const _EditProfilePage()))
        .then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final user        = UserSession.currentUser;
    final fullName    = [user["first_name"], user["middle_name"], user["last_name"]]
        .where((e) => e != null && e.toString().isNotEmpty).join(" ");
    final initials    = (user["first_name"] ?? "U")[0].toUpperCase();
    final nationality = user["nationality"] ?? "";

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: _primary,
            elevation: 0,
            leading: const SizedBox.shrink(),
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F3D2E), Color(0xFF1A6B3C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _white.withOpacity(.15),
                          border: Border.all(color: _white.withOpacity(.4), width: 2.5),
                        ),
                        child: Center(child: Text(initials,
                            style: GoogleFonts.urbanist(
                                fontSize: 34, fontWeight: FontWeight.w800, color: _white))),
                      ),
                      const SizedBox(height: 14),
                      Text(fullName, style: GoogleFonts.urbanist(
                          fontSize: 22, fontWeight: FontWeight.w800, color: _white)),
                      const SizedBox(height: 4),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.public_rounded, color: Colors.white54, size: 14),
                        const SizedBox(width: 4),
                        Text(nationality, style: GoogleFonts.urbanist(
                            fontSize: 13, color: Colors.white60, fontWeight: FontWeight.w500)),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                Text('Personal Information', style: GoogleFonts.urbanist(
                    fontSize: 15, fontWeight: FontWeight.w800, color: _dark, letterSpacing: .3)),
                const SizedBox(height: 12),
                _InfoCard(tiles: [
                  _InfoTile(icon: Icons.person_rounded,    label: 'Gender',        value: user["gender"]),
                  _InfoTile(icon: Icons.cake_rounded,      label: 'Date of Birth', value: _formatDob(user["dob"])),
                  _InfoTile(icon: Icons.bloodtype_rounded, label: 'Blood Group',   value: user["blood_group"], isLast: true),
                ]),

                const SizedBox(height: 24),

                Text('Contact Information', style: GoogleFonts.urbanist(
                    fontSize: 15, fontWeight: FontWeight.w800, color: _dark, letterSpacing: .3)),
                const SizedBox(height: 12),
                _InfoCard(tiles: [
                  _InfoTile(icon: Icons.email_rounded,       label: 'Email',             value: user["email"]),
                  _InfoTile(icon: Icons.phone_rounded,       label: 'Phone',             value: user["phone"]),
                  _InfoTile(icon: Icons.emergency_rounded,   label: 'Emergency Contact', value: user["emergency_contact"],
                      valueColor: const Color(0xFFE53935)),
                  _InfoTile(icon: Icons.location_on_rounded, label: 'Address',           value: user["address"], isLast: true),
                ]),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEEF5F1),
                      foregroundColor: _primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: _primary.withOpacity(.3)),
                      ),
                    ),
                    onPressed: _openEdit,
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: Text('Edit Profile',
                        style: GoogleFonts.urbanist(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFEBEE),
                      foregroundColor: const Color(0xFFE53935),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: const Color(0xFFE53935).withOpacity(.3)),
                      ),
                    ),
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: Text('Log Out',
                        style: GoogleFonts.urbanist(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfilePage extends StatefulWidget {
  const _EditProfilePage();

  @override
  State<_EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<_EditProfilePage> {
  final _phoneCtrl     = TextEditingController();
  final _emergencyCtrl = TextEditingController();
  final _addressCtrl   = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user          = UserSession.currentUser;
    _phoneCtrl.text     = user["phone"]             ?? '';
    _emergencyCtrl.text = user["emergency_contact"] ?? '';
    _addressCtrl.text   = user["address"]           ?? '';
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emergencyCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    UserSession.currentUser["phone"]             = _phoneCtrl.text.trim();
    UserSession.currentUser["emergency_contact"] = _emergencyCtrl.text.trim();
    UserSession.currentUser["address"]           = _addressCtrl.text.trim();
    try {
      await http.patch(
        Uri.parse('$baseUrl/profile/${UserSession.email}'), // ← uses baseUrl
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone':             _phoneCtrl.text.trim(),
          'emergency_contact': _emergencyCtrl.text.trim(),
          'address':           _addressCtrl.text.trim(),
        }),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = UserSession.currentUser;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFFEEF5F1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_rounded, color: _primary, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile',
            style: GoogleFonts.urbanist(fontSize: 18, fontWeight: FontWeight.w800, color: _dark)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF5F1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _primary.withOpacity(.15)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, color: _primary, size: 16),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'You can update your phone, emergency contact and address.',
                style: GoogleFonts.urbanist(fontSize: 12, color: _primary, fontWeight: FontWeight.w500),
              )),
            ]),
          ),

          const SizedBox(height: 24),

          _label('CANNOT BE CHANGED'),
          const SizedBox(height: 8),
          _readOnly(Icons.person_rounded,  'Full Name', UserSession.fullName),
          _readOnly(Icons.email_rounded,   'Email',     user["email"] ?? ''),
          _readOnly(Icons.cake_rounded,    'DOB',       user["dob"]   ?? ''),

          const SizedBox(height: 24),

          _label('EDITABLE'),
          const SizedBox(height: 10),
          _editField('Phone Number',       _phoneCtrl,     Icons.phone_rounded,       'e.g. +91 9876543210'),
          const SizedBox(height: 14),
          _editField('Emergency Contact',  _emergencyCtrl, Icons.emergency_rounded,   'e.g. +91 9876543210'),
          const SizedBox(height: 14),
          _editField('Address',            _addressCtrl,   Icons.location_on_rounded, 'Your address', maxLines: 2),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Save Changes',
                      style: GoogleFonts.urbanist(fontSize: 15, fontWeight: FontWeight.w700, color: _white)),
            ),
          ),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: GoogleFonts.urbanist(fontSize: 11, fontWeight: FontWeight.w700, color: _light, letterSpacing: 0.8));

  Widget _readOnly(IconData icon, String label, String value) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Icon(icon, color: _light, size: 18), const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.urbanist(fontSize: 11, color: _light, fontWeight: FontWeight.w600)),
        Text(value, style: GoogleFonts.urbanist(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
      ]),
    ]),
  );

  Widget _editField(String label, TextEditingController ctrl, IconData icon, String hint, {int maxLines = 1}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.urbanist(fontSize: 13, fontWeight: FontWeight.w700, color: _dark)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl, maxLines: maxLines,
          style: GoogleFonts.urbanist(fontSize: 15, color: _dark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.urbanist(color: _light, fontSize: 14),
            prefixIcon: Icon(icon, color: _primary, size: 18),
            filled: true, fillColor: _white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _primary.withOpacity(.4)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ]);
}

class _InfoCard extends StatelessWidget {
  final List<_InfoTile> tiles;
  const _InfoCard({required this.tiles});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Column(children: tiles),
      );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic value;
  final bool isLast;
  final Color? valueColor;

  const _InfoTile({required this.icon, required this.label,
      this.value, this.isLast = false, this.valueColor});

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(color: const Color(0xFFEEF5F1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: _primary, size: 18)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: GoogleFonts.urbanist(fontSize: 12, color: _light, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value?.toString() ?? '—',
                  style: GoogleFonts.urbanist(fontSize: 15, fontWeight: FontWeight.w600, color: valueColor ?? _dark)),
            ])),
          ]),
        ),
        if (!isLast) Divider(height: 1, indent: 68, endIndent: 18, color: const Color(0xFFF0F4F2)),
      ]);
}