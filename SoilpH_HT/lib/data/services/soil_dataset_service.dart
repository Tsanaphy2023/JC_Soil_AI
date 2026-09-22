import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/geo_location_data.dart';
import '../models/ph_sensor_reading.dart';
import 'soil_telemetry_overlay_service.dart';

class SoilPhotoRecord {
  final String id;
  final String filePath;
  final double phCalibrated;
  final double phRaw;
  final double temperature;
  final double moisture;
  final int conductivity;
  final GeoLocationData? location;
  final DateTime timestamp;

  const SoilPhotoRecord({
    required this.id,
    required this.filePath,
    required this.phCalibrated,
    required this.phRaw,
    required this.temperature,
    required this.moisture,
    required this.conductivity,
    this.location,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'file_path': filePath,
        'ph_calibrated': phCalibrated,
        'ph_raw': phRaw,
        'temperature': temperature,
        'moisture': moisture,
        'conductivity': conductivity,
        'location': location?.toJson(),
        'timestamp': timestamp.toIso8601String(),
      };

  factory SoilPhotoRecord.fromJson(Map<String, dynamic> json) => SoilPhotoRecord(
        id: json['id'] as String,
        filePath: json['file_path'] as String,
        phCalibrated: (json['ph_calibrated'] as num).toDouble(),
        phRaw: (json['ph_raw'] as num).toDouble(),
        temperature: (json['temperature'] as num).toDouble(),
        moisture: (json['moisture'] as num).toDouble(),
        conductivity: (json['conductivity'] as num).toInt(),
        location: json['location'] != null
            ? GeoLocationData.fromJson(json['location'] as Map<String, dynamic>)
            : null,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class SoilDatasetService {
  SoilDatasetService._();

  static const String _folderName = 'soil_ph_dataset';
  static const String _manifestFile = 'ph_dataset_manifest.json';

  static Future<Directory> _getStorageDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_folderName/photos');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<File> _getManifestFile() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_folderName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File('${dir.path}/$_manifestFile');
  }

  /// Saves a captured photo with HUD telemetry burned into image
  static Future<SoilPhotoRecord> saveCapturedPhoto({
    required Uint8List rawImageBytes,
    required CalibratedPhResult result,
    GeoLocationData? location,
  }) async {
    // 1. Burn HUD Overlay
    final compositedBytes = await SoilTelemetryOverlayService.burnTelemetryOverlay(
      imageBytes: rawImageBytes,
      result: result,
      location: location,
    );

    // 2. Save Image File
    final dir = await _getStorageDir();
    final sampleId = 'SOIL_PH_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';
    final filePath = '${dir.path}/$sampleId.png';
    final file = File(filePath);
    await file.writeAsBytes(compositedBytes);

    // 3. Update Manifest
    final record = SoilPhotoRecord(
      id: sampleId,
      filePath: filePath,
      phCalibrated: result.phCalibrated,
      phRaw: result.rawReading.phRaw,
      temperature: result.rawReading.temperature,
      moisture: result.rawReading.moisture,
      conductivity: result.rawReading.conductivity,
      location: location,
      timestamp: DateTime.now(),
    );

    await _appendRecord(record);
    return record;
  }

  static Future<void> _appendRecord(SoilPhotoRecord record) async {
    final manifestFile = await _getManifestFile();
    List<Map<String, dynamic>> records = [];
    if (await manifestFile.exists()) {
      try {
        final content = await manifestFile.readAsString();
        final List<dynamic> decoded = jsonDecode(content);
        records = decoded.cast<Map<String, dynamic>>();
      } catch (_) {}
    }
    records.insert(0, record.toJson());
    await manifestFile.writeAsString(jsonEncode(records));
  }

  static Future<List<SoilPhotoRecord>> loadAllRecords() async {
    final manifestFile = await _getManifestFile();
    if (!await manifestFile.exists()) return [];
    try {
      final content = await manifestFile.readAsString();
      final List<dynamic> decoded = jsonDecode(content);
      return decoded.map((j) => SoilPhotoRecord.fromJson(j as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<int> getSampleCount() async {
    final records = await loadAllRecords();
    return records.length;
  }

  static Future<void> deleteRecord(SoilPhotoRecord record) async {
    try {
      final file = File(record.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}

    final manifestFile = await _getManifestFile();
    if (await manifestFile.exists()) {
      final records = await loadAllRecords();
      records.removeWhere((r) => r.id == record.id);
      await manifestFile.writeAsString(
        jsonEncode(records.map((r) => r.toJson()).toList()),
      );
    }
  }

  static Future<void> sharePhoto(SoilPhotoRecord record) async {
    final xFile = XFile(record.filePath);
    await Share.shareXFiles(
      [xFile],
      text: 'ข้อมูลภาพถ่ายดินพร้อมพิกัด GPS และค่า pH ชดเชยด้วย Deep Learning (PINN) รหัส ${record.id}',
    );
  }
}
