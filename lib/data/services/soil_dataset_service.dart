import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/geo_location_data.dart';
import '../models/soil_reading.dart';
import '../models/soil_dataset_item.dart';
import '../../domain/models/deep_learning_calibrator.dart';
import 'soil_telemetry_overlay_service.dart';

/// Service for managing AI Dataset storage (images, videos, and labeled ground-truth metadata)
/// and providing smartphone retrieval, inspection, and sharing capabilities.
class SoilDatasetService {
  SoilDatasetService._();

  static const String datasetFolder = 'soil_dataset';
  static const String imagesFolder = 'images';
  static const String videosFolder = 'videos';
  static const String dataFolder = 'data';
  static const String manifestFileName = 'dataset_manifest.json';

  /// Get or create base dataset directories (prefers External Storage on Android for easy MTP/file access)
  static Future<Directory> getDatasetDirectory() async {
    Directory? baseDir;
    try {
      if (Platform.isAndroid) {
        baseDir = await getExternalStorageDirectory();
      }
    } catch (_) {}
    baseDir ??= await getApplicationDocumentsDirectory();

    final targetDir = Directory('${baseDir.path}/$datasetFolder');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    return targetDir;
  }

  /// Subfolder 1: Images (JPEG photos with real-time HUD telemetry overlays)
  static Future<Directory> getImagesDirectory() async {
    final baseDir = await getDatasetDirectory();
    final imgDir = Directory('${baseDir.path}/$imagesFolder');
    if (!await imgDir.exists()) {
      await imgDir.create(recursive: true);
    }
    return imgDir;
  }

  /// Subfolder 2: Videos (MP4 video streams and SRT synchronized subtitle telemetries)
  static Future<Directory> getVideosDirectory() async {
    final baseDir = await getDatasetDirectory();
    final vidDir = Directory('${baseDir.path}/$videosFolder');
    if (!await vidDir.exists()) {
      await vidDir.create(recursive: true);
    }
    return vidDir;
  }

  /// Subfolder 3: Data (CSV logs, telemetry records, and dataset manifest JSON)
  static Future<Directory> getDataDirectory() async {
    final baseDir = await getDatasetDirectory();
    final dataDir = Directory('${baseDir.path}/$dataFolder');
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }
    return dataDir;
  }

  static Future<File> getManifestFile() async {
    final dataDir = await getDataDirectory();
    final fileInData = File('${dataDir.path}/$manifestFileName');
    if (await fileInData.exists()) {
      return fileInData;
    }
    final baseDir = await getDatasetDirectory();
    final fileInBase = File('${baseDir.path}/$manifestFileName');
    if (await fileInBase.exists()) {
      try {
        await fileInBase.copy(fileInData.path);
        await fileInBase.delete();
      } catch (_) {}
      return fileInData;
    }
    return fileInData;
  }

  /// Save captured soil photo and register sample in AI training dataset manifest
  static Future<String> savePhotoSample({
    required XFile photo,
    required SoilReading rawReading,
    required CalibratedSoilResult calibrated,
    GeoLocationData? location,
  }) async {
    final imgDir = await getImagesDirectory();
    final now = DateTime.now();
    final timeStr = now.toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final latVal = location?.latitude ?? rawReading.latitude;
    final lonVal = location?.longitude ?? rawReading.longitude;
    final altVal = location?.altitude ?? rawReading.altitude ?? 0.0;
    final lat = latVal?.toStringAsFixed(4) ?? '0.0';
    final lon = lonVal?.toStringAsFixed(4) ?? '0.0';
    final fileName = 'SOIL_IMG_${timeStr}_LAT${lat}_LON$lon.jpg';
    final savedFile = File('${imgDir.path}/$fileName');

    // Burn real-time HUD telemetry, GPS, and targeting reticle onto the photo
    try {
      final rawBytes = await photo.readAsBytes();
      final compositedBytes = await SoilTelemetryOverlayService.burnTelemetryOverlay(
        imageBytes: rawBytes,
        rawReading: rawReading,
        calibrated: calibrated,
        location: location,
      );
      await savedFile.writeAsBytes(compositedBytes);
    } catch (e) {
      debugPrint('[SoilDatasetService] Overlay burn-in fallback to raw photo: $e');
      await photo.saveTo(savedFile.path);
    }

    final item = SoilDatasetItem(
      sampleId: 'SAMPLE_${now.millisecondsSinceEpoch}',
      timestamp: now,
      mediaType: 'image',
      filePath: savedFile.path,
      fileName: fileName,
      latitude: latVal ?? 0.0,
      longitude: lonVal ?? 0.0,
      altitude: altVal,
      temperature: rawReading.temperature,
      moisture: rawReading.moisture,
      conductivity: rawReading.conductivity,
      ph: rawReading.ph,
      nitrogen: rawReading.nitrogen,
      phosphorus: rawReading.phosphorus,
      potassium: rawReading.potassium,
      fertility: rawReading.fertility,
      aiMoisture: calibrated.calibratedReading.moisture,
      aiConductivity: calibrated.calibratedReading.conductivity,
      aiPh: calibrated.calibratedReading.ph,
      aiNitrogen: calibrated.calibratedReading.nitrogen,
      aiPhosphorus: calibrated.calibratedReading.phosphorus,
      aiPotassium: calibrated.calibratedReading.potassium,
      aiConfidenceScore: calibrated.confidenceScore,
    );

    await _appendManifest(item.toJson());
    return savedFile.path;
  }

  /// Save recorded soil video and register sample in AI training dataset manifest
  static Future<String> saveVideoSample({
    required XFile video,
    required SoilReading rawReading,
    required CalibratedSoilResult calibrated,
    required int durationSeconds,
    GeoLocationData? location,
  }) async {
    final vidDir = await getVideosDirectory();
    final now = DateTime.now();
    final timeStr = now.toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final latVal = location?.latitude ?? rawReading.latitude;
    final lonVal = location?.longitude ?? rawReading.longitude;
    final altVal = location?.altitude ?? rawReading.altitude ?? 0.0;
    final lat = latVal?.toStringAsFixed(4) ?? '0.0';
    final lon = lonVal?.toStringAsFixed(4) ?? '0.0';
    final fileName = 'SOIL_VID_${timeStr}_LAT${lat}_LON$lon.mp4';
    final savedFile = File('${vidDir.path}/$fileName');

    await video.saveTo(savedFile.path);

    // Also write synchronized SRT telemetry subtitle alongside MP4 for external players
    try {
      final srtPath = savedFile.path.replaceAll('.mp4', '.srt');
      final srtFile = File(srtPath);
      final dur = durationSeconds > 0 ? durationSeconds : 5;
      final durMin = (dur ~/ 60).toString().padLeft(2, '0');
      final durSec = (dur % 60).toString().padLeft(2, '0');
      final srtContent = '''1
00:00:00,000 --> $durMin:$durSec,000
🌱 JC SOIL AI ANALYZER | SciRBRU AgriPhysics
📍 GPS: ${latVal?.toStringAsFixed(5) ?? '0.0'}° N, ${lonVal?.toStringAsFixed(5) ?? '0.0'}° E (Alt: ${altVal.toStringAsFixed(1)}m)
ความชื้น: ${rawReading.moisture.toStringAsFixed(1)}% | อุณหภูมิ: ${rawReading.temperature.toStringAsFixed(1)}°C | EC: ${rawReading.conductivity} µS/cm | pH: ${rawReading.ph.toStringAsFixed(2)}
N-P-K: ${rawReading.nitrogen}-${rawReading.phosphorus}-${rawReading.potassium} mg/kg | Fertility: ${rawReading.fertility}
🤖 AI PINN: pH ${calibrated.calibratedReading.ph.toStringAsFixed(2)} | EC ${calibrated.calibratedReading.conductivity}µS | Moist ${calibrated.calibratedReading.moisture.toStringAsFixed(1)}%
''';
      await srtFile.writeAsString(srtContent);
    } catch (_) {}

    final item = SoilDatasetItem(
      sampleId: 'SAMPLE_${now.millisecondsSinceEpoch}',
      timestamp: now,
      mediaType: 'video',
      filePath: savedFile.path,
      fileName: fileName,
      latitude: latVal ?? 0.0,
      longitude: lonVal ?? 0.0,
      altitude: altVal,
      durationSeconds: durationSeconds,
      temperature: rawReading.temperature,
      moisture: rawReading.moisture,
      conductivity: rawReading.conductivity,
      ph: rawReading.ph,
      nitrogen: rawReading.nitrogen,
      phosphorus: rawReading.phosphorus,
      potassium: rawReading.potassium,
      fertility: rawReading.fertility,
      aiMoisture: calibrated.calibratedReading.moisture,
      aiConductivity: calibrated.calibratedReading.conductivity,
      aiPh: calibrated.calibratedReading.ph,
      aiNitrogen: calibrated.calibratedReading.nitrogen,
      aiPhosphorus: calibrated.calibratedReading.phosphorus,
      aiPotassium: calibrated.calibratedReading.potassium,
      aiConfidenceScore: calibrated.confidenceScore,
    );

    await _appendManifest(item.toJson());
    debugPrint('[SoilDatasetService] Saved training video: ${savedFile.path}');
    return savedFile.path;
  }

  static Future<void> _appendManifest(Map<String, dynamic> record) async {
    try {
      final file = await getManifestFile();
      List<dynamic> items = [];
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          items = jsonDecode(content) as List<dynamic>;
        }
      }
      items.add(record);
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(items));
    } catch (e) {
      debugPrint('[SoilDatasetService] Error updating manifest: $e');
    }
  }

  /// Retrieve all recorded dataset items with ground-truth and AI metrics (newest first)
  /// If the manifest is missing or incomplete, automatically scans directories as a fallback.
  static Future<List<SoilDatasetItem>> getAllDatasetItems() async {
    final results = <SoilDatasetItem>[];
    final knownPaths = <String>{};

    try {
      final file = await getManifestFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final list = jsonDecode(content) as List<dynamic>;
          for (final raw in list) {
            if (raw is Map<String, dynamic>) {
              final item = SoilDatasetItem.fromJson(raw);
              results.add(item);
              knownPaths.add(item.filePath);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[SoilDatasetService] Error reading manifest: $e');
    }

    // Fallback directory scan for any orphan images/videos not listed in manifest
    try {
      final imgDir = await getImagesDirectory();
      if (await imgDir.exists()) {
        final entities = imgDir.listSync();
        for (final entity in entities) {
          if (entity is File && !knownPaths.contains(entity.path)) {
            final fileName = entity.path.split(Platform.pathSeparator).last;
            if (fileName.toLowerCase().endsWith('.jpg') || fileName.toLowerCase().endsWith('.png')) {
              final stat = entity.statSync();
              results.add(SoilDatasetItem(
                sampleId: 'IMG_${stat.modified.millisecondsSinceEpoch}',
                timestamp: stat.modified,
                mediaType: 'image',
                filePath: entity.path,
                fileName: fileName,
                latitude: 0.0,
                longitude: 0.0,
                altitude: 0.0,
                temperature: 0.0,
                moisture: 0.0,
                conductivity: 0,
                ph: 7.0,
                nitrogen: 0,
                phosphorus: 0,
                potassium: 0,
                fertility: 0,
              ));
              knownPaths.add(entity.path);
            }
          }
        }
      }

      final vidDir = await getVideosDirectory();
      if (await vidDir.exists()) {
        final entities = vidDir.listSync();
        for (final entity in entities) {
          if (entity is File && !knownPaths.contains(entity.path)) {
            final fileName = entity.path.split(Platform.pathSeparator).last;
            if (fileName.toLowerCase().endsWith('.mp4')) {
              final stat = entity.statSync();
              results.add(SoilDatasetItem(
                sampleId: 'VID_${stat.modified.millisecondsSinceEpoch}',
                timestamp: stat.modified,
                mediaType: 'video',
                filePath: entity.path,
                fileName: fileName,
                latitude: 0.0,
                longitude: 0.0,
                altitude: 0.0,
                temperature: 0.0,
                moisture: 0.0,
                conductivity: 0,
                ph: 7.0,
                nitrogen: 0,
                phosphorus: 0,
                potassium: 0,
                fertility: 0,
              ));
              knownPaths.add(entity.path);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[SoilDatasetService] Directory scan error: $e');
    }

    // Sort newest first
    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return results;
  }

  /// Delete a dataset item file from disk and remove its manifest entry
  static Future<bool> deleteDatasetItem(SoilDatasetItem item) async {
    try {
      // 1. Delete physical file
      final file = File(item.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // If video, also delete matching .srt subtitle file
      if (item.isVideo || item.filePath.toLowerCase().endsWith('.mp4')) {
        final srtPath = item.filePath.replaceAll(RegExp(r'\.mp4$', caseSensitive: false), '.srt');
        final srtFile = File(srtPath);
        if (await srtFile.exists()) {
          await srtFile.delete();
        }
      }

      // 2. Remove from manifest
      final manifestFile = await getManifestFile();
      if (await manifestFile.exists()) {
        final content = await manifestFile.readAsString();
        if (content.isNotEmpty) {
          final list = jsonDecode(content) as List<dynamic>;
          final updated = list.where((entry) {
            if (entry is Map<String, dynamic>) {
              return entry['sample_id'] != item.sampleId && entry['file_path'] != item.filePath;
            }
            return true;
          }).toList();
          await manifestFile.writeAsString(const JsonEncoder.withIndent('  ').convert(updated));
        }
      }
      return true;
    } catch (e) {
      debugPrint('[SoilDatasetService] Delete item error: $e');
      return false;
    }
  }

  /// Delete multiple dataset items in a batch (both files, SRTs, and manifest entries)
  static Future<int> deleteMultipleItems(List<SoilDatasetItem> items) async {
    if (items.isEmpty) return 0;
    int deletedCount = 0;
    final itemSampleIds = items.map((e) => e.sampleId).toSet();
    final itemPaths = items.map((e) => e.filePath).toSet();

    for (final item in items) {
      try {
        final file = File(item.filePath);
        if (await file.exists()) {
          await file.delete();
        }
        if (item.isVideo || item.filePath.toLowerCase().endsWith('.mp4')) {
          final srtPath = item.filePath.replaceAll(RegExp(r'\.mp4$', caseSensitive: false), '.srt');
          final srtFile = File(srtPath);
          if (await srtFile.exists()) {
            await srtFile.delete();
          }
        }
        deletedCount++;
      } catch (e) {
        debugPrint('[SoilDatasetService] Error deleting ${item.filePath}: $e');
      }
    }

    // Batch update manifest in one write operation
    try {
      final manifestFile = await getManifestFile();
      if (await manifestFile.exists()) {
        final content = await manifestFile.readAsString();
        if (content.isNotEmpty) {
          final list = jsonDecode(content) as List<dynamic>;
          final updated = list.where((entry) {
            if (entry is Map<String, dynamic>) {
              final sid = entry['sample_id'];
              final fpath = entry['file_path'];
              return !itemSampleIds.contains(sid) && !itemPaths.contains(fpath);
            }
            return true;
          }).toList();
          await manifestFile.writeAsString(const JsonEncoder.withIndent('  ').convert(updated));
        }
      }
    } catch (e) {
      debugPrint('[SoilDatasetService] Error batch updating manifest: $e');
    }

    return deletedCount;
  }

  /// Share a single dataset item (image or video) with comprehensive agronomic caption
  static Future<void> shareItem(SoilDatasetItem item) async {
    final file = File(item.filePath);
    if (!await file.exists()) {
      throw Exception('ไฟล์ตัวอย่างไม่พบบนหน่วยความจำ: ${item.fileName}');
    }

    await Share.shareXFiles(
      [XFile(item.filePath)],
      text: item.toFormattedCaption(),
      subject: 'Soil AI Sample [${item.sampleId}]',
    );
  }

  /// Share multiple dataset items in a batch
  static Future<void> shareMultipleItems(List<SoilDatasetItem> items) async {
    final validFiles = <XFile>[];
    for (final item in items) {
      if (File(item.filePath).existsSync()) {
        validFiles.add(XFile(item.filePath));
      }
    }

    if (validFiles.isEmpty) return;

    await Share.shareXFiles(
      validFiles,
      text: 'ชุดข้อมูลตัวอย่างดินวิจัย (${validFiles.length} รายการ) - JC SOIL AI ANALYZER | SciRBRU AgriPhysics',
      subject: 'JC Soil AI Dataset Export',
    );
  }

  /// Share entire dataset bundle (Manifest JSON + Images/Videos)
  static Future<void> shareFullDatasetPackage() async {
    final manifestFile = await getManifestFile();
    final items = await getAllDatasetItems();

    final filesToShare = <XFile>[];
    if (await manifestFile.exists()) {
      filesToShare.add(XFile(manifestFile.path));
    }

    for (final item in items.take(15)) {
      if (File(item.filePath).existsSync()) {
        filesToShare.add(XFile(item.filePath));
      }
    }

    if (filesToShare.isEmpty) {
      throw Exception('ไม่พบชุดข้อมูลสำหรับแชร์');
    }

    await Share.shareXFiles(
      filesToShare,
      text: '📦 ชุดข้อมูล AI ดินครบชุด (Manifest + ภาพ/วิดีโอ) สำหรับการฝึกฝนโมเดล AI\nพัฒนาโดย: มหาวิทยาลัยราชภัฏรำไพพรรณี',
      subject: 'Full Soil AI Dataset Package',
    );
  }

  /// Get total count of saved multimodal samples
  static Future<int> getSampleCount() async {
    try {
      final items = await getAllDatasetItems();
      return items.length;
    } catch (_) {
      return 0;
    }
  }

  /// List all telemetry data files (CSV, JSON) stored in soil_dataset/data/
  static Future<List<SoilDataFileInfo>> getAllDataFiles() async {
    final results = <SoilDataFileInfo>[];
    try {
      final dataDir = await getDataDirectory();
      if (await dataDir.exists()) {
        final entities = dataDir.listSync();
        for (final entity in entities) {
          if (entity is File) {
            final fileName = entity.path.split(Platform.pathSeparator).last;
            if (!fileName.startsWith('.')) {
              final stat = entity.statSync();
              final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
              results.add(SoilDataFileInfo(
                fileName: fileName,
                filePath: entity.path,
                fileSizeBytes: stat.size,
                modified: stat.modified,
                fileType: ext,
              ));
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[SoilDatasetService] Error listing data files: $e');
    }
    // Newest first
    results.sort((a, b) => b.modified.compareTo(a.modified));
    return results;
  }

  /// Delete an exported data file from soil_dataset/data/
  static Future<bool> deleteDataFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      debugPrint('[SoilDatasetService] Error deleting data file: $e');
    }
    return false;
  }

  /// Share a data file (CSV, JSON)
  static Future<void> shareDataFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('ไม่พบไฟล์ข้อมูล: $filePath');
    }
    final fileName = filePath.split(Platform.pathSeparator).last;
    await Share.shareXFiles(
      [XFile(filePath)],
      text: '📊 ไฟล์ข้อมูลการตรวจวัดดิน: $fileName\n🌱 JC SOIL AI ANALYZER | SciRBRU AgriPhysics',
      subject: 'Soil Data Export [$fileName]',
    );
  }

  /// Calculate summary stats for the dataset across all subfolders (images, videos, data)
  static Future<Map<String, dynamic>> getDatasetStats() async {
    final items = await getAllDatasetItems();
    int imgCount = 0;
    int vidCount = 0;
    int totalBytes = 0;
    int geotaggedCount = 0;

    for (final item in items) {
      if (item.isImage) imgCount++;
      if (item.isVideo) vidCount++;
      if (item.latitude != 0.0 || item.longitude != 0.0) geotaggedCount++;
      totalBytes += item.fileSizeBytes;
    }

    int dataFilesCount = 0;
    try {
      final dataFiles = await getAllDataFiles();
      dataFilesCount = dataFiles.length;
      for (final df in dataFiles) {
        totalBytes += df.fileSizeBytes;
      }
    } catch (_) {}

    String formattedSize = '0 MB';
    if (totalBytes < 1024 * 1024) {
      formattedSize = '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      formattedSize = '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return {
      'total': items.length,
      'images': imgCount,
      'videos': vidCount,
      'dataFiles': dataFilesCount,
      'geotagged': geotaggedCount,
      'totalBytes': totalBytes,
      'formattedSize': formattedSize,
      'subfolderPath': 'soil_dataset/ (images, videos, data)',
    };
  }
}

/// Metadata model for files stored in soil_dataset/data/ (CSV logs, JSON manifest, etc.)
class SoilDataFileInfo {
  final String fileName;
  final String filePath;
  final int fileSizeBytes;
  final DateTime modified;
  final String fileType; // 'csv', 'json', etc.

  const SoilDataFileInfo({
    required this.fileName,
    required this.filePath,
    required this.fileSizeBytes,
    required this.modified,
    required this.fileType,
  });

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    return '${modified.year}-${modified.month.toString().padLeft(2, '0')}-${modified.day.toString().padLeft(2, '0')} '
        '${modified.hour.toString().padLeft(2, '0')}:${modified.minute.toString().padLeft(2, '0')}';
  }

  bool get isCsv => fileType.toLowerCase() == 'csv';
  bool get isJson => fileType.toLowerCase() == 'json';
}
