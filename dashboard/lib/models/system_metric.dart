/// Represents a single metric reading for one monitored PC,
/// matching the JSON returned by the backend API.
class SystemMetric {
  final String systemName;
  final String ipAddress;
  final String os;
  final double cpu;
  final double ram;
  final double disk;
  final double network;
  final String timestamp;
  final String? receivedAt;
  final String? status; // "online" or "offline" (only present on /latest)

  SystemMetric({
    required this.systemName,
    required this.ipAddress,
    required this.os,
    required this.cpu,
    required this.ram,
    required this.disk,
    required this.network,
    required this.timestamp,
    this.receivedAt,
    this.status,
  });

  factory SystemMetric.fromJson(Map<String, dynamic> json) {
    return SystemMetric(
      systemName: json['system_name'] as String? ?? 'Unknown',
      ipAddress: json['ip_address'] as String? ?? '-',
      os: json['os'] as String? ?? '-',
      cpu: _toDouble(json['cpu']),
      ram: _toDouble(json['ram']),
      disk: _toDouble(json['disk']),
      network: _toDouble(json['network']),
      timestamp: json['timestamp'] as String? ?? '',
      receivedAt: json['received_at'] as String?,
      status: json['status'] as String?,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
