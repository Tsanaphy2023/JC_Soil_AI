import 'package:flutter_test/flutter_test.dart';
import 'package:soil_app/data/models/soil_dataset_item.dart';

void main() {
  group('SoilDatasetItem & Video Telemetry Tests', () {
    test('verifies video dataset item creation and share caption branding', () {
      final now = DateTime.now();
      final item = SoilDatasetItem(
        sampleId: 'SAMPLE_VID_TEST_123',
        timestamp: now,
        mediaType: 'video',
        filePath: '/tmp/test_video.mp4',
        fileName: 'test_video.mp4',
        latitude: 12.62358,
        longitude: 102.17413,
        altitude: 5.3,
        durationSeconds: 15,
        temperature: 31.3,
        moisture: 36.9,
        conductivity: 35,
        ph: 4.49,
        nitrogen: 2,
        phosphorus: 3,
        potassium: 6,
        fertility: 25,
        aiMoisture: 36.7,
        aiConductivity: 35,
        aiPh: 4.49,
        aiConfidenceScore: 0.95,
      );

      expect(item.isVideo, isTrue);
      expect(item.isImage, isFalse);
      expect(item.durationSeconds, 15);

      final caption = item.toFormattedCaption();
      expect(caption, contains('JC SOIL AI ANALYZER'));
      expect(caption, contains('SciRBRU AgriPhysics'));
      expect(caption, contains('12.62358° N, 102.17413° E'));
      expect(caption, contains('36.9 %'));
      expect(caption, contains('4.49'));
      expect(caption, contains('ความยาวคลิป: 15 วินาที'));
    });
  });
}
