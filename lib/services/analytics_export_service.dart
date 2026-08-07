import 'package:flutter/material.dart';

import '../services/export_service.dart';
import '../services/guest_dialog_service.dart';
import '../services/report_manager_service.dart';

class AnalyticsExportService {
  /// Exports expenses as a PDF, saves it to report history,
  /// shares the file, and shows a success/error message.
  static Future<void> exportPdf({
    required BuildContext context,
    required List expenses,
    required Future<void> Function() onReportsUpdated,
  }) async {
    try {
      await GuestDialogService.requireAccount(context);

      final file = await ExportService.exportExpensesPdf(expenses);

      await ReportManagerService.saveReport(file);

      await onReportsUpdated();

      await ExportService.shareFile(file);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF report exported successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export PDF report')),
      );
    }
  }

  /// Exports expenses as CSV, saves it to report history,
  /// shares the file, and shows a success/error message.
  static Future<void> exportCsv({
    required BuildContext context,
    required List expenses,
    required Future<void> Function() onReportsUpdated,
  }) async {
    try {
      await GuestDialogService.requireAccount(context);

      final file = await ExportService.exportExpensesCsv(expenses);

      await ReportManagerService.saveReport(file);

      await onReportsUpdated();

      await ExportService.shareFile(file);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV report exported successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export CSV report')),
      );
    }
  }
}
