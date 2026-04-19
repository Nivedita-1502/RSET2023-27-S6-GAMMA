import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../../services/user_session.dart';
import '../../services/api_config.dart'; // ← import the config
import '../../data/destinations.dart';
import '../../drawer/app_drawer.dart';
import '../chatbot/chatbot_screen.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
const _bg      = Color(0xFFF5F6F8);
const _white   = Colors.white;
const _primary = Color(0xFF1A6B3C);
const _accent  = Color(0xFF25A05B);
const _dark    = Color(0xFF0D1B12);
const _light   = Color(0xFF9EB5A8);

// ── Destination descriptions ──────────────────────────────────────────────────
const _descriptions = {
  'Munnar':   'A breathtaking hill station in the Western Ghats, famous for its rolling tea gardens, cool misty weather, and the rare Neelakurinji bloom.',
  'Alleppey': 'Known as the "Venice of the East", Alleppey enchants with its tranquil backwaters, charming houseboats, and vibrant snake boat races.',
  'Kochi':    'A captivating port city blending colonial heritage with modern culture — Chinese fishing nets, spice markets, and vibrant art galleries.',
  'Wayanad':  'A lush green paradise nestled in the Western Ghats, home to ancient caves, coffee plantations, tribal heritage, and rich wildlife.',
};

// ── Travel Safety Tips (daily rotation) ──────────────────────────────────────
const _safetyTips = [
  'Always carry a printed copy of your ID when travelling to remote areas in Kerala.',
  'Download offline maps before heading into forest or hill areas — network can be patchy.',
  'Monsoon season (Jun–Sep): avoid trekking alone, watch for landslide alerts in Wayanad & Idukki.',
  'Keep the Kerala Tourism helpline saved: 1800-425-4747 (toll free, 24×7).',
  'Scan QR codes only from verified vendors — use TravelShield\'s QR checker when in doubt.',
  'Inform someone of your itinerary before heading to isolated beaches or forest areas.',
  'Carry cash — many local shops and homestays in rural Kerala don\'t accept cards.',
  'Respect wildlife — maintain safe distance from elephants on forest roads, especially at dusk.',
];

String _getDailyTip() {
  final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
  return _safetyTips[dayOfYear % _safetyTips.length];
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final name = UserSession.currentUser["first_name"] ?? "Explorer";

    return Scaffold(
      backgroundColor: _bg,
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatbotScreen()),
        ),
        backgroundColor: _primary,
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.chat_bubble_rounded, color: _white, size: 22),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          SliverAppBar(
            backgroundColor: _white,
            elevation: 0,
            floating: true,
            snap: true,
            toolbarHeight: 70,
            leading: Builder(
              builder: (ctx) => Padding(
                padding: const EdgeInsets.all(12),
                child: GestureDetector(
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF5F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.menu_rounded, color: _primary, size: 22),
                  ),
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, $name 👋',
                    style: GoogleFonts.urbanist(
                        fontSize: 20, fontWeight: FontWeight.w800, color: _dark)),
                Text("Where to next?",
                    style: GoogleFonts.urbanist(
                        fontSize: 13, color: _light, fontWeight: FontWeight.w500)),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFEEF5F1),
                      child: Text(
                        (UserSession.currentUser["first_name"] ?? "U")[0].toUpperCase(),
                        style: GoogleFonts.urbanist(
                            fontSize: 16, fontWeight: FontWeight.w800, color: _primary),
                      ),
                    ),
                    Positioned(
                      right: 1, bottom: 1,
                      child: Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: _accent, shape: BoxShape.circle,
                          border: Border.all(color: _white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _KeralaBanner(),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 14),
              child: Row(
                children: [
                  Text('Popular Destinations',
                      style: GoogleFonts.urbanist(
                          fontSize: 17, fontWeight: FontWeight.w800, color: _dark)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF5F1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('👆 Tap to explore',
                        style: GoogleFonts.urbanist(
                            fontSize: 10, color: _primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardW = (constraints.maxWidth - 40 - 12) / 2;
                return SizedBox(
                  height: 210,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: destinations.length,
                    itemBuilder: (_, i) => _FlipDestCard(
                      destination: destinations[i],
                      description: _descriptions[destinations[i].name] ?? '',
                      badge: i == 0 ? 'Trending' : i == 1 ? 'Top Rated' : null,
                      width: cardW,
                    ),
                  ),
                );
              },
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 14),
              child: Text('Live Weather & Safety',
                  style: GoogleFonts.urbanist(
                      fontSize: 17, fontWeight: FontWeight.w800, color: _dark)),
            ),
          ),
          const SliverToBoxAdapter(child: _WeatherSafetyCard()),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ── Kerala Banner ─────────────────────────────────────────────────────────────

class _KeralaBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.15), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset('assets/images/boat.png', fit: BoxFit.cover)),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(.6), Colors.black.withOpacity(.1)],
                    begin: Alignment.centerLeft, end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0, bottom: 0, left: 22,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(.9), borderRadius: BorderRadius.circular(20)),
                    child: Text("🌿  God's Own Country",
                        style: GoogleFonts.cormorantGaramond(
                            color: _white, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: .8)),
                  ),
                  const SizedBox(height: 10),
                  Text('Explore\nKerala',
                      style: GoogleFonts.cormorantGaramond(
                          fontSize: 34, fontWeight: FontWeight.w700,
                          color: _white, height: 1.1, letterSpacing: .5)),
                  const SizedBox(height: 6),
                  Text('14 DISTRICTS  •  ENDLESS BEAUTY',
                      style: GoogleFonts.urbanist(
                          fontSize: 10, color: Colors.white54,
                          fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Flip Destination Card ─────────────────────────────────────────────────────

class _FlipDestCard extends StatefulWidget {
  final Destination destination;
  final String description;
  final String? badge;
  final double width;

  const _FlipDestCard({
    required this.destination, required this.description,
    required this.width, this.badge,
  });

  @override
  State<_FlipDestCard> createState() => _FlipDestCardState();
}

class _FlipDestCardState extends State<_FlipDestCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _flipped = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _anim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _toggle() {
    _flipped ? _ctrl.reverse() : _ctrl.forward();
    setState(() => _flipped = !_flipped);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: _toggle,
        child: SizedBox(
          width: widget.width,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) {
              final angle = _anim.value * pi;
              final showBack = angle > pi / 2;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(angle),
                child: showBack
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(pi),
                        child: _back())
                    : _front(),
              );
            },
          ),
        ),
      );

  Widget _front() => Container(
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.1), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(children: [
            Positioned.fill(child: Image.asset(widget.destination.image, fit: BoxFit.cover)),
            Positioned.fill(child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(.65)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0.4, 1.0],
                ),
              ),
            )),
            if (widget.badge != null)
              Positioned(top: 10, left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(8)),
                  child: Text(widget.badge!,
                      style: GoogleFonts.urbanist(color: _white, fontSize: 10, fontWeight: FontWeight.w700)),
                )),
            Positioned(top: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(6)),
                child: const Icon(Icons.flip_rounded, color: Colors.white70, size: 12),
              )),
            Positioned(bottom: 12, left: 12, right: 12,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.destination.name,
                    style: GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w800, color: _white)),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.location_on_rounded, color: Color(0xFF80E0AA), size: 12),
                  const SizedBox(width: 2),
                  Text(widget.destination.location,
                      style: GoogleFonts.urbanist(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                ]),
              ])),
          ]),
        ),
      );

  Widget _back() => Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _primary, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _primary.withOpacity(.25), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.destination.name,
                  style: GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w800, color: _white)),
              const SizedBox(height: 6),
              Container(height: 2, width: 28, color: Colors.white30),
            ]),
            Text(widget.description,
                style: GoogleFonts.urbanist(
                    fontSize: 11.5, color: Colors.white.withOpacity(.85),
                    fontWeight: FontWeight.w500, height: 1.5),
                maxLines: 6, overflow: TextOverflow.ellipsis),
            Row(children: [
              const Icon(Icons.location_on_rounded, color: Colors.white54, size: 12),
              const SizedBox(width: 3),
              Text(widget.destination.location,
                  style: GoogleFonts.urbanist(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w600)),
            ]),
          ],
        ),
      );
}

// ── Weather + Safety Tip Card ─────────────────────────────────────────────────

class _WeatherSafetyCard extends StatefulWidget {
  const _WeatherSafetyCard();

  @override
  State<_WeatherSafetyCard> createState() => _WeatherSafetyCardState();
}

class _WeatherSafetyCardState extends State<_WeatherSafetyCard> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  String _detectedCity = '';

  static const _keralaDistricts = {
    'Thiruvananthapuram': [8.5241, 76.9366],
    'Kollam':            [8.8932, 76.6141],
    'Pathanamthitta':    [9.2648, 76.7870],
    'Alappuzha':         [9.4981, 76.3388],
    'Kottayam':          [9.5916, 76.5222],
    'Idukki':            [9.9189, 77.1025],
    'Ernakulam':         [9.9816, 76.2999],
    'Thrissur':          [10.5276, 76.2144],
    'Palakkad':          [10.7867, 76.6548],
    'Malappuram':        [11.0730, 76.0740],
    'Kozhikode':         [11.2588, 75.7804],
    'Wayanad':           [11.6854, 76.1320],
    'Kannur':            [11.8745, 75.3704],
    'Kasaragod':         [12.4996, 74.9869],
    'Munnar':            [10.0892, 77.0595],
    'Kochi':             [9.9312,  76.2673],
  };

  @override
  void initState() {
    super.initState();
    _fetchWeatherForLocation();
  }

  Future<void> _fetchWeatherForLocation() async {
    setState(() { _loading = true; _error = null; });
    String city = 'Kochi';
    try {
      final perm = await Geolocator.requestPermission();
      if (perm != LocationPermission.denied &&
          perm != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low);
        city = _nearestKeralaCity(pos.latitude, pos.longitude);
      }
    } catch (_) {}
    setState(() => _detectedCity = city);
    await _fetchWeather(city);
  }

  String _nearestKeralaCity(double lat, double lng) {
    String nearest = 'Kochi';
    double minDist = double.infinity;
    _keralaDistricts.forEach((city, coords) {
      final d = _dist(lat, lng, coords[0], coords[1]);
      if (d < minDist) { minDist = d; nearest = city; }
    });
    return nearest;
  }

  double _dist(double lat1, double lng1, double lat2, double lng2) =>
      sqrt(pow(lat1 - lat2, 2) + pow(lng1 - lng2, 2));

  Future<void> _fetchWeather(String city) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/clothing_suggestion/$city')) // ← uses baseUrl
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['status'] == 'success') {
          setState(() { _data = json; _loading = false; });
          return;
        }
      }
      setState(() { _error = 'Unable to fetch weather'; _loading = false; });
    } catch (_) {
      setState(() { _error = 'Check your connection'; _loading = false; });
    }
  }

  String _icon(String w) {
    switch (w.toLowerCase()) {
      case 'rain': case 'drizzle': return '🌧️';
      case 'thunderstorm': return '⛈️';
      case 'clouds': return '☁️';
      case 'clear': return '☀️';
      case 'mist': case 'fog': case 'haze': return '🌫️';
      default: return '🌤️';
    }
  }

  Color _color(String w) {
    switch (w.toLowerCase()) {
      case 'rain': case 'drizzle': case 'thunderstorm': return const Color(0xFF1565C0);
      case 'clouds': return const Color(0xFF546E7A);
      case 'clear': return const Color(0xFFF57F17);
      default: return _primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _white, borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 14, offset: const Offset(0, 4))],
            ),
            child: _loading
                ? const SizedBox(height: 80,
                    child: Center(child: CircularProgressIndicator(color: _primary, strokeWidth: 2)))
                : _error != null
                    ? SizedBox(height: 80,
                        child: Center(child: GestureDetector(
                          onTap: _fetchWeatherForLocation,
                          child: Text('⚠️ $_error — Tap to retry',
                              style: GoogleFonts.urbanist(color: _light, fontSize: 13)))))
                    : _data == null ? const SizedBox(height: 80) : _weatherContent(),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FAF4), borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _primary.withOpacity(.15)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.shield_rounded, color: _white, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("Today's Safety Tip",
                    style: GoogleFonts.urbanist(fontSize: 13, fontWeight: FontWeight.w800, color: _primary)),
                const SizedBox(height: 5),
                Text(_getDailyTip(),
                    style: GoogleFonts.urbanist(
                        fontSize: 13, color: const Color(0xFF2E5E42),
                        fontWeight: FontWeight.w500, height: 1.5)),
              ])),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _weatherContent() {
    final temp    = (_data!['temperature'] as num).toDouble();
    final weather = _data!['weather'] as String;
    final color   = _color(weather);
    return Row(children: [
      Text(_icon(weather), style: const TextStyle(fontSize: 52)),
      const SizedBox(width: 16),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        RichText(text: TextSpan(children: [
          TextSpan(text: '${temp.round()}',
              style: GoogleFonts.urbanist(fontSize: 48, fontWeight: FontWeight.w800, color: _dark)),
          TextSpan(text: '°C',
              style: GoogleFonts.urbanist(fontSize: 20, fontWeight: FontWeight.w600, color: _light)),
        ])),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(.1), borderRadius: BorderRadius.circular(8)),
          child: Text(weather,
              style: GoogleFonts.urbanist(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ]),
      const Spacer(),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Row(children: [
          const Icon(Icons.my_location_rounded, color: Color(0xFF80E0AA), size: 14),
          const SizedBox(width: 4),
          Text(_detectedCity,
              style: GoogleFonts.urbanist(fontSize: 15, fontWeight: FontWeight.w800, color: _dark)),
        ]),
        const SizedBox(height: 3),
        Text('Kerala, India',
            style: GoogleFonts.urbanist(fontSize: 12, color: _light, fontWeight: FontWeight.w500)),
      ]),
    ]);
  }
}