import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportService {
  static Future<void> exportExpensesPdf(List expenses) async {
    final pdf = pw.Document();

    double totalSpending = 0;

    for (var expense in expenses) {
      totalSpending += double.tryParse(expense['amount'].toString()) ?? 0;
    }

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'PesaPulse Financial Report',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),

          pw.SizedBox(height: 10),

          pw.Text('Generated: ${DateTime.now()}'),

          pw.SizedBox(height: 10),

          pw.Text('Total Expenses: ${expenses.length}'),

          pw.Text('Total Spending: KES ${totalSpending.toStringAsFixed(2)}'),

          pw.SizedBox(height: 20),

          pw.Table.fromTextArray(
            headers: const ['Title', 'Category', 'Amount'],

            data: expenses.map((expense) {
              return [
                expense['title'] ?? '',
                expense['category'] ?? '',
                expense['amount'].toString(),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    final directory = await getApplicationDocumentsDirectory();

    final file = File('${directory.path}/expenses_report.pdf');

    await file.writeAsBytes(await pdf.save());

    print('PDF exported successfully');
  }

  static Future<void> exportExpensesCsv(List expenses) async {
    List<List<dynamic>> rows = [];

    rows.add(['Title', 'Category', 'Amount', 'Date', 'Description']);

    for (var expense in expenses) {
      rows.add([
        expense['title'],
        expense['category'],
        expense['amount'],
        expense['expense_date'],
        expense['description'] ?? '',
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();

    final file = File('${directory.path}/expenses_report.csv');

    await file.writeAsString(csvData);

    print('CSV exported successfully');
  }
}
