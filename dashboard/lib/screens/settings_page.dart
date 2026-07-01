import 'package:flutter/material.dart';
import '../config.dart';
import '../theme.dart';

class SettingsPage extends StatelessWidget {
  final String username;
  final VoidCallback onLogout;

  const SettingsPage({super.key, required this.username, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings',
              style: TextStyle(color: AppColors.textPrimary,
                  fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Account and system configuration',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 28),

          _section('Account', [
            _infoTile(Icons.person_outline, 'Username', username),
            _infoTile(Icons.cloud_outlined, 'Backend URL', AppConfig.baseUrl),
            _infoTile(Icons.timer_outlined, 'Refresh Interval',
                '${AppConfig.refreshInterval.inSeconds}s'),
          ]),

          const SizedBox(height: 20),

          _section('Thresholds', [
            _infoTile(Icons.memory_outlined,  'CPU Warning',  '≥ 70%'),
            _infoTile(Icons.memory_outlined,  'CPU Critical', '≥ 90%'),
            _infoTile(Icons.storage_outlined, 'RAM Warning',  '≥ 75%'),
            _infoTile(Icons.storage_outlined, 'RAM Critical', '≥ 90%'),
            _infoTile(Icons.save_outlined,    'Disk Warning', '≥ 80%'),
            _infoTile(Icons.save_outlined,    'Disk Critical','≥ 95%'),
          ]),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout, color: AppColors.critical),
              label: const Text('Logout',
                  style: TextStyle(color: AppColors.critical)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.critical),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(),
            style: const TextStyle(color: AppColors.textSecondary,
                fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Column(
            children: [
              for (int i = 0; i < tiles.length; i++) ...[
                tiles[i],
                if (i != tiles.length - 1)
                  const Divider(height: 1, color: AppColors.surfaceLight),
              ]
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: const TextStyle(color: AppColors.textPrimary,
                fontSize: 13, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
