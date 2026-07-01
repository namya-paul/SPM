import 'dart:async';
import 'package:flutter/material.dart';
import '../config.dart';
import '../models/system_metric.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'login_screen.dart';
import 'overview_page.dart';
import 'history_page.dart';
import 'alerts_page.dart';
import 'settings_page.dart';

/// Top-level shell: left sidebar navigation + content area.
/// Fetches user data once on a timer and shares it with all sub-pages,
/// so switching tabs is instant (no per-page refetch).
class AppShell extends StatefulWidget {
  final String username;
  final String? systemName;

  const AppShell({super.key, required this.username, required this.systemName});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final ApiService _api = ApiService();
  Timer? _timer;

  SystemMetric? _latest;
  List<SystemMetric> _history = [];
  List<Map<String, dynamic>> _alerts = [];
  bool _loading = true;
  String? _error;
  int _navIndex = 0;

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
      final alertsJson = data['alerts'] as List<dynamic>? ?? [];
      setState(() {
        _latest = latestJson != null ? SystemMetric.fromJson(latestJson) : null;
        _history = historyJson
            .map((e) => SystemMetric.fromJson(e as Map<String, dynamic>))
            .toList();
        _alerts = alertsJson.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _logout() {
    _timer?.cancel();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  static const _navItems = [
    (icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'),
    (icon: Icons.history_outlined, activeIcon: Icons.history, label: 'History'),
    (icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Alerts'),
    (icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 760;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: isWide ? null : Drawer(child: _buildSidebar()),
      appBar: isWide
          ? null
          : AppBar(
              backgroundColor: AppColors.surface,
              title: Text(_navItems[_navIndex].label),
            ),
      body: Row(
        children: [
          if (isWide) _buildSidebar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null && _latest == null
                    ? _buildError()
                    : _buildPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 230,
      color: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Row(children: [
                Icon(Icons.monitor_heart_outlined, color: AppColors.accent, size: 24),
                SizedBox(width: 8),
                Text('SPM',
                    style: TextStyle(color: AppColors.textPrimary,
                        fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ]),
            ),
            for (int i = 0; i < _navItems.length; i++)
              _navTile(i),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                    child: Text(
                      widget.username.isNotEmpty
                          ? widget.username[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: AppColors.accent, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.username,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 13,
                            fontWeight: FontWeight.w500)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, size: 18, color: AppColors.textSecondary),
                    onPressed: _logout,
                    tooltip: 'Logout',
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navTile(int i) {
    final selected = _navIndex == i;
    final item = _navItems[i];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? AppColors.surfaceLight : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() => _navIndex = i);
            if (Scaffold.of(context).hasDrawer) {
              Navigator.maybePop(context);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(children: [
              Icon(selected ? item.activeIcon : item.icon,
                  size: 19,
                  color: selected ? AppColors.accent : AppColors.textSecondary),
              const SizedBox(width: 12),
              Text(item.label,
                  style: TextStyle(
                      color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
              if (i == 2 && _alerts.isNotEmpty) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.critical,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${_alerts.length}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }

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

  Widget _buildPage() {
    switch (_navIndex) {
      case 0:
        return OverviewPage(
          latest: _latest,
          systemName: widget.systemName,
          onRefresh: _fetchData,
        );
      case 1:
        return HistoryPage(history: _history);
      case 2:
        return AlertsPage(alerts: _alerts);
      default:
        return SettingsPage(username: widget.username, onLogout: _logout);
    }
  }
}
