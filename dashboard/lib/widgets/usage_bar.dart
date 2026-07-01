import 'package:flutter/material.dart';

import '../theme.dart';

/// A labeled horizontal bar showing a percentage value, colored
/// according to how high the value is:
///   < 60%  -> healthy (green)
///   60-85% -> warning (amber)
///   > 85%  -> critical (red)
///
/// Used for CPU, RAM, and Disk usage on the dashboard cards.
class UsageBar extends StatelessWidget {
  final String label;
  final double value; // expected range 0-100
  final String unit;

  const UsageBar({
    super.key,
    required this.label,
    required this.value,
    this.unit = '%',
  });

  Color _colorForValue(double v) {
    if (v < 60) return AppColors.healthy;
    if (v < 85) return AppColors.warning;
    return AppColors.critical;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForValue(value);
    final clamped = value.clamp(0, 100).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${value.toStringAsFixed(1)}$unit',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: clamped / 100,
              minHeight: 6,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
