import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../config.dart';
import '../models/system_metric.dart';
import '../services/api_service.dart';
import '../theme.dart';

/// Shows historical line charts for one PC's CPU, RAM, Disk, and
/// Network usage, auto-refreshing every [AppConfig.refreshInterval].
class DetailScreen extends StatefulWidget {
  final String systemName;

  const DetailScreen({super.key, required this.systemName});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final ApiService _api = ApiService();

  List<SystemMetric> _history = [];
  Timer? _timer;
  bool _loading = true;
  String? _error;

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
      final data = await _api.getHistory(widget.systemName);
      if (!mounted) return;
      setState(() {
        _history = data;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load history for ${widget.systemName}.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.systemName)),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
      );
    }
    if (_history.isEmpty) {
      return const Center(
        child: Text('No history yet for this system.',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildChart(
          title: 'CPU Usage (%)',
          values: _history.map((m) => m.cpu).toList(),
          color: AppColors.accent,
          maxY: 100,
        ),
        const SizedBox(height: 24),
        _buildChart(
          title: 'RAM Usage (%)',
          values: _history.map((m) => m.ram).toList(),
          color: AppColors.healthy,
          maxY: 100,
        ),
        const SizedBox(height: 24),
        _buildChart(
          title: 'Disk Usage (%)',
          values: _history.map((m) => m.disk).toList(),
          color: AppColors.warning,
          maxY: 100,
        ),
        const SizedBox(height: 24),
        _buildChart(
          title: 'Network (KB/s)',
          values: _history.map((m) => m.network).toList(),
          color: AppColors.critical,
          maxY: null, // network has no fixed upper bound
        ),
      ],
    );
  }

  Widget _buildChart({
    required String title,
    required List<double> values,
    required Color color,
    required double? maxY,
  }) {
    final spots = <FlSpot>[
      for (int i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) =>
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
                    show: true,
                    color: color.withOpacity(0.15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
