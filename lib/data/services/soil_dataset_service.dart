import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/soil_reading.dart';
import '../models/soil_dataset_item.dart';
import '../../domain/models/deep_learning_calibrator.dart';

/// Service for managing AI Dataset storage (images, videos, and labeled ground-truth metadata)
/// and providing smartphone retrieval, inspection, and sharing capabilities.
class SoilDatasetService {
  SoilDatasetService._();

  static const String datasetFolder = 'soil_dataset';
  static const String imagesFolder = 'images';
  static const String videosFolder = 'videos';
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

  static Future<Directory> getImagesDirectory() async {
    final baseDir = await getDatasetDirectory();
    final imgDir = Directory('${baseDir.path}/$imagesFolder');
    if (!await imgDir.exists()) {
      await imgDir.create(recursive: true);
    }
    return imgDir;
  }

  static Future<Directory> getVideosDirectory() async {
    final baseDir = await getDatasetDirectory();
    final vidDir = Directory('${baseDir.path}/$videosFolder');
    if (!await vidDir.exists()) {
      await vidDir.create(recursive: true);
    }
    return vidDir;
  }

  static Future<File> getManifestFile() async {
    final baseDir = await getDatasetDirectory();
    return File('${baseDir.path}/$manifestFileName');
  }

  /// Save captured soil photo and register sample in AI training dataset manifest
  static Future<String> savePhotoSample({
    required XFile photo,
    required SoilReading rawReading,
    required CalibratedSoilResult calibrated,
  }) async {
    final imgDir = await getImagesDirectory();
    final now = DateTime.now();
    final timeStr = now.toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final lat = rawReading.latitude?.toStringAsFixed(4) ?? '0.0';
    final lon = rawReading.longitude?.toStringAsFixed(4) ?? '0.0';
    final fileName = 'SOIL_IMG_${timeStr}_LAT${lat}_LON${lon}.jpg';
    final savedFile = File('${imgDir.path}/$fileName');

    await photo.saveTo(savedFile.path);

    final item = SoilDatasetItem(
      sampleId: 'SAMPLE_${now.millisecondsSinceEpoch}',
      timestamp: now,
      mediaType: 'image',
      filePath: savedFile.path,
      fileName: fileName,
      latitude: rawReading.latitude ?? 0.0,
      longitude: rawReading.longitude ?? 0.0,
      altitude: rawReading.altitude ?? 0.0,
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
    debugPrint('[SoilDatasetService] Saved training photo: ${savedFile.path}');
    return savedFile.path;
  }

  /// Save recorded soil video and register sample in AI training dataset manifest
  static Future<String> saveVideoSample({
    required XFile video,
    required SoilReading rawReading,
    required CalibratedSoilResult calibrated,
    required int durationSeconds,
  }) async {
    final vidDir = await getVideosDirectory();
    final now = DateTime.now();
    final timeStr = now.toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final lat = rawReading.latitude?.toStringAsFixed(4) ?? '0.0';
    final lon = rawReading.longitude?.toStringAsFixed(4) ?? '0.0';
    final fileName = 'SOIL_VID_${timeStr}_LAT${lat}_LON${lon}.mp4';
    final savedFile = File('${vidDir.path}/$fileName');

    await video.saveTo(savedFile.path);

    final item = SoilDatasetItem(
      sampleId: 'SAMPLE_${now.millisecondsSinceEpoch}',
      timestamp: now,
      mediaType: 'video',
      filePath: savedFile.path,
      fileName: fileName,
      latitude: rawReading.latitude ?? 0.0,
      longitude: rawReading.longitude ?? 0.0,
      altitude: rawReading.altitude ?? 0.0,
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
      text: 'ชุดข้อมูลตัวอย่างดินวิจัย (${validFiles.length} รายการ) - SOIL AI ANALYZER',
      subject: 'Soil AI Dataset Export',
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

  /// Calculate summary stats for the dataset
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
      'geotagged': geotaggedCount,
      'totalBytes': totalBytes,
      'formattedSize': formattedSize,
    };
  }
}
