// lib/screens/alerts/district_alert_screen.dart

import 'package:flutter/material.dart';
import '../../services/news_service.dart';
import '../../widgets/alert_card.dart';
import '../../widgets/news_tile.dart';

const _kGreen      = Color(0xFF006845);
const _kBackground = Color(0xFFF4F6F8);
const _kDark       = Color(0xFF1A1A2E);

class DistrictAlertScreen extends StatefulWidget {
  const DistrictAlertScreen({super.key});

  @override
  State<DistrictAlertScreen> createState() => _DistrictAlertScreenState();
}

class _DistrictAlertScreenState extends State<DistrictAlertScreen>
    with SingleTickerProviderStateMixin {

  DistrictAlertData? _alertData;
  String? _errorMessage;
  bool _loading = true;
  String _currentDistrict = 'Ernakulam';
  List<String> _districts = [];
  String? _selectedDistrict;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _init();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _districts = await NewsService.fetchDistrictList();
    setState(() {});
    await _loadAlertsForDistrict('Ernakulam');
  }

  Future<void> _loadAlertsForDistrict(String district) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _currentDistrict = district;
      _selectedDistrict = district;
    });
    try {
      final data = await NewsService.fetchDistrictAlerts(district);
      setState(() { _alertData = data; _loading = false; });
      _fadeCtrl.forward(from: 0);
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not fetch alerts.\nMake sure the backend is running on port 8000.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: RefreshIndicator(
        color: _kGreen,
        onRefresh: () => _loadAlertsForDistrict(_currentDistrict),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildDistrictSelector()),
            SliverToBoxAdapter(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: _kGreen,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF004D36), Color(0xFF00875A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('🛡️', style: TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TravelShield Alerts',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                          Text('Kerala Safety Alerts',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _LocationChip(district: _currentDistrict),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDistrictSelector() {
    if (_districts.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedDistrict,
          hint: const Text('Select a district'),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _kGreen),
          style: const TextStyle(color: _kDark, fontSize: 15, fontWeight: FontWeight.w600),
          items: _districts
              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
              .toList(),
          onChanged: (d) {
            if (d != null) _loadAlertsForDistrict(d);
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildLoadingState();
    if (_errorMessage != null) return _buildErrorState();
    if (_alertData == null) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          AlertCard(data: _alertData!),
          if (_alertData!.newsArticles.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
              child: Row(
                children: [
                  const Text('Recent Tourism News',
                      style: TextStyle(
                          color: _kDark, fontSize: 17, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                        color: _kGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('${_alertData!.newsArticles.length}',
                        style: const TextStyle(
                            color: _kGreen, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
            ),
            ...List.generate(
              _alertData!.newsArticles.length,
              (i) => NewsTile(article: _alertData!.newsArticles[i], index: i),
            ),
          ] else
            _buildNoNewsPlaceholder(),
          const SizedBox(height: 24),
          Center(
            child: Text('↓ Pull to refresh alerts',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLoadingState() => SizedBox(
        height: 400,
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(color: _kGreen, strokeWidth: 3),
            const SizedBox(height: 16),
            Text('Fetching alerts for $_currentDistrict...',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ]),
        ),
      );

  Widget _buildErrorState() => SizedBox(
        height: 380,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('😵', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(_errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () => _loadAlertsForDistrict(_currentDistrict),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
              ),
            ]),
          ),
        ),
      );

  Widget _buildNoNewsPlaceholder() => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const Text('🌴', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('All Clear!',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B5E20))),
              const SizedBox(height: 4),
              Text(
                'No tourism alerts for $_currentDistrict in the last 7 days.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF2E7D32), height: 1.4),
              ),
            ]),
          ),
        ]),
      );
}

class _LocationChip extends StatelessWidget {
  final String district;
  const _LocationChip({required this.district});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.location_on_outlined, color: Colors.white70, size: 14),
        const SizedBox(width: 5),
        Text('📌 $district',
            style: const TextStyle(
                color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}