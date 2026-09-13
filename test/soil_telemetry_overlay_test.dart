import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:soil_app/data/models/geo_location_data.dart';
import 'package:soil_app/data/models/soil_reading.dart';
import 'package:soil_app/domain/models/deep_learning_calibrator.dart';
import 'package:soil_app/data/services/soil_telemetry_overlay_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SoilTelemetryOverlayService Tests', () {
    test('burnTelemetryOverlay composits HUD, GPS, and reticle onto image bytes', () async {
      // 1x1 transparent PNG image
      final png1x1 = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
        0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);

      final reading = SoilReading(
        moisture: 38.5,
        temperature: 27.2,
        conductivity: 512,
        ph: 6.35,
        nitrogen: 48,
        phosphorus: 24,
        potassium: 110,
        fertility: 182,
        timestamp: DateTime(2026, 9, 13, 12, 0, 0),
      );

      final calibrated = DeepLearningCalibrator.calibrate(reading);
      final location = GeoLocationData(
        latitude: 12.6083,
        longitude: 102.1154,
        altitude: 42.5,
        accuracy: 3.2,
        timestamp: DateTime(2026, 9, 13, 12, 0, 0),
      );

      final resultBytes = await SoilTelemetryOverlayService.burnTelemetryOverlay(
        imageBytes: png1x1,
        rawReading: reading,
        calibrated: calibrated,
        location: location,
      );

      expect(resultBytes, isNotNull);
      expect(resultBytes.isNotEmpty, isTrue);
      // Valid PNG header (0x89 0x50 0x4E 0x47)
      expect(resultBytes[0], 0x89);
      expect(resultBytes[1], 0x50);
      expect(resultBytes[2], 0x4E);
      expect(resultBytes[3], 0x47);
    });
  });
}
