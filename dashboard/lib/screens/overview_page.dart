import 'package:flutter/material.dart';
import '../models/system_metric.dart';
import '../theme.dart';
import '../widgets/usage_bar.dart';

class OverviewPage extends StatelessWidget {
  final SystemMetric? latest;
  final String? systemName;
  final VoidCallback onRefresh;

  const OverviewPage({
    super.key,
    required this.latest,
    required this.systemName,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (systemName == null) return _buildUnlinkedState(context);

    final m = latest;
    if (m == null) {
      return const Center(
        child: Text('Waiting for data...',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    final isOnline = m.status == 'online';

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Dashboard',
              style: TextStyle(color: AppColors.textPrimary,
                  fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Live system performance',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(18),
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
                width: 48, height: 48,
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
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.systemName,
                      style: const TextStyle(color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text('${m.os}  ·  ${m.ipAddress}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isOnline ? AppColors.healthy : AppColors.critical)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(isOnline ? 'ONLINE' : 'OFFLINE',
                    style: TextStyle(
                        color: isOnline ? AppColors.healthy : AppColors.critical,
                        fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Column(children: [
              UsageBar(label: 'CPU', value: m.cpu),
              const SizedBox(height: 10),
              UsageBar(label: 'RAM', value: m.ram),
              const SizedBox(height: 10),
              UsageBar(label: 'DISK', value: m.disk),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('NETWORK',
                    style: TextStyle(color: AppColors.textSecondary,
                        fontSize: 12, letterSpacing: 0.5)),
                Text('${m.network.toStringAsFixed(1)} KB/s',
                    style: const TextStyle(color: AppColors.accent,
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          LayoutBuilder(builder: (context, constraints) {
            final narrow = constraints.maxWidth < 420;
            final tiles = [
              _statTile('CPU', '${m.cpu.toStringAsFixed(1)}%', AppColors.accent),
              _statTile('RAM', '${m.ram.toStringAsFixed(1)}%', AppColors.healthy),
              _statTile('DISK', '${m.disk.toStringAsFixed(1)}%', AppColors.warning),
            ];
            return narrow
                ? Column(children: [
                    for (final t in tiles)
                      Padding(padding: const EdgeInsets.only(bottom: 10), child: t)
                  ])
                : Row(children: [
                    for (int i = 0; i < tiles.length; i++) ...[
                      Expanded(child: tiles[i]),
                      if (i != tiles.length - 1) const SizedBox(width: 10),
                    ]
                  ]);
          }),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        Text(label,
            style: TextStyle(color: color, fontSize: 10,
                fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(color: AppColors.textPrimary,
                fontSize: 19, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildUnlinkedState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.computer_outlined, color: AppColors.textSecondary, size: 56),
          const SizedBox(height: 20),
          const Text('No PC linked to your account yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textPrimary,
                  fontSize: 16, fontWeight: FontWeight.w500)),
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
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Check Again'),
          ),
        ]),
      ),
    );
  }
}
