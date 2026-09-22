import 'package:flutter_test/flutter_test.dart';
import 'package:soil_app/data/models/soil_reading.dart';
import 'package:soil_app/data/services/multi_color_space_service.dart';
import 'package:soil_app/domain/models/soil_multimodal_deep_model.dart';

void main() {
  group('MultiColorSpaceService Tests', () {
    test('Calculates RGB, HSV, CIE Lab and YCbCr accurately', () {
      final metric = MultiColorSpaceService.fromRgb(230, 57, 70); // #E63946
      expect(metric.r, 230);
      expect(metric.g, 57);
      expect(metric.b, 70);
      expect(metric.hue, greaterThanOrEqualTo(350.0));
      expect(metric.saturation, greaterThan(0.7));
      expect(metric.labL, greaterThan(40.0));
      expect(metric.hexString, '#E63946');
    });

    test('DeltaE calculation between identical colors is zero', () {
      final m1 = MultiColorSpaceService.fromRgb(100, 150, 200);
      final m2 = MultiColorSpaceService.fromRgb(100, 150, 200);
      expect(m1.deltaE(m2), closeTo(0.0, 0.001));
    });
  });

  group('SoilMultimodalDeepModel Inference Tests', () {
    test('Evaluates acidic soil color with probe pH agreement', () {
      final metric = MultiColorSpaceService.fromRgb(230, 57, 70); // Table 2.3 Tier 1 (< 4.5)
      final sensor = SoilReading(
        temperature: 26.5,
        moisture: 42.0,
        conductivity: 620,
        ph: 4.20,
        nitrogen: 18,
        phosphorus: 8,
        potassium: 55,
        fertility: 1,
        timestamp: DateTime.now(),
      );

      final result = SoilMultimodalDeepModel.infer(
        visionMetric: metric,
        sensorReading: sensor,
      );

      expect(result.visionPh, closeTo(4.2, 0.6));
      expect(result.sensorPh, 4.20);
      expect(result.deltaPh, lessThan(0.8));
      expect(result.soilOrganicMatterPct, greaterThan(1.0));
      expect(result.consistencyScore, greaterThan(0.70));
    });

    test('Evaluates neutral organic soil with high SOM', () {
      final darkSoilMetric = MultiColorSpaceService.fromRgb(45, 35, 28); // Dark high-organic soil
      final sensor = SoilReading(
        temperature: 25.0,
        moisture: 55.0,
        conductivity: 450,
        ph: 6.85,
        nitrogen: 45,
        phosphorus: 25,
        potassium: 140,
        fertility: 2,
        timestamp: DateTime.now(),
      );

      final result = SoilMultimodalDeepModel.infer(
        visionMetric: darkSoilMetric,
        sensorReading: sensor,
      );

      expect(result.soilOrganicMatterPct, greaterThan(3.0));
      expect(result.predictedNitrogen, greaterThan(20));
      expect(result.predictedPhosphorus, greaterThan(10));
      expect(result.predictedPotassium, greaterThan(80));
    });
  });
}
