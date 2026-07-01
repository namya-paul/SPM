import 'package:flutter/material.dart';

import '../models/system_metric.dart';
import '../theme.dart';
import 'usage_bar.dart';

/// A card showing a summary of one monitored PC: online status,
/// OS/IP, and CPU/RAM/Disk/Network usage. Tapping the card opens
/// the detail screen with historical charts.
class MetricCard extends StatelessWidget {
  final SystemMetric metric;
  final VoidCallback onTap;

  const MetricCard({
    super.key,
    required this.metric,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = metric.status == 'online';

    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? AppColors.healthy : AppColors.critical,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      metric.systemName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    isOnline ? 'ONLINE' : 'OFFLINE',
                    style: TextStyle(
                      color: isOnline ? AppColors.healthy : AppColors.critical,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${metric.os}  •  ${metric.ipAddress}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              UsageBar(label: 'CPU', value: metric.cpu),
              UsageBar(label: 'RAM', value: metric.ram),
              UsageBar(label: 'DISK', value: metric.disk),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'NETWORK',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '${metric.network.toStringAsFixed(1)} KB/s',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
