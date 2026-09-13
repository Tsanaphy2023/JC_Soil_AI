import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/soil_reading.dart';
import 'soil_dataset_service.dart';

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

      // Save into organized subfolder: soil_dataset/data/
      final dataDir = await SoilDatasetService.getDataDirectory();
      final now = DateTime.now();
      final timeStamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

      final timestampedFile = File('${dataDir.path}/Soil_parameters_$timeStamp.csv');
      await timestampedFile.writeAsString(csvContent);

      final latestFile = File('${dataDir.path}/$filename');
      await latestFile.writeAsString(csvContent);

      // Also copy to root storage for legacy access
      try {
        Directory? directory;
        if (Platform.isAndroid) {
          directory = await getExternalStorageDirectory();
        }
        directory ??= await getApplicationDocumentsDirectory();
        final legacyFile = File('${directory.path}/$filename');
        await legacyFile.writeAsString(csvContent);
      } catch (_) {}

      return ExportResult(
        success: true,
        filePath: timestampedFile.path,
        message: 'บันทึกในโฟลเดอร์ data เรียบร้อย: ${timestampedFile.path}',
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
