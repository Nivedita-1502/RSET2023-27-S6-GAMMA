import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../sos/sos_page.dart';
import '../profile/profile_page.dart';
import 'home_page.dart';
import '../../drawer/app_drawer.dart';
import '../../services/token_service.dart';
import '../../services/rating_service.dart'; // ← NEW

const _primary = Color(0xFF1A6B3C);

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int index = 0;

  final pages = [
    const HomePage(),
    const SOSPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check token expiry
      TokenService.checkAndLogoutIfExpired(context);
      // Check if rating prompt should show
      RatingService.checkAndShow(context); // ← NEW
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (index != 0) {
          setState(() => index = 0);
          return false;
        }
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text('Exit App?',
                style: GoogleFonts.urbanist(
                    fontWeight: FontWeight.w800, fontSize: 17)),
            content: Text('Are you sure you want to exit TravelShield?',
                style: GoogleFonts.urbanist(fontSize: 14)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel',
                    style: GoogleFonts.urbanist(
                        color: Colors.grey, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text('Exit',
                    style: GoogleFonts.urbanist(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        drawer: const AppDrawer(),
        body: pages[index],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    selected: index == 0,
                    onTap: () => setState(() => index = 0),
                  ),
                  _NavItem(
                    icon: Icons.warning_amber_rounded,
                    label: 'SOS',
                    selected: index == 1,
                    onTap: () => setState(() => index = 1),
                    isAlert: true,
                  ),
                  _NavItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    selected: index == 2,
                    onTap: () => setState(() => index = 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool isAlert;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAlert
        ? const Color(0xFFE53935)
        : selected
            ? _primary
            : const Color(0xFF8FA89B);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (isAlert
                  ? const Color(0xFFFFEBEE)
                  : const Color(0xFFE8F5EE))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 3),
            Text(label,
                style: GoogleFonts.urbanist(
                  color: color,
                  fontSize: 11,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }
}