import 'package:flutter/material.dart';
import '../../models/trip_model.dart';
import '../../services/trip_api_service.dart';

class ItineraryScreen extends StatefulWidget {
  final TripModel? prefillTrip;
  const ItineraryScreen({super.key, this.prefillTrip});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen>
    with SingleTickerProviderStateMixin {
  final _api = TripApiService();
  late TabController _tabController;

  // Form state
  String _destination = '';
  DateTime? _startDate;
  DateTime? _endDate;
  String _purpose = 'leisure';
  int _travelers = 1;
  bool _loading = false;
  Map<String, dynamic>? _result;
  int _expandedDay = 0;

  final List<String> _purposes = [
    'leisure', 'pilgrimage', 'adventure', 'business', 'wildlife', 'medical'
  ];

  List<String> _districts = [];
  bool _loadingDistricts = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadDistricts();
    if (widget.prefillTrip != null) {
      final t = widget.prefillTrip!;
      _destination = t.destination;
      _startDate = DateTime.tryParse(t.startDate);
      _endDate = DateTime.tryParse(t.endDate);
      _purpose = t.purpose;
      _travelers = t.travelersCount;
    }
  }

  Future<void> _loadDistricts() async {
    try {
      final list = await _api.getDestinations();
      setState(() { _districts = list; _loadingDistricts = false; });
    } catch (_) {
      setState(() {
        _districts = [
          'Thiruvananthapuram', 'Kollam', 'Pathanamthitta', 'Alappuzha',
          'Kottayam', 'Idukki', 'Ernakulam', 'Thrissur', 'Palakkad',
          'Malappuram', 'Kozhikode', 'Wayanad', 'Kannur', 'Kasaragod',
          'Munnar', 'Alleppey', 'Kochi', 'Kovalam', 'Varkala', 'Thekkady',
        ];
        _loadingDistricts = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get _durationDays {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ??
              (_startDate ?? DateTime.now()).add(const Duration(days: 3))),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1B5E20)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => isStart ? _startDate = picked : _endDate = picked);
    }
  }

  Future<void> _generate() async {
    if (_destination.isEmpty || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select destination and dates'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() { _loading = true; _result = null; });
    try {
      final result = await _api.generateItinerary(
        destination: _destination,
        startDate: _startDate!.toIso8601String().split('T').first,
        endDate: _endDate!.toIso8601String().split('T').first,
        purpose: _purpose,
        travelersCount: _travelers,
      );
      setState(() {
        _result = result;
        _expandedDay = 0;
        _tabController.animateTo(0);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'Select';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('AI Itinerary Generator'),
        elevation: 0,
        bottom: _result != null
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12),
                tabs: const [
                  Tab(text: '📅 Day Plan'),
                  Tab(text: '🍛 Food'),
                  Tab(text: '💡 Tips'),
                  Tab(text: '🏨 Hotels'),
                  Tab(text: '💰 Budget'),
                  Tab(text: '🚗 Transport'),
                ],
              )
            : null,
      ),
      body: _result != null
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildDaysTab(),
                _buildFoodTab(),
                _buildTipsTab(),
                _buildHotelsTab(),
                _buildBudgetTab(),
                _buildTransportTab(),
              ],
            )
          : _buildForm(),
    );
  }

  // ── FORM ──────────────────────────────────────────────────────

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F3D2E), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(children: [
            const Text('🗺️', style: TextStyle(fontSize: 40)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('Smart Itinerary Planner',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17)),
                const SizedBox(height: 4),
                Text(
                  'AI-powered day-wise Kerala travel plan with hidden gems, food & stays',
                  style: TextStyle(color: Colors.white.withOpacity(0.8),
                      fontSize: 12),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Destination
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('DESTINATION'),
          const SizedBox(height: 8),
          _loadingDistricts
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(children: [
                    SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF1B5E20)),
                    ),
                    SizedBox(width: 10),
                    Text('Loading destinations...',
                        style: TextStyle(color: Colors.grey)),
                  ]),
                )
              : DropdownButtonFormField<String>(
                  value: _destination.isEmpty ? null : _destination,
                  decoration:
                      _deco('Select district / place', Icons.place_rounded),
                  isExpanded: true,
                  items: _districts
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setState(() => _destination = v ?? ''),
                ),
        ])),
        const SizedBox(height: 12),

        // Dates
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('TRAVEL DATES'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _dateTile('Start', _startDate, () => _pickDate(true))),
            const SizedBox(width: 10),
            Expanded(child: _dateTile('End', _endDate, () => _pickDate(false))),
          ]),
          if (_durationDays > 0) ...[
            const SizedBox(height: 10),
            _infoChip('$_durationDays day trip'),
          ],
        ])),
        const SizedBox(height: 12),

        // Purpose
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('PURPOSE'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _purposes.map((p) {
              final sel = _purpose == p;
              return ChoiceChip(
                label: Text(p[0].toUpperCase() + p.substring(1),
                    style: TextStyle(
                        color: sel ? Colors.white : const Color(0xFF1B5E20),
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                selected: sel,
                selectedColor: const Color(0xFF1B5E20),
                backgroundColor: const Color(0xFF1B5E20).withOpacity(0.08),
                side: BorderSide(
                    color: sel
                        ? const Color(0xFF1B5E20)
                        : const Color(0xFF1B5E20).withOpacity(0.3)),
                onSelected: (_) => setState(() => _purpose = p),
              );
            }).toList(),
          ),
        ])),
        const SizedBox(height: 12),

        // Travelers
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('TRAVELERS'),
          const SizedBox(height: 8),
          Row(children: [
            _cBtn(Icons.remove,
                _travelers > 1 ? () => setState(() => _travelers--) : null),
            const SizedBox(width: 20),
            Text('$_travelers',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(width: 20),
            _cBtn(Icons.add, () => setState(() => _travelers++)),
            const SizedBox(width: 10),
            Text('person${_travelers > 1 ? 's' : ''}',
                style: const TextStyle(color: Colors.grey)),
          ]),
        ])),
        const SizedBox(height: 24),

        // Generate button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _loading ? null : _generate,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome),
            label: Text(
                _loading ? 'Generating your plan...' : '✨ Generate Itinerary',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 40),
      ]),
    );
  }

  // ── DAYS TAB ──────────────────────────────────────────────────

  Widget _buildDaysTab() {
    final days = List<Map<String, dynamic>>.from(_result!['days'] ?? []);
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20).withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF1B5E20).withOpacity(0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '📍 ${_result!['destination']} — ${_result!['number_of_days']}-Day Plan',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1B5E20)),
            ),
            const SizedBox(height: 4),
            Text(
              '${_result!['start_date']} → ${_result!['end_date']}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ]),
        ),
        const SizedBox(height: 10),

        ...days.asMap().entries.map((entry) {
          final i = entry.key;
          final day = entry.value;
          return _DayCard(
            day: day,
            expanded: _expandedDay == i,
            onTap: () => setState(
                () => _expandedDay = _expandedDay == i ? -1 : i),
          );
        }),

        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Plan Another'),
          onPressed: () => setState(() => _result = null),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            side: const BorderSide(color: Color(0xFF1B5E20)),
            foregroundColor: const Color(0xFF1B5E20),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── FOOD TAB ──────────────────────────────────────────────────

  Widget _buildFoodTab() {
    final food = List<String>.from(_result!['food_suggestions'] ?? []);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionContainer(
          color: const Color(0xFFFFF8E1),
          borderColor: const Color(0xFFFFB300),
          icon: '🍛',
          title: 'Must-Try Food in ${_result!['destination']}',
          titleColor: const Color(0xFFE65100),
          child: Column(
            children: food
                .map((f) => _bulletRow(f, const Color(0xFF2E7D32)))
                .toList(),
          ),
        ),
      ],
    );
  }

  // ── TIPS TAB ──────────────────────────────────────────────────

  Widget _buildTipsTab() {
    final tips = List<String>.from(_result!['general_tips'] ?? []);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionContainer(
          color: const Color(0xFFE3F2FD),
          borderColor: Colors.blue.shade200,
          icon: '💡',
          title: 'Travel Tips for ${_result!['destination']}',
          titleColor: Colors.blue.shade700,
          child: Column(
            children: tips.asMap().entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.blue.shade600,
                    child: Text('${e.key + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(e.value,
                          style: const TextStyle(fontSize: 13))),
                ]),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── HOTELS TAB ────────────────────────────────────────────────

  Widget _buildHotelsTab() {
    final hotels =
        List<Map<String, dynamic>>.from(_result!['hotel_suggestions'] ?? []);
    if (hotels.isEmpty) {
      return const Center(
        child: Text('No hotel data — try regenerating',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: hotels.map((h) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(h['name'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(h['category'] ?? '',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 6),
            Text('📍 ${h['area'] ?? ''}',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            Text('💰 ${h['price_range'] ?? ''}',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            if (h['highlight'] != null) ...[
              const SizedBox(height: 6),
              Text('⭐ ${h['highlight']}',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF1B5E20))),
            ],
          ]),
        );
      }).toList(),
    );
  }

  // ── BUDGET TAB ────────────────────────────────────────────────

  Widget _buildBudgetTab() {
    final b = Map<String, dynamic>.from(_result!['budget_estimate'] ?? {});
    if (b.isEmpty) {
      return const Center(
        child: Text('No budget data — try regenerating',
            style: TextStyle(color: Colors.grey)),
      );
    }
    final items = [
      {'icon': '🏨', 'label': 'Accommodation', 'value': b['accommodation_per_night'], 'note': 'per night'},
      {'icon': '🍛', 'label': 'Food', 'value': b['food_per_day_per_person'], 'note': 'per day/person'},
      {'icon': '🚗', 'label': 'Transport', 'value': b['transport_per_day'], 'note': 'per day'},
      {'icon': '🎯', 'label': 'Activities', 'value': b['activities_per_day'], 'note': 'per day'},
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF0F3D2E), Color(0xFF2E7D32)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            const Text('Total Estimated Budget',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 6),
            Text(b['total_estimated']?.toString() ?? '',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
          ]),
        ),
        const SizedBox(height: 16),
        ...items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6)
                ],
              ),
              child: Row(children: [
                Text(item['icon']?.toString() ?? '',
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(item['label']?.toString() ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700))),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(item['value']?.toString() ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B5E20),
                          fontSize: 14)),
                  Text(item['note']?.toString() ?? '',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                ]),
              ]),
            )),
      ],
    );
  }

  // ── TRANSPORT TAB ─────────────────────────────────────────────

  Widget _buildTransportTab() {
    final transport =
        List<Map<String, dynamic>>.from(_result!['local_transport'] ?? []);
    if (transport.isEmpty) {
      return const Center(
        child: Text('No transport data — try regenerating',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: transport.map((t) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.directions, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(t['type'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
              ),
              Text(t['cost'] ?? '',
                  style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ]),
            const SizedBox(height: 6),
            Text('Use for: ${t['use_for'] ?? ''}',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 4),
            Text('💡 ${t['tip'] ?? ''}',
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1B5E20),
                    fontStyle: FontStyle.italic)),
          ]),
        );
      }).toList(),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1B5E20),
          letterSpacing: 0.8));

  InputDecoration _deco(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF1B5E20), size: 20),
        filled: true,
        fillColor: const Color(0xFFF5F7F5),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF1B5E20), width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  Widget _dateTile(String label, DateTime? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: value != null
                  ? const Color(0xFF1B5E20).withOpacity(0.5)
                  : Colors.transparent),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined,
              size: 16, color: Color(0xFF1B5E20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600)),
              Text(_fmt(value),
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: value != null
                          ? const Color(0xFF1B5E20)
                          : Colors.grey)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _infoChip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1B5E20).withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.info_outline,
              size: 15, color: Color(0xFF1B5E20)),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  color: Color(0xFF1B5E20), fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _cBtn(IconData icon, VoidCallback? onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: onTap != null
                ? const Color(0xFF1B5E20)
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              color: onTap != null ? Colors.white : Colors.grey, size: 18),
        ),
      );

  Widget _sectionContainer({
    required Color color,
    required Color borderColor,
    required String icon,
    required String title,
    required Color titleColor,
    required Widget child,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor.withOpacity(0.4)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$icon $title',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: titleColor)),
          const SizedBox(height: 12),
          child,
        ]),
      );

  Widget _bulletRow(String text, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 7,
            height: 7,
            margin: const EdgeInsets.only(top: 5, right: 10),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 13, color: Colors.black87))),
        ]),
      );
}

// ── Day Card Widget ───────────────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  final Map<String, dynamic> day;
  final bool expanded;
  final VoidCallback onTap;

  const _DayCard(
      {required this.day, required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Column(children: [
        InkWell(
          onTap: onTap,
          borderRadius: expanded
              ? const BorderRadius.vertical(top: Radius.circular(14))
              : BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF1B5E20),
                child: Text('${day['day_number']}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                Text(day['title'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                Text(day['date'] ?? '',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
              ])),
              Row(children: [
                const Icon(Icons.access_time_outlined,
                    size: 13, color: Colors.grey),
                const SizedBox(width: 3),
                Text(day['total_hours'] ?? '',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
              const SizedBox(width: 6),
              Icon(expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey),
            ]),
          ),
        ),
        if (expanded) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              _slot('🌅 Morning', day['morning'], const Color(0xFFE65100)),
              _slot('☀️ Afternoon', day['afternoon'],
                  const Color(0xFF1B5E20)),
              _slot('🌆 Evening', day['evening'],
                  const Color(0xFF7B1FA2)),
              if (day['day_tip'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Text('💡', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(day['day_tip'],
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFE65100),
                                fontWeight: FontWeight.w700))),
                  ]),
                ),
              ],
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _slot(String label, dynamic places, Color color) {
    if (places == null || (places as List).isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 13, color: color)),
      ),
      ...(places as List).map((p) {
        final place = Map<String, dynamic>.from(p);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(place['time_slot'] ?? '',
                  style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(place['duration'] ?? '',
                    style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(place['place_name'] ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 2),
            Text(place['description'] ?? '',
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.directions_walk_outlined,
                  size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(place['activity'] ?? '',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey))),
            ]),
          ]),
        );
      }),
    ]);
  }
}