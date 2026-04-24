import 'package:flutter/material.dart';
import '../../models/trip_model.dart';
import '../../services/trip_api_service.dart';
import 'create_trip_screen.dart';
import 'itinerary_screen.dart';

class TripPlannerScreen extends StatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen> {
  final _api = TripApiService();
  List<TripModel> _trips = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() { _loading = true; _error = null; });
    try {
      final trips = await _api.getTrips();
      setState(() { _trips = trips; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _deleteTrip(TripModel trip) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Trip'),
        content: Text('Delete "${trip.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && trip.id != null) {
      await _api.deleteTrip(trip.id!);
      _loadTrips();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('Trip Planner'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrips,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTrips,
        color: const Color(0xFF1B5E20),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Action Cards ──
              _ActionCard(
                icon: Icons.add_location_alt_outlined,
                title: 'Plan a New Trip',
                subtitle: 'Save a trip with destination, dates & budget',
                color: const Color(0xFF1B5E20),
                onTap: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CreateTripScreen()),
                  );
                  if (result == true) _loadTrips();
                },
              ),
              const SizedBox(height: 12),
              _ActionCard(
                icon: Icons.auto_awesome,
                title: 'AI Itinerary Generator',
                subtitle:
                    'Generate day-wise plan with places, food, stays & budget',
                color: const Color(0xFF2E7D32),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>  ItineraryScreen()),
                ),
              ),

              // ── My Trips ──
              const SizedBox(height: 28),
              const Text(
                'MY TRIPS',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.grey,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),

              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                        color: Color(0xFF1B5E20)),
                  ),
                )
              else if (_error != null)
                _ErrorCard(message: _error!, onRetry: _loadTrips)
              else if (_trips.isEmpty)
                _EmptyState()
              else
                ..._trips.map((trip) => _TripCard(
                      trip: trip,
                      onEdit: () async {
                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  CreateTripScreen(existingTrip: trip)),
                        );
                        if (result == true) _loadTrips();
                      },
                      onDelete: () => _deleteTrip(trip),
                      onGenerateItinerary: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ItineraryScreen(prefillTrip: trip),
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Action Card ───────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 3),
              Text(subtitle,
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 12)),
            ]),
          ),
          Icon(Icons.chevron_right, color: color),
        ]),
      ),
    );
  }
}

// ── Trip Card ─────────────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  final TripModel trip;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onGenerateItinerary;

  const _TripCard({
    required this.trip,
    required this.onEdit,
    required this.onDelete,
    required this.onGenerateItinerary,
  });

  Color get _statusColor {
    switch (trip.status) {
      case 'ongoing':
        return Colors.orange;
      case 'completed':
        return Colors.grey;
      default:
        return const Color(0xFF1B5E20);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Top bar with status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _statusColor.withOpacity(0.08),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            Expanded(
              child: Text(
                trip.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                trip.status[0].toUpperCase() + trip.status.substring(1),
                style: TextStyle(
                    fontSize: 11,
                    color: _statusColor,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ]),
        ),

        // Details
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            _detail(Icons.place_outlined, trip.destination,
                const Color(0xFF1B5E20)),
            const SizedBox(height: 6),
            _detail(
              Icons.calendar_today_outlined,
              '${trip.startDate} → ${trip.endDate}  (${trip.durationDays} days)',
              Colors.grey,
            ),
            const SizedBox(height: 6),
            _detail(
              Icons.people_outline,
              '${trip.travelersCount} traveler${trip.travelersCount > 1 ? 's' : ''}  •  ${trip.purpose[0].toUpperCase()}${trip.purpose.substring(1)}',
              Colors.grey,
            ),
            if (trip.budgetInr != null) ...[
              const SizedBox(height: 6),
              _detail(Icons.currency_rupee,
                  '${trip.budgetInr!.toStringAsFixed(0)} budget', Colors.grey),
            ],
            if (trip.notes != null && trip.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              _detail(Icons.note_outlined, trip.notes!, Colors.grey),
            ],

            const SizedBox(height: 14),

            // Buttons
            Row(children: [
              // Generate Itinerary button
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Generate Itinerary',
                      style: TextStyle(fontSize: 13)),
                  onPressed: onGenerateItinerary,
                ),
              ),
              const SizedBox(width: 8),
              // Edit
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(Icons.edit_outlined,
                    color: Colors.blue.shade700, size: 20),
                onPressed: onEdit,
                tooltip: 'Edit',
              ),
              const SizedBox(width: 6),
              // Delete
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 20),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _detail(IconData icon, String text, Color color) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 8),
      Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 13, color: color))),
    ]);
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        const Text('✈️', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        const Text('No trips yet',
            style:
                TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 6),
        const Text(
          'Tap "Plan a New Trip" to create your first Kerala adventure',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ]),
    );
  }
}

// ── Error Card ────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(children: [
        const Icon(Icons.wifi_off, color: Colors.red, size: 32),
        const SizedBox(height: 8),
        const Text('Could not load trips',
            style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Make sure backend is running on port 8000',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white),
          onPressed: onRetry,
          child: const Text('Try Again'),
        ),
      ]),
    );
  }
}