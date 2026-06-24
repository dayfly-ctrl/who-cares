import 'dart:convert';
import 'package:http/http.dart' as http;

const _base = 'https://who-cares-api-production.up.railway.app';

Future<Map<String, dynamic>> fetchBalance() async {
  final r = await http.get(Uri.parse('$_base/api/balance/'));
  return jsonDecode(r.body) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> fetchReport() async {
  final r = await http.get(Uri.parse('$_base/api/report/'));
  return jsonDecode(r.body) as Map<String, dynamic>;
}

Future<List<dynamic>> fetchTrades() async {
  final r = await http.get(Uri.parse('$_base/api/report/trades'));
  return jsonDecode(r.body) as List<dynamic>;
}

Future<List<dynamic>> fetchTransactions(String tab) async {
  final r = await http.get(
      Uri.parse('$_base/api/analysis/transactions?tab=$tab'));
  return jsonDecode(r.body) as List<dynamic>;
}

Future<List<dynamic>> fetchMonitoring() async {
  final r = await http.get(Uri.parse('$_base/api/monitoring/'));
  return jsonDecode(r.body) as List<dynamic>;
}

Future<List<dynamic>> fetchConference(String filter) async {
  final r = await http.get(
      Uri.parse('$_base/api/conference/?filter=$filter'));
  return jsonDecode(r.body) as List<dynamic>;
}

Future<Map<String, dynamic>> fetchSchedule() async {
  final r = await http.get(Uri.parse('$_base/api/analysis/schedule'));
  return jsonDecode(r.body) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> fetchSummary() async {
  final r = await http.get(Uri.parse('$_base/api/analysis/summary'));
  return jsonDecode(r.body) as Map<String, dynamic>;
}

Future<List<dynamic>> fetchRecommendation() async {
  final r = await http.get(
      Uri.parse('$_base/api/analysis/recommendation'));
  return jsonDecode(r.body) as List<dynamic>;
}
