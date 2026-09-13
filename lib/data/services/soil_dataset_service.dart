import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/soil_reading.dart';
import '../../domain/models/deep_learning_calibrator.dart';

/// Service for managing AI Dataset storage (images, videos, and labeled ground-truth metadata)
class SoilDatasetService {
  SoilDatasetService._();

  static const String datasetFolder = 'soil_dataset';
  static const String imagesFolder = 'images';
  static const String videosFolder = 'videos';
  static const String manifestFileName = 'dataset_manifest.json';

  /// Get or create base dataset directories
  static Future<Directory> getDatasetDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final baseDir = Directory('${docsDir.path}/$datasetFolder');
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }
    return baseDir;
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

    final record = {
      'sample_id': 'SAMPLE_${now.millisecondsSinceEpoch}',
      'timestamp': now.toIso8601String(),
      'media_type': 'image',
      'file_path': savedFile.path,
      'file_name': fileName,
      'gps': {
        'latitude': rawReading.latitude ?? 0.0,
        'longitude': rawReading.longitude ?? 0.0,
        'altitude': rawReading.altitude ?? 0.0,
      },
      'sensor_ground_truth': {
        'temperature': rawReading.temperature,
        'moisture': rawReading.moisture,
        'conductivity_ec': rawReading.conductivity,
        'ph': rawReading.ph,
        'nitrogen': rawReading.nitrogen,
        'phosphorus': rawReading.phosphorus,
        'potassium': rawReading.potassium,
        'fertility': rawReading.fertility,
      },
      'ai_pinn_calibrated': {
        'moisture': calibrated.calibratedReading.moisture,
        'conductivity_ec': calibrated.calibratedReading.conductivity,
        'ph': calibrated.calibratedReading.ph,
        'nitrogen': calibrated.calibratedReading.nitrogen,
        'phosphorus': calibrated.calibratedReading.phosphorus,
        'potassium': calibrated.calibratedReading.potassium,
        'confidence_score': calibrated.confidenceScore,
      },
    };

    await _appendManifest(record);
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

    final record = {
      'sample_id': 'SAMPLE_${now.millisecondsSinceEpoch}',
      'timestamp': now.toIso8601String(),
      'media_type': 'video',
      'duration_seconds': durationSeconds,
      'file_path': savedFile.path,
      'file_name': fileName,
      'gps': {
        'latitude': rawReading.latitude ?? 0.0,
        'longitude': rawReading.longitude ?? 0.0,
        'altitude': rawReading.altitude ?? 0.0,
      },
      'sensor_ground_truth': {
        'temperature': rawReading.temperature,
        'moisture': rawReading.moisture,
        'conductivity_ec': rawReading.conductivity,
        'ph': rawReading.ph,
        'nitrogen': rawReading.nitrogen,
        'phosphorus': rawReading.phosphorus,
        'potassium': rawReading.potassium,
        'fertility': rawReading.fertility,
      },
      'ai_pinn_calibrated': {
        'moisture': calibrated.calibratedReading.moisture,
        'conductivity_ec': calibrated.calibratedReading.conductivity,
        'ph': calibrated.calibratedReading.ph,
        'confidence_score': calibrated.confidenceScore,
      },
    };

    await _appendManifest(record);
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

  /// Get total count of saved multimodal samples
  static Future<int> getSampleCount() async {
    try {
      final file = await getManifestFile();
      if (!await file.exists()) return 0;
      final content = await file.readAsString();
      if (content.isEmpty) return 0;
      final list = jsonDecode(content) as List<dynamic>;
      return list.length;
    } catch (_) {
      return 0;
    }
  }
}
