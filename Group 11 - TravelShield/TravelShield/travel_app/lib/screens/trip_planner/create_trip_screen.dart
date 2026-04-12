import 'package:flutter/material.dart';
import '../../models/trip_model.dart';
import '../../services/trip_api_service.dart';

class CreateTripScreen extends StatefulWidget {
  final TripModel? existingTrip;
  const CreateTripScreen({super.key, this.existingTrip});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = TripApiService();
  bool _loading = false;

  final _titleCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _purpose = 'leisure';
  int _travelers = 1;
  double? _budget;
  String? _notes;
  String _destination = '';

  final List<String> _purposes = [
    'leisure', 'business', 'medical', 'pilgrimage', 'wildlife', 'adventure',
  ];

  List<String> _districts = [];
  bool _loadingDistricts = true;

  @override
  void initState() {
    super.initState();
    _loadDistricts(); // ← loads districts on screen open
    if (widget.existingTrip != null) {
      final t = widget.existingTrip!;
      _titleCtrl.text = t.title;
      _destination = t.destination;
      _startDate = DateTime.tryParse(t.startDate);
      _endDate = DateTime.tryParse(t.endDate);
      _purpose = t.purpose;
      _travelers = t.travelersCount;
      _budget = t.budgetInr;
      _notes = t.notes;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  // ── Load districts from backend ───────────────────────────────────────────

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

  // ── Date picker ───────────────────────────────────────────────────────────

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? (_startDate ?? DateTime.now()).add(const Duration(days: 3))),
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
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.day}/${date.month}/${date.year}';
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_destination.isEmpty) {
      _showSnack('Please select a destination', Colors.orange);
      return;
    }
    if (_startDate == null || _endDate == null) {
      _showSnack('Please select travel dates', Colors.orange);
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      _showSnack('End date must be after start date', Colors.orange);
      return;
    }

    setState(() => _loading = true);
    try {
      final tripData = {
        'title': _titleCtrl.text.trim(),
        'destination': _destination,
        'start_date': _startDate!.toIso8601String().split('T').first,
        'end_date': _endDate!.toIso8601String().split('T').first,
        'purpose': _purpose,
        'travelers_count': _travelers,
        if (_budget != null) 'budget_inr': _budget,
        if (_notes != null && _notes!.isNotEmpty) 'notes': _notes,
      };

      if (widget.existingTrip?.id != null) {
        await _api.updateTrip(widget.existingTrip!.id!, tripData);
        if (mounted) _showSnack('Trip updated!', const Color(0xFF1B5E20));
      } else {
        await _api.createTrip(tripData);
        if (mounted) _showSnack('Trip created!', const Color(0xFF1B5E20));
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _showSnack('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingTrip != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: Text(isEdit ? 'Edit Trip' : 'Plan New Trip'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Trip Title ────────────────────────────────────────────────
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('TRIP TITLE'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: _inputDeco('e.g. Munnar Monsoon Escape', Icons.title_rounded),
                      validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Destination ───────────────────────────────────────────────
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('DESTINATION'),
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
                            decoration: _inputDeco('Select district / place', Icons.place_rounded),
                            isExpanded: true,
                            items: _districts
                                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                                .toList(),
                            onChanged: (v) => setState(() => _destination = v ?? ''),
                            validator: (v) => v == null ? 'Please select a destination' : null,
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Dates ─────────────────────────────────────────────────────
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('TRAVEL DATES'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _dateTile(label: 'Start Date', value: _startDate, onTap: () => _pickDate(true))),
                        const SizedBox(width: 12),
                        Expanded(child: _dateTile(label: 'End Date', value: _endDate, onTap: () => _pickDate(false))),
                      ],
                    ),
                    if (_startDate != null && _endDate != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B5E20).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(children: [
                          const Icon(Icons.info_outline, size: 16, color: Color(0xFF1B5E20)),
                          const SizedBox(width: 6),
                          Text(
                            '${_endDate!.difference(_startDate!).inDays + 1} day trip',
                            style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.w700),
                          ),
                        ]),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Purpose ───────────────────────────────────────────────────
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('TRIP PURPOSE'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _purposes.map((p) {
                        final sel = _purpose == p;
                        return ChoiceChip(
                          label: Text(
                            p[0].toUpperCase() + p.substring(1),
                            style: TextStyle(
                              color: sel ? Colors.white : const Color(0xFF1B5E20),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          selected: sel,
                          selectedColor: const Color(0xFF1B5E20),
                          backgroundColor: const Color(0xFF1B5E20).withOpacity(0.08),
                          side: BorderSide(
                            color: sel ? const Color(0xFF1B5E20) : const Color(0xFF1B5E20).withOpacity(0.3),
                          ),
                          onSelected: (_) => setState(() => _purpose = p),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Travelers ─────────────────────────────────────────────────
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('NUMBER OF TRAVELERS'),
                    const SizedBox(height: 8),
                    Row(children: [
                      _counterBtn(
                        icon: Icons.remove,
                        onTap: _travelers > 1 ? () => setState(() => _travelers--) : null,
                      ),
                      const SizedBox(width: 20),
                      Text('$_travelers', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 20),
                      _counterBtn(icon: Icons.add, onTap: () => setState(() => _travelers++)),
                      const SizedBox(width: 12),
                      Text('person${_travelers > 1 ? 's' : ''}', style: const TextStyle(color: Colors.grey)),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Budget & Notes ────────────────────────────────────────────
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('BUDGET & NOTES (OPTIONAL)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: _budget?.toString(),
                      keyboardType: TextInputType.number,
                      decoration: _inputDeco('Total budget in ₹ (e.g. 25000)', Icons.currency_rupee),
                      onChanged: (v) => _budget = double.tryParse(v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: _notes,
                      maxLines: 3,
                      decoration: _inputDeco('Special requirements, preferences...', Icons.note_outlined),
                      onChanged: (v) => _notes = v,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Submit ────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 22, width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          isEdit ? 'Update Trip' : 'Save Trip',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helper Widgets ────────────────────────────────────────────────────────

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w800,
          color: Color(0xFF1B5E20), letterSpacing: 0.8,
        ),
      );

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF1B5E20), size: 20),
        filled: true,
        fillColor: const Color(0xFFF5F7F5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  Widget _dateTile({required String label, required DateTime? value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value != null ? const Color(0xFF1B5E20).withOpacity(0.5) : Colors.transparent,
          ),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF1B5E20)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
              Text(
                _formatDate(value),
                style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13,
                  color: value != null ? const Color(0xFF1B5E20) : Colors.grey,
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _counterBtn({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: onTap != null ? const Color(0xFF1B5E20) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: onTap != null ? Colors.white : Colors.grey, size: 18),
      ),
    );
  }
}