import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/system_metric.dart';

class ApiService {
  Future<Map<String, dynamic>> login(String username, String password) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/api/login');
    final response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}))
        .timeout(const Duration(seconds: 5));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['error'] ?? 'Login failed');
  }

  Future<void> register(String username, String password) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/api/register');
    final response = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}))
        .timeout(const Duration(seconds: 5));
    final data = jsonDecode(response.body);
    if (response.statusCode != 201) {
      throw Exception(data['error'] ?? 'Registration failed');
    }
  }

  /// Returns latest metric, history and alerts for the logged-in user's PC.
  Future<Map<String, dynamic>> getUserDashboard(String username) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/api/metrics/user/$username');
    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data;
    throw Exception(data['error'] ?? 'Failed to load your data');
  }

  Future<List<SystemMetric>> getLatestMetrics() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/api/metrics/latest');
    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => SystemMetric.fromJson(item as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load metrics');
  }

  Future<List<SystemMetric>> getHistory(String systemName, {int limit = 50}) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/api/metrics/$systemName?limit=$limit');
    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => SystemMetric.fromJson(item as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load history');
  }
}
