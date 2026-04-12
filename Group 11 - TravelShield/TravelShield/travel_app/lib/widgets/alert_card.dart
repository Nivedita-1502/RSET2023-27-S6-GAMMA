// lib/widgets/alert_card.dart

import 'package:flutter/material.dart';
import '../services/news_service.dart';

class AlertCard extends StatelessWidget {
  final DistrictAlertData data;

  const AlertCard({super.key, required this.data});

  _AlertStyle get _style {
    switch (data.alertLevel) {
      case AlertLevel.high:
        return _AlertStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          badgeColor: const Color(0xFFFFCDD2),
          badgeText: '🔴 HIGH ALERT',
          badgeTextColor: const Color(0xFFB71C1C),
          icon: Icons.warning_rounded,
          iconColor: Colors.white,
        );
      case AlertLevel.medium:
        return _AlertStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFFE65100), Color(0xFFF57C00)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          badgeColor: const Color(0xFFFFE0B2),
          badgeText: '🟠 MODERATE ALERT',
          badgeTextColor: const Color(0xFFE65100),
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.white,
        );
      case AlertLevel.low:
        return _AlertStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFFF9A825), Color(0xFFFDD835)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          badgeColor: const Color(0xFFFFF9C4),
          badgeText: '🟡 LOW ALERT',
          badgeTextColor: const Color(0xFFF57F17),
          icon: Icons.info_outline_rounded,
          iconColor: Colors.white,
        );
      case AlertLevel.none:
      default:
        return _AlertStyle(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          badgeColor: const Color(0xFFC8E6C9),
          badgeText: '✅ ALL CLEAR',
          badgeTextColor: const Color(0xFF1B5E20),
          icon: Icons.check_circle_outline_rounded,
          iconColor: Colors.white,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: s.gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: s.gradient.colors.first.withOpacity(0.35),
            blurRadius: 16, offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              top: -30, right: -30,
              child: Container(
                width: 130, height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _Badge(text: s.badgeText, color: s.badgeColor, textColor: s.badgeTextColor),
                      Icon(s.icon, color: s.iconColor, size: 28),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(data.district,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 22,
                          fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text('Kerala, India',
                      style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
                  const SizedBox(height: 14),
                  Divider(color: Colors.white.withOpacity(0.25), height: 1),
                  const SizedBox(height: 14),
                  Text(data.alertSummary,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14.5, height: 1.55)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 13, color: Colors.white.withOpacity(0.6)),
                      const SizedBox(width: 4),
                      Text('Updated: ${_formatTime(data.fetchedAt)}',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11.5)),
                      const Spacer(),
                      Text('${data.newsArticles.length} sources',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11.5)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2,'0')}:${local.minute.toString().padLeft(2,'0')}, ${local.day}/${local.month}/${local.year}';
  }
}

class _AlertStyle {
  final LinearGradient gradient;
  final Color badgeColor;
  final String badgeText;
  final Color badgeTextColor;
  final IconData icon;
  final Color iconColor;
  const _AlertStyle({
    required this.gradient, required this.badgeColor,
    required this.badgeText, required this.badgeTextColor,
    required this.icon, required this.iconColor,
  });
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  const _Badge({required this.text, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: TextStyle(
              color: textColor, fontSize: 11,
              fontWeight: FontWeight.w700, letterSpacing: 0.3)),
    );
  }
}