import 'dart:io';

import 'export_service.dart';
import 'report_history_service.dart';

class ReportManagerService {
  const ReportManagerService._();

  /// Loads all previously generated reports.
  static Future<List<Map<String, dynamic>>> loadReports() async {
    return ReportHistoryService.getReports();
  }

  /// Deletes a report at the specified index.
  static Future<List<Map<String, dynamic>>> deleteReport(int index) async {
    final reports = await ReportHistoryService.getReports();

    if (index < 0 || index >= reports.length) {
      return reports;
    }

    reports.removeAt(index);

    await ReportHistoryService.saveReportsList(reports);

    return reports;
  }

  /// Deletes the complete report history.
  static Future<List<Map<String, dynamic>>> clearHistory() async {
    await ReportHistoryService.clearReports();

    return [];
  }

  /// Shares an existing report if the file still exists.
  ///
  /// Returns false when the file no longer exists.
  static Future<bool> shareExistingReport(String path) async {
    final file = File(path);

    if (!await file.exists()) {
      return false;
    }

    await ExportService.shareFile(file);

    return true;
  }

  static Future<void> saveReport(File file) async {
    await ReportHistoryService.saveReport(
      name: file.path.split('/').last,
      path: file.path,
    );
  }
}
