import 'package:flutter_test/flutter_test.dart';
import 'package:soil_app/data/models/soil_dataset_item.dart';
import 'package:soil_app/data/services/soil_dataset_service.dart';

void main() {
  group('SoilDatasetItem Tests', () {
    test('serializes and deserializes json correctly with GPS and AI telemetry', () {
      final now = DateTime(2026, 9, 13, 12, 30, 0);
      final item = SoilDatasetItem(
        sampleId: 'SAMPLE_1789274000',
        timestamp: now,
        mediaType: 'image',
        filePath: '/storage/emulated/0/Android/data/com.agriphysics.soil_app/files/soil_dataset/images/SOIL_IMG_01.jpg',
        fileName: 'SOIL_IMG_01.jpg',
        latitude: 12.6083,
        longitude: 102.1154,
        altitude: 42.5,
        temperature: 28.5,
        moisture: 45.2,
        conductivity: 620,
        ph: 6.45,
        nitrogen: 55,
        phosphorus: 28,
        potassium: 115,
        fertility: 198,
        aiMoisture: 44.8,
        aiConductivity: 615,
        aiPh: 6.48,
        aiConfidenceScore: 0.965,
      );

      final json = item.toJson();
      expect(json['sample_id'], 'SAMPLE_1789274000');
      expect(json['media_type'], 'image');
      expect(json['gps']['latitude'], 12.6083);
      expect(json['sensor_ground_truth']['ph'], 6.45);
      expect(json['ai_pinn_calibrated']['confidence_score'], 0.965);

      final reconstructed = SoilDatasetItem.fromJson(json);
      expect(reconstructed.sampleId, item.sampleId);
      expect(reconstructed.mediaType, 'image');
      expect(reconstructed.latitude, 12.6083);
      expect(reconstructed.longitude, 102.1154);
      expect(reconstructed.altitude, 42.5);
      expect(reconstructed.ph, 6.45);
      expect(reconstructed.conductivity, 620);
      expect(reconstructed.aiConfidenceScore, 0.965);
      expect(reconstructed.isImage, isTrue);
      expect(reconstructed.isVideo, isFalse);
    });

    test('generates comprehensive caption for sharing to LINE/Social', () {
      final now = DateTime(2026, 9, 13, 12, 30, 0);
      final item = SoilDatasetItem(
        sampleId: 'SAMPLE_101',
        timestamp: now,
        mediaType: 'image',
        filePath: '/dummy/path.jpg',
        fileName: 'path.jpg',
        latitude: 12.6083,
        longitude: 102.1154,
        altitude: 42.5,
        temperature: 29.0,
        moisture: 40.0,
        conductivity: 500,
        ph: 6.5,
        nitrogen: 50,
        phosphorus: 25,
        potassium: 120,
        fertility: 195,
        aiConfidenceScore: 0.98,
      );

      final caption = item.toFormattedCaption();
      expect(caption, contains('SOIL AI ANALYZER'));
      expect(caption, contains('SAMPLE_101'));
      expect(caption, contains('12.60830° N'));
      expect(caption, contains('102.11540° E'));
      expect(caption, contains('42.5 เมตร'));
      expect(caption, contains('google.com/maps'));
      expect(caption, contains('(pH): 6.50'));
      expect(caption, contains('98.0%'));
    });

    test('formats GPS coordinates and maps URL correctly', () {
      final item = SoilDatasetItem(
        sampleId: 'SAMPLE_102',
        timestamp: DateTime.now(),
        mediaType: 'video',
        filePath: '/dummy/vid.mp4',
        fileName: 'vid.mp4',
        latitude: 13.7563,
        longitude: 100.5018,
        altitude: 15.0,
        durationSeconds: 12,
        temperature: 30.0,
        moisture: 50.0,
        conductivity: 400,
        ph: 7.0,
        nitrogen: 40,
        phosphorus: 20,
        potassium: 100,
        fertility: 160,
      );

      expect(item.isVideo, isTrue);
      expect(item.isImage, isFalse);
      expect(item.durationSeconds, 12);
      expect(item.formattedGps, contains('13.75630°'));
      expect(item.formattedGps, contains('100.50180°'));
      expect(item.googleMapsUrl, contains('13.7563,100.5018'));
    });
  });

  group('SoilDataset Subfolder Organization & DataFile Tests', () {
    test('verifies subfolder naming conventions for images, videos, and data', () {
      expect(SoilDatasetService.datasetFolder, 'soil_dataset');
      expect(SoilDatasetService.imagesFolder, 'images');
      expect(SoilDatasetService.videosFolder, 'videos');
      expect(SoilDatasetService.dataFolder, 'data');
      expect(SoilDatasetService.manifestFileName, 'dataset_manifest.json');
    });

    test('SoilDataFileInfo calculates size and formats date correctly', () {
      final modified = DateTime(2026, 9, 13, 14, 30, 0);
      final dataFile = SoilDataFileInfo(
        fileName: 'Soil_parameters_20260913_143000.csv',
        filePath: '/mock/soil_dataset/data/Soil_parameters_20260913_143000.csv',
        fileSizeBytes: 2048,
        modified: modified,
        fileType: 'csv',
      );

      expect(dataFile.isCsv, isTrue);
      expect(dataFile.isJson, isFalse);
      expect(dataFile.formattedSize, '2.0 KB');
      expect(dataFile.formattedDate, '2026-09-13 14:30');
    });

    test('SoilDataFileInfo identifies JSON manifest file', () {
      final modified = DateTime(2026, 9, 13, 15, 0, 0);
      final manifestInfo = SoilDataFileInfo(
        fileName: 'dataset_manifest.json',
        filePath: '/mock/soil_dataset/data/dataset_manifest.json',
        fileSizeBytes: 524288,
        modified: modified,
        fileType: 'json',
      );

      expect(manifestInfo.isCsv, isFalse);
      expect(manifestInfo.isJson, isTrue);
      expect(manifestInfo.formattedSize, '512.0 KB');
    });
  });
}
