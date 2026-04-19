import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:math';
import '../../services/user_session.dart';
import '../../services/api_config.dart'; // ← NEW

const _bg          = Color(0xFFF5F6F8);
const _white       = Colors.white;
const _primary     = Color(0xFF1A6B3C);
const _accent      = Color(0xFF25A05B);
const _dark        = Color(0xFF0D1B12);
const _light       = Color(0xFF9EB5A8);
const _cardBg      = Color(0xFFEEF5F1);
const _cardPolice  = Color(0xFF1A6B3C);
const _cardHelpline= Color(0xFF0F4D6B);
const _cardHospital= Color(0xFF1B5E8C);
const _cardSOS     = Color(0xFFB83232);

class SOSPage extends StatefulWidget {
  const SOSPage({super.key});
  @override
  State<SOSPage> createState() => _SOSPageState();
}

class _Place {
  final String name, address, phone, openingHours, operator, website, facilityType;
  final double lat, lon, distance;
  _Place({
    required this.name, required this.lat, required this.lon, required this.distance,
    this.address = '', this.phone = '', this.openingHours = '',
    this.operator = '', this.website = '', this.facilityType = '',
  });
}

class _SOSPageState extends State<SOSPage> with TickerProviderStateMixin {
  String    _locationText  = 'Detecting your location...';
  String    _locationBadge = 'LOCATING';
  Color     _badgeColor    = _accent;
  Position? _cachedPosition;
  DateTime? _positionTimestamp; // ← NEW: tracks when location was last fetched

  List<_Place> _policeCache   = [];
  List<_Place> _hospitalCache = [];
  bool _policeFetched   = false;
  bool _hospitalFetched = false;

  late AnimationController _pulseController;
  late Animation<double>   _pulseAnim;

  final List<Map<String, dynamic>> _helplines = [
    {'category': 'Universal'},
    {'name': 'National Emergency',    'number': '112',          'desc': 'Police, Fire & Ambulance combined',    'icon': Icons.crisis_alert,        'color': _cardSOS},
    {'category': 'Medical'},
    {'name': 'Ambulance',             'number': '108',          'desc': 'Free emergency ambulance service',     'icon': Icons.local_hospital,      'color': _cardHospital},
    {'name': 'Medical Helpline',      'number': '104',          'desc': 'Health advice & medical guidance',     'icon': Icons.medical_services,    'color': _cardHelpline},
    {'name': 'Blood Bank',            'number': '1910',         'desc': 'Emergency blood requirement',          'icon': Icons.water_drop,          'color': _cardSOS},
    {'name': 'AYUSH Helpline',        'number': '14429',        'desc': 'Ayurveda, Yoga & natural medicine',    'icon': Icons.spa,                 'color': _primary},
    {'category': 'Police & Safety'},
    {'name': 'Police',                'number': '100',          'desc': 'Local police emergency',               'icon': Icons.local_police,        'color': _cardPolice},
    {'name': 'Fire & Rescue',         'number': '101',          'desc': 'Fire brigade & rescue services',       'icon': Icons.local_fire_department,'color': _cardSOS},
    {'name': 'Disaster Management',   'number': '108',          'desc': 'Natural disasters & calamities',       'icon': Icons.flood,               'color': _cardHelpline},
    {'name': 'Road Accident',         'number': '1073',         'desc': 'Highway & road accident helpline',     'icon': Icons.car_crash,           'color': Color(0xFF6A3A8C)},
    {'category': 'Women & Children'},
    {'name': 'Women Helpline',        'number': '1091',         'desc': 'Women in distress & emergencies',      'icon': Icons.female,              'color': Color(0xFFAD1457)},
    {'name': 'Women Helpline (NCW)',  'number': '181',          'desc': 'National Commission for Women',        'icon': Icons.woman,               'color': Color(0xFFAD1457)},
    {'name': 'Child Helpline',        'number': '1098',         'desc': 'Children in need of care',             'icon': Icons.child_care,          'color': _cardHospital},
    {'name': 'Missing Child & Women', 'number': '1094',         'desc': 'Report missing persons',               'icon': Icons.search,              'color': _cardSOS},
    {'category': 'Mental Health & Support'},
    {'name': 'Vandrevala Foundation', 'number': '1860-2662-345','desc': '24/7 mental health helpline',          'icon': Icons.psychology,          'color': Color(0xFF4A1580)},
    {'name': 'iCall',                 'number': '9152987821',   'desc': 'Psychosocial support helpline',        'icon': Icons.favorite,            'color': Color(0xFFAD1457)},
    {'category': 'Senior Citizens'},
    {'name': 'Elder Helpline',        'number': '14567',        'desc': 'Support for senior citizens',          'icon': Icons.elderly,             'color': Color(0xFF00695C)},
    {'category': 'Other'},
    {'name': 'Railway Helpline',      'number': '139',          'desc': 'Railway emergency & enquiry',          'icon': Icons.train,               'color': _cardHospital},
    {'name': 'Anti Poison',           'number': '1066',         'desc': 'Poison control & drug overdose',       'icon': Icons.warning_amber,       'color': _cardSOS},
    {'name': 'Cyber Crime',           'number': '1930',         'desc': 'Online fraud & cybercrime',            'icon': Icons.security,            'color': Color(0xFF4A1580)},
    {'name': 'Tourist Helpline',      'number': '1363',         'desc': 'Help for tourists in India',           'icon': Icons.beach_access,        'color': Color(0xFF00695C)},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.8).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
    _prefetchAll();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Check if cached position is fresh (under 3 minutes) ──────────────────
  bool _isFreshPosition() {
    if (_cachedPosition == null || _positionTimestamp == null) return false;
    final age = DateTime.now().difference(_positionTimestamp!);
    return age.inMinutes < 3;
  }

  // ── Prefetch location + nearby places ────────────────────────────────────
  Future<void> _prefetchAll() async {
    final pos = await _getLocation();
    if (pos == null) return;
    await Future.wait([
      _fetchOverpass(pos.latitude, pos.longitude,
              [['amenity', 'police']], 'police')
          .then((r) {
        if (mounted) setState(() { _policeCache = r; _policeFetched = true; });
      }).catchError((_) {
        if (mounted) setState(() { _policeFetched = true; });
      }),
      _fetchOverpass(pos.latitude, pos.longitude, [
        ['amenity', 'hospital'], ['amenity', 'clinic'],
        ['healthcare', 'hospital'], ['healthcare', 'clinic'],
      ], 'hospital')
          .then((r) {
        if (mounted) setState(() { _hospitalCache = r; _hospitalFetched = true; });
      }).catchError((_) {
        if (mounted) setState(() { _hospitalFetched = true; });
      }),
    ]);
  }

  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  Future<List<_Place>> _fetchOverpass(double userLat, double userLon,
      List<List<String>> tagPairs, String type) async {
    const radius = 10000, limit = 20;
    final filters = tagPairs.map((kv) =>
        'node["${kv[0]}"="${kv[1]}"](around:$radius,$userLat,$userLon);'
        'way["${kv[0]}"="${kv[1]}"](around:$radius,$userLat,$userLon);').join('');
    final query = '[out:json][timeout:15];($filters);out center tags $limit;';
    final res = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'), body: query);
    if (res.statusCode != 200) throw Exception('Could not reach map server.');
    final data   = jsonDecode(res.body);
    final places = <_Place>[], seen = <String>{};
    for (final el in data['elements']) {
      final t    = el['tags'] ?? {};
      final name = t['name:en'] ?? t['name'] ?? t['name:ml'] ?? 'Unknown';
      final key  = name.toString().toLowerCase().trim();
      if (seen.contains(key)) continue;
      seen.add(key);
      double? elLat, elLon;
      if (el['type'] == 'node') {
        elLat = el['lat']?.toDouble(); elLon = el['lon']?.toDouble();
      } else if (el['center'] != null) {
        elLat = el['center']['lat']?.toDouble();
        elLon = el['center']['lon']?.toDouble();
      }
      if (elLat == null || elLon == null) continue;
      final dist = _distanceMeters(userLat, userLon, elLat, elLon);
      final addr = [
        t['addr:housename'], t['addr:housenumber'], t['addr:street'],
        t['addr:suburb'] ?? t['addr:neighbourhood'],
        t['addr:city']   ?? t['addr:town'],
        t['addr:state'],   t['addr:postcode'],
      ].where((e) => e != null && e.toString().isNotEmpty).join(', ');
      places.add(_Place(
        name: name.toString(), lat: elLat, lon: elLon, distance: dist,
        address: addr,
        phone:        t['phone']           ?? t['contact:phone']   ?? '',
        openingHours: t['opening_hours']   ?? '',
        operator:     t['operator']        ?? '',
        website:      t['website']         ?? t['contact:website'] ?? '',
        facilityType: t['amenity']         ?? t['healthcare']      ?? '',
      ));
    }
    places.sort((a, b) => a.distance.compareTo(b.distance));
    return places;
  }

  // ── IMPROVED _getLocation ─────────────────────────────────────────────────
  Future<Position?> _getLocation({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _locationText  = 'Detecting your location...';
        _locationBadge = 'LOCATING';
        _badgeColor    = _accent;
      });
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      _setLocError('Location services disabled. Please enable GPS.');
      return null;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        _setLocError('Permission denied.');
        return null;
      }
    }
    if (perm == LocationPermission.deniedForever) {
      _setLocError('Permission permanently denied.');
      await Geolocator.openAppSettings();
      return null;
    }

    try {
      // Step 1: Show last known position instantly while GPS warms up
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && !silent) {
        setState(() {
          _cachedPosition    = lastKnown;
          _positionTimestamp = DateTime.now();
          _locationText  =
              '${lastKnown.latitude.toStringAsFixed(5)}, '
              '${lastKnown.longitude.toStringAsFixed(5)} (last known)';
          _locationBadge = 'UPDATING';
          _badgeColor    = Colors.orange;
        });
      }

      // Step 2: Get accurate position with timeout
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          if (lastKnown != null) return lastKnown;
          throw Exception('Location timed out.');
        },
      );

      // Step 3: Retry if accuracy is poor (>50m)
      Position finalPos = pos;
      if (pos.accuracy > 50) {
        try {
          final retry = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
          ).timeout(const Duration(seconds: 10));
          if (retry.accuracy < pos.accuracy) finalPos = retry;
        } catch (_) {}
      }

      if (!mounted) return null;
      setState(() {
        _cachedPosition    = finalPos;
        _positionTimestamp = DateTime.now();
        _locationText  =
            '${finalPos.latitude.toStringAsFixed(5)}, '
            '${finalPos.longitude.toStringAsFixed(5)} '
            '(±${finalPos.accuracy.toStringAsFixed(0)}m)';
        _locationBadge = 'LIVE';
        _badgeColor    = _accent;
      });
      return finalPos;

    } catch (e) {
      // Fallback to cached position if GPS completely fails
      if (_cachedPosition != null) {
        if (!silent && mounted) {
          setState(() {
            _locationBadge = 'CACHED';
            _badgeColor    = Colors.orange;
            _locationText  =
                '${_cachedPosition!.latitude.toStringAsFixed(5)}, '
                '${_cachedPosition!.longitude.toStringAsFixed(5)} (cached)';
          });
        }
        return _cachedPosition;
      }
      _setLocError('Could not get location. Please try again.');
      return null;
    }
  }

  void _setLocError(String msg) {
    if (!mounted) return;
    setState(() {
      _locationText  = 'Location error — allow access';
      _locationBadge = 'ERROR';
      _badgeColor    = _cardSOS;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: _cardSOS));
  }

  Future<void> _makeCall(String number) async {
    if (kIsWeb) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: _white,
          title: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.phone_rounded, color: _primary, size: 18)),
            const SizedBox(width: 10),
            Text('Emergency Number',
                style: GoogleFonts.urbanist(
                    fontWeight: FontWeight.w800, color: _dark, fontSize: 16)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Dial this number on your phone:',
                style: GoogleFonts.urbanist(
                    color: _light, fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _primary.withOpacity(0.2))),
              child: Text(number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.urbanist(
                      fontSize: 32, fontWeight: FontWeight.w800,
                      color: _primary, letterSpacing: 3))),
            const SizedBox(height: 10),
            Text('On mobile, calls open directly in the dialer.',
                textAlign: TextAlign.center,
                style: GoogleFonts.urbanist(
                    color: _light, fontSize: 11, fontWeight: FontWeight.w500)),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close',
                  style: GoogleFonts.urbanist(
                      color: _light, fontWeight: FontWeight.w600))),
          ],
        ),
      );
      return;
    }
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _showNearby(String type) {
    final isPolice = type == 'police';
    final color    = isPolice ? _cardPolice : _cardHospital;
    final icon     = isPolice ? Icons.local_police : Icons.local_hospital;
    final title    = isPolice ? 'Nearby Police Stations' : 'Nearby Hospitals';
    final places   = isPolice ? _policeCache : _hospitalCache;
    final fetched  = isPolice ? _policeFetched : _hospitalFetched;
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: _white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.85,
        builder: (_, controller) => Column(children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2))),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: color,
            child: Row(children: [
              Icon(icon, color: _white), const SizedBox(width: 10),
              Text(title, style: GoogleFonts.urbanist(
                  color: _white, fontWeight: FontWeight.w700, fontSize: 16)),
            ])),
          Expanded(child: !fetched
            ? Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: color),
                  const SizedBox(height: 12),
                  Text('Fetching nearby places...',
                      style: GoogleFonts.urbanist(color: _light)),
                ]))
            : places.isEmpty
              ? Center(child: Text('Nothing found within 10 km.',
                  style: GoogleFonts.urbanist(color: _light)))
              : ListView.builder(
                  controller: controller,
                  itemCount: places.length,
                  itemBuilder: (_, i) =>
                      _placeListItem(places[i], i, color, isPolice))),
        ]),
      ),
    );
  }

  Widget _placeListItem(_Place p, int i, Color numColor, bool isPolice) {
    final ftLower = p.facilityType.toLowerCase();
    String badge = '';
    if (ftLower == 'hospital') badge = 'Hospital';
    else if (ftLower == 'clinic') badge = 'Clinic';
    else if (ftLower == 'police') badge = 'Police';
    return InkWell(
      onTap: () => _showPlaceDetail(p, isPolice),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: numColor.withOpacity(0.1)),
            child: Center(child: Text('${i + 1}',
                style: TextStyle(
                    color: numColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)))),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(child: Text(p.name,
                      style: GoogleFonts.urbanist(
                          fontWeight: FontWeight.w700,
                          fontSize: 14, color: _dark),
                      overflow: TextOverflow.ellipsis)),
                  if (badge.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: numColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: numColor.withOpacity(0.3))),
                      child: Text(badge, style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: numColor))),
                  ],
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.navigation_rounded, color: _accent, size: 10),
                  const SizedBox(width: 4),
                  Text('${(p.distance / 1000).toStringAsFixed(2)} km away',
                      style: GoogleFonts.urbanist(
                          fontSize: 12, color: _light,
                          fontWeight: FontWeight.w500)),
                  if (p.openingHours.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Icon(Icons.access_time, color: _light, size: 10),
                    const SizedBox(width: 4),
                    Flexible(child: Text(p.openingHours,
                        style: GoogleFonts.urbanist(
                            fontSize: 11, color: _light),
                        overflow: TextOverflow.ellipsis)),
                  ],
                ]),
                if (p.address.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.location_pin, color: _primary, size: 10),
                    const SizedBox(width: 4),
                    Flexible(child: Text(p.address,
                        style: GoogleFonts.urbanist(
                            fontSize: 11, color: _light),
                        overflow: TextOverflow.ellipsis)),
                  ]),
                ],
                if (p.phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.phone, color: _accent, size: 10),
                    const SizedBox(width: 4),
                    Text(p.phone, style: GoogleFonts.urbanist(
                        fontSize: 11, color: _light)),
                  ]),
                ],
              ])),
          Icon(Icons.chevron_right_rounded, color: _light, size: 18),
        ]),
      ),
    );
  }

  void _showPlaceDetail(_Place p, bool isPolice) {
    final color     = isPolice ? _cardPolice : _cardHospital;
    final typeLabel = isPolice ? 'Police Station' : 'Hospital';
    final icon      = isPolice ? Icons.local_police : Icons.local_hospital;
    final distKm    = (p.distance / 1000).toStringAsFixed(2);
    final dirUrl    =
        'https://www.google.com/maps/dir/?api=1&destination=${p.lat},${p.lon}&travelmode=driving';
    final mapsUrl   = 'https://www.google.com/maps?q=${p.lat},${p.lon}';
    final callNum   = p.phone.isNotEmpty ? p.phone : (isPolice ? '100' : '108');
    final callLabel = p.phone.isNotEmpty
        ? 'Call Now'
        : (isPolice ? 'Call Police (100)' : 'Call Ambulance (108)');
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: _white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.25))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(typeLabel, style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 12)),
            ])),
          const SizedBox(height: 10),
          Text(p.name, style: GoogleFonts.urbanist(
              fontSize: 18, fontWeight: FontWeight.w800, color: _dark)),
          const Divider(height: 24),
          _sheetRow(Icons.navigation_rounded, _accent, 'Distance', '$distKm km away'),
          if (p.address.isNotEmpty)
            _sheetRow(Icons.location_pin, _primary, 'Address', p.address),
          if (p.operator.isNotEmpty)
            _sheetRow(Icons.business_rounded, const Color(0xFF4A1580),
                'Operator', p.operator),
          if (p.phone.isNotEmpty)
            _sheetRow(Icons.phone_rounded, _accent, 'Phone', p.phone,
                link: 'tel:${p.phone}'),
          if (p.openingHours.isNotEmpty)
            _sheetRow(Icons.access_time, _primary, 'Hours', p.openingHours),
          if (p.website.isNotEmpty)
            _sheetRow(Icons.language_rounded, const Color(0xFF00695C),
                'Website', p.website, link: p.website),
          const Divider(height: 24),
          _actionBtn('Get Directions', Icons.turn_right_rounded, _primary,
              () => launchUrl(Uri.parse(dirUrl),
                  mode: LaunchMode.externalApplication)),
          const SizedBox(height: 10),
          _actionBtn(callLabel, Icons.phone_rounded, _accent,
              () => _makeCall(callNum)),
          const SizedBox(height: 10),
          _actionBtn('Open in Google Maps', Icons.map_rounded,
              const Color(0xFF34a853),
              () => launchUrl(Uri.parse(mapsUrl),
                  mode: LaunchMode.externalApplication)),
        ]),
      ),
    );
  }

  Widget _sheetRow(IconData icon, Color color, String label, String value,
      {String? link}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: color, size: 16)),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.urbanist(
                  fontSize: 11, color: _light, fontWeight: FontWeight.w600)),
              GestureDetector(
                onTap: link != null
                    ? () => launchUrl(Uri.parse(link),
                        mode: LaunchMode.externalApplication)
                    : null,
                child: Text(value, style: GoogleFonts.urbanist(
                    fontSize: 14,
                    color: link != null ? _primary : _dark,
                    decoration: link != null
                        ? TextDecoration.underline
                        : TextDecoration.none))),
            ])),
      ]),
    );
  }

  Widget _actionBtn(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: _white, size: 18),
        label: Text(label, style: GoogleFonts.urbanist(
            color: _white, fontWeight: FontWeight.w700, fontSize: 14)),
        style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0)),
    );
  }

  // ── IMPROVED _sendSOS ─────────────────────────────────────────────────────
  Future<void> _sendSOS() async {
    // Use fresh cached position or fetch new one
    final pos = _isFreshPosition() ? _cachedPosition : await _getLocation();
    if (pos == null) return;

    final lat = pos.latitude;
    final lon = pos.longitude;
    final acc = pos.accuracy;

    if (!mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _white,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: _primary, strokeWidth: 3),
            const SizedBox(height: 20),
            Text('Sending SOS...', style: GoogleFonts.urbanist(
                fontSize: 16, fontWeight: FontWeight.w800, color: _dark)),
            const SizedBox(height: 6),
            Text('Getting your location name', style: GoogleFonts.urbanist(
                fontSize: 12, color: _light, fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );

    String shortName   = '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}';
    String fullAddress = '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}';
    String mapsUrl     = 'https://www.google.com/maps?q=$lat,$lon';

    try {
      // Try backend first for structured address
      final res = await http.post(
        Uri.parse('$baseUrl/send_location'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'latitude': lat, 'longitude': lon, 'accuracy': acc}),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        shortName   = data['place']        ?? shortName;
        fullAddress = data['full_address'] ?? fullAddress;
      }
    } catch (_) {
      // Backend unreachable — fallback to Nominatim directly
      try {
        final nomRes = await http.get(
          Uri.parse(
              'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon'
              '&zoom=16&addressdetails=1&format=json&accept-language=en'),
          headers: {'User-Agent': 'TravelShield-SOS-App'},
        ).timeout(const Duration(seconds: 8));

        if (nomRes.statusCode == 200) {
          final d    = jsonDecode(nomRes.body);
          final addr = d['address'] as Map<String, dynamic>? ?? {};
          shortName  = addr['road']   ?? addr['suburb'] ??
                       addr['city']   ?? d['name']      ?? shortName;
          fullAddress = d['display_name'] ?? fullAddress;
        }
      } catch (_) {}
    }

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    // Accuracy badge
    final accColor = acc <= 10 ? _accent : acc <= 30 ? _primary : _cardSOS;
    final accLabel = acc <= 10
        ? 'High accuracy'
        : acc <= 30 ? 'Medium accuracy' : 'Low accuracy';
    final accIcon  = acc <= 10
        ? Icons.satellite_alt
        : acc <= 30 ? Icons.signal_cellular_alt : Icons.warning_amber;

    // WhatsApp message
    final emergencyContact =
        UserSession.currentUser['emergency_contact'] ?? '';
    final cleanNumber = emergencyContact
        .replaceAll(RegExp(r'[\s\-\(\)]'), '')
        .replaceAll('+', '');
    final waMessage = Uri.encodeComponent(
      '🆘 EMERGENCY SOS!\n\n'
      'I need help. My current location:\n'
      '📍 $shortName\n'
      '$fullAddress\n\n'
      '$mapsUrl\n\n'
      'Sent via TravelShield',
    );
    final waUrl = 'https://wa.me/$cleanNumber?text=$waMessage';

    // Show SOS result dialog
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: _white,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
                color: _primary,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20))),
            child: Row(children: [
              const Icon(Icons.check_circle_rounded, color: _white),
              const SizedBox(width: 10),
              Text('SOS Sent', style: GoogleFonts.urbanist(
                  color: _white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16)),
            ])),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Accuracy badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                        color: accColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: accColor.withOpacity(0.3))),
                    child: Row(children: [
                      Icon(accIcon, color: accColor, size: 16),
                      const SizedBox(width: 8),
                      Flexible(child: Text(
                        'Accuracy: ±${acc.toStringAsFixed(1)}m  ($accLabel)',
                        style: GoogleFonts.urbanist(
                            color: accColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13))),
                    ])),

                  const SizedBox(height: 14),

                  _detailRow(Icons.my_location_rounded, _accent,
                      'Latitude',  lat.toStringAsFixed(8)),
                  _detailRow(Icons.my_location_rounded, _accent,
                      'Longitude', lon.toStringAsFixed(8)),
                  _detailRow(Icons.location_pin, _primary,
                      'Location', shortName),

                  // Full address if different from shortName
                  if (fullAddress.isNotEmpty && fullAddress != shortName)
                    _detailRow(Icons.home_rounded, _primary,
                        'Address', fullAddress),

                  const SizedBox(height: 8),

                  _actionBtn('Open in Google Maps', Icons.map_rounded,
                      const Color(0xFF34a853),
                      () => launchUrl(Uri.parse(mapsUrl),
                          mode: LaunchMode.externalApplication)),
                  const SizedBox(height: 10),
                  _actionBtn('Send via WhatsApp', Icons.message_rounded,
                      const Color(0xFF25D366),
                      () => launchUrl(Uri.parse(waUrl),
                          mode: LaunchMode.externalApplication)),
                ])),

          const Divider(height: 1),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('Close', style: GoogleFonts.urbanist(
                  color: _light,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)))),
        ]),
      ),
    );
  }

  Widget _detailRow(IconData icon, Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: color, size: 16)),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.urbanist(
                  fontSize: 11, color: _light, fontWeight: FontWeight.w600)),
              Text(value, style: GoogleFonts.urbanist(
                  fontSize: 14, color: _dark, fontWeight: FontWeight.w500)),
            ])),
      ]));
  }

  void _showHelplines() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: _white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.85,
        builder: (_, controller) => Column(children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2))),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [_primary, _cardHelpline])),
            child: Row(children: [
              const Icon(Icons.phone_in_talk_rounded, color: _white),
              const SizedBox(width: 10),
              Text('Emergency Helplines', style: GoogleFonts.urbanist(
                  color: _white, fontWeight: FontWeight.w700, fontSize: 16)),
            ])),
          Expanded(child: ListView.builder(
            controller: controller,
            itemCount: _helplines.length,
            itemBuilder: (_, i) {
              final item = _helplines[i];
              if (item.containsKey('category')) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 8),
                  color: _bg,
                  child: Text(
                    (item['category'] as String).toUpperCase(),
                    style: GoogleFonts.urbanist(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: _light, letterSpacing: 0.8)));
              }
              final color = item['color'] as Color;
              return Container(
                decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(
                        color: Colors.grey.shade100))),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 4),
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(item['icon'] as IconData,
                        color: color, size: 20)),
                  title: Text(item['name'], style: GoogleFonts.urbanist(
                      fontWeight: FontWeight.w700,
                      fontSize: 14, color: _dark)),
                  subtitle: Text(item['desc'], style: GoogleFonts.urbanist(
                      fontSize: 11, color: _light)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(item['number'], style: GoogleFonts.urbanist(
                        fontSize: 14, fontWeight: FontWeight.w800,
                        color: _primary, letterSpacing: 0.5)),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _makeCall(item['number']),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                            color: _cardBg, shape: BoxShape.circle),
                        child: Icon(Icons.phone_rounded,
                            color: _primary, size: 16))),
                  ]),
                  onTap: () => _makeCall(item['number'])));
            })),
        ])),
    );
  }

  Widget _sosCard({
    required String label,
    required String sublabel,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, 5))],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 24)),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.urbanist(
              color: _dark, fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(sublabel, style: GoogleFonts.urbanist(
              color: _light, fontSize: 10, fontWeight: FontWeight.w500)),
        ])),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW  = MediaQuery.of(context).size.width;
    final isWide   = screenW > 600;
    final contentW = isWide ? 480.0 : screenW;

    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: SizedBox(
          width: contentW,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [

              SliverAppBar(
                backgroundColor: _white,
                elevation: 0,
                floating: true,
                snap: true,
                toolbarHeight: 70,
                leading: const SizedBox.shrink(),
                automaticallyImplyLeading: false,
                title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Emergency SOS', style: GoogleFonts.urbanist(
                          fontSize: 20, fontWeight: FontWeight.w800,
                          color: _dark)),
                      Text('Tap a button for immediate help',
                          style: GoogleFonts.urbanist(
                              fontSize: 12, color: _light,
                              fontWeight: FontWeight.w500)),
                    ]),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => Stack(
                          alignment: Alignment.center,
                          children: [
                            Transform.scale(
                              scale: _pulseAnim.value,
                              child: Container(
                                width: 20, height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _accent.withOpacity(
                                        (1.8 - _pulseAnim.value)
                                            .clamp(0.0, 1.0)),
                                    width: 2),
                                ))),
                            Container(
                              width: 10, height: 10,
                              decoration: const BoxDecoration(
                                  color: _accent,
                                  shape: BoxShape.circle)),
                          ])),
                  ),
                ],
              ),

              // Location bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _primary.withOpacity(0.15)),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3))],
                    ),
                    child: Row(children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                            color: _primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.location_on_rounded,
                            color: _primary, size: 16)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_locationText,
                          style: GoogleFonts.urbanist(
                              color: _dark, fontSize: 12,
                              fontWeight: FontWeight.w500))),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _badgeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _badgeColor.withOpacity(0.3))),
                        child: Text(_locationBadge,
                            style: GoogleFonts.urbanist(
                                color: _badgeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700))),
                    ]))),
              ),

              // Section label
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                  child: Row(children: [
                    Text('Quick Actions', style: GoogleFonts.urbanist(
                        fontSize: 17, fontWeight: FontWeight.w800,
                        color: _dark)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('👆 Tap to use',
                          style: GoogleFonts.urbanist(
                              fontSize: 10, color: _primary,
                              fontWeight: FontWeight.w600))),
                  ])),
              ),

              // SOS Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: ((contentW - 46) / 2) / 130,
                  ),
                  delegate: SliverChildListDelegate([
                    _sosCard(label: 'Police', sublabel: 'Find nearby',
                        icon: Icons.local_police_rounded, color: _cardPolice,
                        onTap: () => _showNearby('police')),
                    _sosCard(label: 'Helplines', sublabel: 'Emergency numbers',
                        icon: Icons.phone_in_talk_rounded, color: _cardHelpline,
                        onTap: _showHelplines),
                    _sosCard(label: 'Hospitals', sublabel: 'Find nearby',
                        icon: Icons.local_hospital_rounded, color: _cardHospital,
                        onTap: () => _showNearby('hospital')),
                    _sosCard(label: 'Send SOS', sublabel: 'Alert contacts',
                        icon: Icons.notifications_active_rounded, color: _cardSOS,
                        onTap: _sendSOS),
                  ]),
                ),
              ),

              // Emergency strip
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _cardSOS.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _cardSOS.withOpacity(0.2))),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                            color: _cardSOS,
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.emergency_rounded,
                            color: _white, size: 20)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Life-threatening emergency?',
                                style: GoogleFonts.urbanist(
                                    fontSize: 13, fontWeight: FontWeight.w800,
                                    color: _dark)),
                            const SizedBox(height: 2),
                            Text('Call 112 — Police, Fire & Ambulance',
                                style: GoogleFonts.urbanist(
                                    fontSize: 11, color: _light,
                                    fontWeight: FontWeight.w500)),
                          ])),
                      GestureDetector(
                        onTap: () => _makeCall('112'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                              color: _cardSOS,
                              borderRadius: BorderRadius.circular(10)),
                          child: Text('Call 112', style: GoogleFonts.urbanist(
                              color: _white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)))),
                    ]))),
              ),

              // Web notice
              if (kIsWeb)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: _primary.withOpacity(0.2))),
                      child: Row(children: [
                        Icon(Icons.info_outline_rounded,
                            color: _primary, size: 16),
                        const SizedBox(width: 10),
                        Expanded(child: Text(
                          'On web, tap call buttons to see the number. '
                          'Install the app on Android for direct dialing.',
                          style: GoogleFonts.urbanist(
                              fontSize: 11, color: _primary,
                              fontWeight: FontWeight.w500))),
                      ]))),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}