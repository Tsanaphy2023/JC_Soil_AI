import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/soil_reading.dart';

class ExportResult {
  final bool success;
  final String filePath;
  final String message;

  const ExportResult({
    required this.success,
    required this.filePath,
    required this.message,
  });
}

/// Service for exporting recorded soil parameters to CSV / Excel spreadsheet
class ExportService {
  ExportService._();

  /// Export list of soil readings to a CSV / XLS compatible file
  static Future<ExportResult> exportToSpreadsheet(
    List<SoilReading> readings, {
    String filename = 'Soil_parameters.csv',
  }) async {
    if (readings.isEmpty) {
      return const ExportResult(
        success: false,
        filePath: '',
        message: 'No sensor data available to export.',
      );
    }

    try {
      final rows = <List<dynamic>>[];
      rows.add(SoilReading.csvHeaders);

      for (final r in readings) {
        rows.add(r.toCsvRow());
      }

      final csvContent = const ListToCsvConverter().convert(rows);

      // Save to external storage or documents directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      }
      directory ??= await getApplicationDocumentsDirectory();

      final file = File('${directory.path}/$filename');
      await file.writeAsString(csvContent);

      return ExportResult(
        success: true,
        filePath: file.path,
        message: 'File saved successfully: ${file.path}',
      );
    } catch (e) {
      return ExportResult(
        success: false,
        filePath: '',
        message: 'Export failed: $e',
      );
    }
  }

  /// Share exported file via system share dialog (Line, Mail, Drive, Files)
  static Future<void> shareFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Soil Parameter Detector Data Log',
        subject: 'Soil Parameters Log Export',
      );
    }
  }
}
