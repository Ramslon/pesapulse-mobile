import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ReportHistoryService {
  static const String reportsKey = 'generated_reports';

  static Future<void> saveReport({
    required String name,
    required String path,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final reports = prefs.getStringList(reportsKey) ?? [];

    reports.removeWhere((report) {
      final data = jsonDecode(report);
      return data['path'] == path;
    });

    reports.insert(
      0,
      jsonEncode({
        'name': name,
        'path': path,
        'created_at': DateTime.now().toIso8601String(),
      }),
    );

    if (reports.length > 50) {
      reports.removeLast();
    }

    await prefs.setStringList(reportsKey, reports);
  }

  static Future<List<Map<String, dynamic>>> getReports() async {
    final prefs = await SharedPreferences.getInstance();

    final reports = prefs.getStringList(reportsKey) ?? [];

    return reports.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  static Future<void> clearReports() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(reportsKey);
  }

  static Future<void> saveReportsList(
    List<Map<String, dynamic>> reports,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(reportsKey, reports.map(jsonEncode).toList());
  }
}
