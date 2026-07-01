import 'package:flutter/material.dart';
import '../theme.dart';

class AlertsPage extends StatelessWidget {
  final List<Map<String, dynamic>> alerts;

  const AlertsPage({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    final criticals = alerts.where((a) => a['level'] == 'critical').toList();
    final warnings  = alerts.where((a) => a['level'] == 'warning').toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Alerts',
              style: TextStyle(color: AppColors.textPrimary,
                  fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${alerts.length} alert${alerts.length == 1 ? '' : 's'} for your system',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),

          // Summary badges
          Row(children: [
            _badge('Critical', criticals.length, AppColors.critical),
            const SizedBox(width: 10),
            _badge('Warning', warnings.length, AppColors.warning),
          ]),
          const SizedBox(height: 20),

          if (alerts.isEmpty)
            const Expanded(
              child: Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.check_circle_outline,
                      color: AppColors.healthy, size: 52),
                  SizedBox(height: 14),
                  Text('All clear — no alerts for your system.',
                      style: TextStyle(color: AppColors.textSecondary)),
                ]),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: alerts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _alertCard(alerts[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _badge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(label == 'Critical'
            ? Icons.error_outline
            : Icons.warning_amber_outlined,
            color: color, size: 16),
        const SizedBox(width: 6),
        Text('$count $label',
            style: TextStyle(color: color,
                fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _alertCard(Map<String, dynamic> alert) {
    final isCritical = alert['level'] == 'critical';
    final color = isCritical ? AppColors.critical : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isCritical ? Icons.error_outline : Icons.warning_amber_outlined,
            color: color, size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text((alert['level'] as String).toUpperCase(),
                    style: TextStyle(color: color, fontSize: 9,
                        fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
              const SizedBox(width: 8),
              Text((alert['metric'] as String? ?? '').toUpperCase(),
                  style: const TextStyle(color: AppColors.textSecondary,
                      fontSize: 11, fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(height: 6),
            Text(alert['message'] as String? ?? '',
                style: const TextStyle(color: AppColors.textPrimary,
                    fontSize: 13, height: 1.4)),
            const SizedBox(height: 4),
            Text(alert['created_at'] as String? ?? '',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ]),
        ),
      ]),
    );
  }
}
