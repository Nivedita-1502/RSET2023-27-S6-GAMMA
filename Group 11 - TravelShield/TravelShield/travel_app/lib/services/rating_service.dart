// lib/services/rating_service.dart
//
// Tracks app open count and shows rating prompt after 5 opens.
// Uses flutter_secure_storage (already in pubspec.yaml).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _primary = Color(0xFF1A6B3C);
const _dark    = Color(0xFF0D1B12);
const _light   = Color(0xFF9EB5A8);
const _white   = Colors.white;

class RatingService {
  static const _storage        = FlutterSecureStorage();
  static const _openCountKey   = 'app_open_count';
  static const _ratingDoneKey  = 'rating_done';
  static const _remindAfterKey = 'rating_remind_after';
  static const _promptAfter    = 5; // show after 5 opens

  // ── Call this on every app open (in MainNavigation initState) ─────────────
  static Future<void> checkAndShow(BuildContext context) async {
    // Never show if user already rated or said never
    final done = await _storage.read(key: _ratingDoneKey);
    if (done == 'true') return;

    // Increment open count
    final countStr = await _storage.read(key: _openCountKey) ?? '0';
    final count    = int.parse(countStr) + 1;
    await _storage.write(key: _openCountKey, value: count.toString());

    // Check if we should remind after X opens
    final remindAfterStr = await _storage.read(key: _remindAfterKey);
    if (remindAfterStr != null) {
      final remindAfter = int.parse(remindAfterStr);
      if (count < remindAfter) return;
    }

    // Show prompt after 5 opens
    if (count >= _promptAfter) {
      if (!context.mounted) return;
      await Future.delayed(
          const Duration(seconds: 2)); // slight delay after page loads
      if (!context.mounted) return;
      _showRatingDialog(context);
    }
  }

  // ── Never show again ───────────────────────────────────────────────────────
  static Future<void> _markDone() async {
    await _storage.write(key: _ratingDoneKey, value: 'true');
  }

  // ── Remind after 3 more opens ──────────────────────────────────────────────
  static Future<void> _remindLater() async {
    final countStr = await _storage.read(key: _openCountKey) ?? '0';
    final count    = int.parse(countStr);
    await _storage.write(
        key: _remindAfterKey, value: (count + 3).toString());
  }

  // ── Show rating dialog ─────────────────────────────────────────────────────
  static void _showRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RatingDialog(
        onRateNow: () async {
          await _markDone();
          Navigator.pop(ctx);
          if (!ctx.mounted) return;
          _showThankYouDialog(ctx);
        },
        onMaybeLater: () async {
          await _remindLater();
          Navigator.pop(ctx);
        },
        onNever: () async {
          await _markDone();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  // ── Thank you dialog after rating ─────────────────────────────────────────
  static void _showThankYouDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: _white,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Green checkmark circle
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primary.withOpacity(.1),
                  border: Border.all(
                      color: _primary.withOpacity(.3), width: 2),
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: _primary, size: 34),
              ),
              const SizedBox(height: 20),
              Text('Thank You! 🙏',
                  style: GoogleFonts.urbanist(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _dark)),
              const SizedBox(height: 10),
              Text(
                'Your feedback means a lot to us!\nWe\'re constantly working to make TravelShield better for every Kerala traveller.',
                textAlign: TextAlign.center,
                style: GoogleFonts.urbanist(
                    fontSize: 13,
                    color: _light,
                    fontWeight: FontWeight.w500,
                    height: 1.6),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Continue Exploring 🌿',
                      style: GoogleFonts.urbanist(
                          color: _white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Rating Dialog Widget ──────────────────────────────────────────────────────

class _RatingDialog extends StatefulWidget {
  final VoidCallback onRateNow;
  final VoidCallback onMaybeLater;
  final VoidCallback onNever;

  const _RatingDialog({
    required this.onRateNow,
    required this.onMaybeLater,
    required this.onNever,
  });

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _selectedStars = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: _white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // App icon placeholder
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A1F14), Color(0xFF1A6B3C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withOpacity(.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.travel_explore,
                  color: _white, size: 34),
            ),

            const SizedBox(height: 16),

            Text('Enjoying TravelShield?',
                style: GoogleFonts.urbanist(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _dark)),

            const SizedBox(height: 8),

            Text(
              'Your experience matters to us.\nTap a star to rate your experience!',
              textAlign: TextAlign.center,
              style: GoogleFonts.urbanist(
                  fontSize: 13,
                  color: _light,
                  fontWeight: FontWeight.w500,
                  height: 1.5),
            ),

            const SizedBox(height: 20),

            // Star rating row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starred = i < _selectedStars;
                return GestureDetector(
                  onTap: () => setState(() => _selectedStars = i + 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      starred ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: starred
                          ? const Color(0xFFFFC107)
                          : Colors.grey.shade300,
                      size: starred ? 42 : 36,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 8),

            // Star label
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _selectedStars == 0 ? 'Tap a star to rate'
                  : _selectedStars == 1 ? 'Poor 😕'
                  : _selectedStars == 2 ? 'Fair 🙂'
                  : _selectedStars == 3 ? 'Good 😊'
                  : _selectedStars == 4 ? 'Great 😄'
                  : 'Excellent! 🤩',
                key: ValueKey(_selectedStars),
                style: GoogleFonts.urbanist(
                    fontSize: 13,
                    color: _selectedStars >= 4
                        ? _primary
                        : _selectedStars > 0
                            ? Colors.orange
                            : _light,
                    fontWeight: FontWeight.w700),
              ),
            ),

            const SizedBox(height: 20),

            // Rate Now button (enabled only after star selection)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedStars > 0
                      ? _primary
                      : Colors.grey.shade200,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _selectedStars > 0 ? widget.onRateNow : null,
                child: Text('Rate Now ⭐',
                    style: GoogleFonts.urbanist(
                        color: _selectedStars > 0 ? _white : Colors.grey,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            ),

            const SizedBox(height: 10),

            // Maybe Later + Never row
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: widget.onMaybeLater,
                    child: Text('Maybe Later',
                        style: GoogleFonts.urbanist(
                            color: _light,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: widget.onNever,
                    child: Text('Never',
                        style: GoogleFonts.urbanist(
                            color: Colors.red.shade300,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}