import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../config.dart';
import '../models/system_metric.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/usage_bar.dart';
import 'login_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  final String username;
  final String? systemName;

  const UserDashboardScreen({
    super.key,
    required this.username,
    required this.systemName,
  });

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  final ApiService _api = ApiService();

  SystemMetric? _latest;
  List<SystemMetric> _history = [];
  List<Map<String, dynamic>> _alerts = [];
  Timer? _timer;
  bool _loading = true;
  String? _error;
  int _tab = 0; // 0=overview, 1=charts, 2=alerts

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(AppConfig.refreshInterval, (_) => _fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final data = await _api.getUserDashboard(widget.username);
      if (!mounted) return;

      final latestJson = data['latest'] as Map<String, dynamic>?;
      final historyJson = data['history'] as List<dynamic>? ?? [];
      final alertsJson  = data['alerts']  as List<dynamic>? ?? [];

      setState(() {
        _latest  = latestJson != null ? SystemMetric.fromJson(latestJson) : null;
        _history = historyJson
            .map((e) => SystemMetric.fromJson(e as Map<String, dynamic>))
            .toList();
        _alerts  = alertsJson
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _error   = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error   = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _logout() {
    _timer?.cancel();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final unlinked = widget.systemName == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('System Monitor'),
            Text(
              'Logged in as ${widget.username}',
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          if (!_loading)
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchData,
                tooltip: 'Refresh'),
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout'),
        ],
      ),
      body: unlinked
          ? _buildUnlinkedState()
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildError()
                  : _buildDashboard(),
      bottomNavigationBar: unlinked
          ? null
          : BottomNavigationBar(
              currentIndex: _tab,
              onTap: (i) => setState(() => _tab = i),
              backgroundColor: AppColors.surface,
              selectedItemColor: AppColors.accent,
              unselectedItemColor: AppColors.textSecondary,
              items: [
                const BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_outlined),
                    activeIcon: Icon(Icons.dashboard),
                    label: 'Overview'),
                const BottomNavigationBarItem(
                    icon: Icon(Icons.show_chart_outlined),
                    activeIcon: Icon(Icons.show_chart),
                    label: 'Charts'),
                BottomNavigationBarItem(
                    icon: Badge(
                      isLabelVisible: _alerts.isNotEmpty,
                      label: Text('${_alerts.length}'),
                      child: const Icon(Icons.notifications_outlined),
                    ),
                    activeIcon: const Icon(Icons.notifications),
                    label: 'Alerts'),
              ],
            ),
    );
  }

  // ── Unlinked (agent not running yet) ──────────────────────────────
  Widget _buildUnlinkedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.computer_outlined,
              color: AppColors.textSecondary, size: 56),
          const SizedBox(height: 20),
          const Text('No PC linked to your account yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          const Text(
            'To link your PC:\n'
            '1. Run the monitoring agent on your computer\n'
            '2. Make sure your Windows username matches your account\n'
            '3. Come back here — it will appear automatically',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.7),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchData,
            icon: const Icon(Icons.refresh),
            label: const Text('Check Again'),
          ),
        ]),
      ),
    );
  }

  // ── Error state ───────────────────────────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.cloud_off, color: AppColors.textSecondary, size: 48),
          const SizedBox(height: 16),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchData, child: const Text('Retry')),
        ]),
      ),
    );
  }

  // ── Main dashboard ────────────────────────────────────────────────
  Widget _buildDashboard() {
    if (_tab == 0) return _buildOverview();
    if (_tab == 1) return _buildCharts();
    return _buildAlerts();
  }

  // ── Tab 0: Overview ───────────────────────────────────────────────
  Widget _buildOverview() {
    final m = _latest;
    if (m == null) return const Center(child: Text('No data yet.'));

    final isOnline = m.status == 'online';

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOnline
                    ? AppColors.healthy.withValues(alpha: 0.4)
                    : AppColors.critical.withValues(alpha: 0.4),
              ),
            ),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: (isOnline ? AppColors.healthy : AppColors.critical)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isOnline ? Icons.computer : Icons.computer_outlined,
                  color: isOnline ? AppColors.healthy : AppColors.critical,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(m.systemName,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('${m.os}  ·  ${m.ipAddress}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isOnline ? AppColors.healthy : AppColors.critical)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isOnline ? 'ONLINE' : 'OFFLINE',
                  style: TextStyle(
                    color: isOnline ? AppColors.healthy : AppColors.critical,
                    fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1,
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Metrics card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Column(children: [
              UsageBar(label: 'CPU', value: m.cpu),
              const SizedBox(height: 8),
              UsageBar(label: 'RAM', value: m.ram),
              const SizedBox(height: 8),
              UsageBar(label: 'DISK', value: m.disk),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('NETWORK',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12, letterSpacing: 0.5)),
                Text('${m.network.toStringAsFixed(1)} KB/s',
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // Quick stats row
          Row(children: [
            _statTile('CPU', '${m.cpu.toStringAsFixed(1)}%', AppColors.accent),
            const SizedBox(width: 10),
            _statTile('RAM', '${m.ram.toStringAsFixed(1)}%', AppColors.healthy),
            const SizedBox(width: 10),
            _statTile('DISK', '${m.disk.toStringAsFixed(1)}%', AppColors.warning),
          ]),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(children: [
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 10,
                  fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  // ── Tab 1: Charts ─────────────────────────────────────────────────
  Widget _buildCharts() {
    if (_history.isEmpty) {
      return const Center(
        child: Text('No history yet. Check back in a few seconds.',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _lineChart('CPU Usage (%)',
            _history.map((m) => m.cpu).toList(), AppColors.accent, 100),
        const SizedBox(height: 16),
        _lineChart('RAM Usage (%)',
            _history.map((m) => m.ram).toList(), AppColors.healthy, 100),
        const SizedBox(height: 16),
        _lineChart('Disk Usage (%)',
            _history.map((m) => m.disk).toList(), AppColors.warning, 100),
        const SizedBox(height: 16),
        _lineChart('Network (KB/s)',
            _history.map((m) => m.network).toList(), AppColors.critical, null),
      ],
    );
  }

  Widget _lineChart(String title, List<double> values, Color color, double? maxY) {
    final spots = [
      for (int i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Container(
        height: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: LineChart(LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.surfaceLight, strokeWidth: 1),
          ),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                  show: true, color: color.withValues(alpha: 0.12)),
            ),
          ],
        )),
      ),
    ]);
  }

  // ── Tab 2: Alerts ─────────────────────────────────────────────────
  Widget _buildAlerts() {
    if (_alerts.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.check_circle_outline, color: AppColors.healthy, size: 52),
          SizedBox(height: 14),
          Text('All clear — no alerts for your system.',
              style: TextStyle(color: AppColors.textSecondary)),
        ]),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _alerts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final alert = _alerts[i];
        final isCritical = alert['level'] == 'critical';
        final color = isCritical ? AppColors.critical : AppColors.warning;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.08),
                  blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(
              isCritical ? Icons.error_outline : Icons.warning_amber_outlined,
              color: color, size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      (alert['level'] as String).toUpperCase(),
                      style: TextStyle(
                          color: color, fontSize: 9,
                          fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    (alert['metric'] as String? ?? '').toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(alert['message'] as String? ?? '',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13, height: 1.4)),
                const SizedBox(height: 4),
                Text(alert['created_at'] as String? ?? '',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ]),
            ),
          ]),
        );
      },
    );
  }
}
