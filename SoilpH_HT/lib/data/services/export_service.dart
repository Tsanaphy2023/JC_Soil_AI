import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/ph_sensor_reading.dart';

class ExportService {
  ExportService._();

  /// Export list of calibrated readings to CSV file
  static Future<String> exportToCsv(List<CalibratedPhResult> history) async {
    final List<List<dynamic>> rows = [
      [
        'Timestamp',
        'Raw pH',
        'Calibrated pH',
        'Delta Total',
        'Delta Temp (Nernst)',
        'Delta Moisture',
        'Delta PINN',
        'Temperature (°C)',
        'Moisture (%VWC)',
        'EC (uS/cm)',
        'AI Confidence',
        'Physical Interpretation',
        'Model Version',
      ]
    ];

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    for (final item in history) {
      rows.add([
        dateFormat.format(item.timestamp),
        item.rawReading.phRaw,
        item.phCalibrated,
        item.deltaPhTotal,
        item.deltaPhTemperature,
        item.deltaPhMoisture,
        item.deltaPhPinn,
        item.rawReading.temperature,
        item.rawReading.moisture,
        item.rawReading.conductivity,
        item.confidenceScore,
        item.physicalInterpretation,
        item.modelName,
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'SoilpH_HT_Log_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvData);

    return file.path;
  }

  /// Share CSV file via Android native share sheet
  static Future<void> shareFile(String filePath) async {
    final xFile = XFile(filePath);
    await Share.shareXFiles([xFile], text: 'ข้อมูลผลการตรวจวัดและชดเชยค่า pH ดินด้วย Deep Learning (SoilpH-HT)');
  }
}
