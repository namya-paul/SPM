import 'package:flutter/material.dart';
import '../models/system_metric.dart';
import '../theme.dart';

class HistoryPage extends StatelessWidget {
  final List<SystemMetric> history;

  const HistoryPage({super.key, required this.history});

  Color _statusColor(SystemMetric m) {
    if (m.cpu >= 90 || m.ram >= 90) return AppColors.critical;
    if (m.cpu >= 70 || m.ram >= 75) return AppColors.warning;
    return AppColors.healthy;
  }

  String _statusLabel(SystemMetric m) {
    if (m.cpu >= 90 || m.ram >= 90) return 'Critical';
    if (m.cpu >= 70 || m.ram >= 75) return 'Warning';
    return 'Normal';
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw.replaceAll(' ', 'T'));
      return '${dt.day.toString().padLeft(2,'0')}/'
          '${dt.month.toString().padLeft(2,'0')}/'
          '${dt.year}';
    } catch (_) { return raw.split(' ').first; }
  }

  String _formatTime(String raw) {
    try {
      final dt = DateTime.parse(raw.replaceAll(' ', 'T'));
      return '${dt.hour.toString().padLeft(2,'0')}:'
          '${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return raw.split(' ').last; }
  }

  @override
  Widget build(BuildContext context) {
    final reversed = history.reversed.toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System History',
              style: TextStyle(color: AppColors.textPrimary,
                  fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Previous monitoring records',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),

          if (history.isEmpty)
            const Expanded(
              child: Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.history, color: AppColors.textSecondary, size: 52),
                  SizedBox(height: 14),
                  Text('No history yet.',
                      style: TextStyle(color: AppColors.textSecondary)),
                ]),
              ),
            )
          else
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceLight),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: const Row(children: [
                        Expanded(flex: 3, child: _HeaderCell('Date')),
                        Expanded(flex: 2, child: _HeaderCell('Time')),
                        Expanded(flex: 2, child: _HeaderCell('CPU')),
                        Expanded(flex: 2, child: _HeaderCell('RAM')),
                        Expanded(flex: 2, child: _HeaderCell('Disk')),
                        Expanded(flex: 3, child: _HeaderCell('Status')),
                      ]),
                    ),
                    // Rows
                    Expanded(
                      child: ListView.separated(
                        itemCount: reversed.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: AppColors.surfaceLight),
                        itemBuilder: (context, i) {
                          final m = reversed[i];
                          final color = _statusColor(m);
                          final label = _statusLabel(m);
                          final receivedAt = m.receivedAt ?? m.timestamp;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 13),
                            color: i.isEven
                                ? Colors.transparent
                                : AppColors.surfaceLight.withValues(alpha: 0.3),
                            child: Row(children: [
                              Expanded(flex: 3,
                                  child: _Cell(_formatDate(receivedAt))),
                              Expanded(flex: 2,
                                  child: _Cell(_formatTime(receivedAt))),
                              Expanded(flex: 2,
                                  child: _Cell('${m.cpu.toStringAsFixed(1)}%',
                                      color: m.cpu >= 90
                                          ? AppColors.critical
                                          : m.cpu >= 70
                                              ? AppColors.warning
                                              : AppColors.textPrimary)),
                              Expanded(flex: 2,
                                  child: _Cell('${m.ram.toStringAsFixed(1)}%',
                                      color: m.ram >= 90
                                          ? AppColors.critical
                                          : m.ram >= 75
                                              ? AppColors.warning
                                              : AppColors.textPrimary)),
                              Expanded(flex: 2,
                                  child: _Cell('${m.disk.toStringAsFixed(1)}%')),
                              Expanded(flex: 3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(label,
                                      style: TextStyle(
                                          color: color, fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ]),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5));
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final Color? color;
  const _Cell(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
            color: color ?? AppColors.textPrimary, fontSize: 13));
  }
}
