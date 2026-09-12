import 'package:flutter_test/flutter_test.dart';
import 'package:soil_app/data/models/soil_reading.dart';
import 'package:soil_app/domain/models/deep_learning_calibrator.dart';

void main() {
  group('DeepLearningCalibrator (PINN Model) Tests', () {
    test('compensates moisture and EC temperature effect at elevated temperature', () {
      // At 35°C (10°C above standard 25°C), water dielectric permittivity decreases
      // and raw EC is elevated due to ion mobility.
      final raw = SoilReading.mock(
        temp: 35.0,
        moist: 60.0,
        ec: 1000,
        phVal: 6.8,
      );

      final result = DeepLearningCalibrator.calibrate(raw);

      expect(result.calibratedReading, isNotNull);
      expect(result.confidenceScore, greaterThan(0.85));
      expect(result.modelName, equals('JC-SoilNet-v2.1 PINN'));

      // Moisture delta should compensate for dielectric temperature shift
      expect(result.moistureDelta, isNotNull);

      // Temperature delta should adjust for probe thermal conduction
      expect(result.temperatureDelta.abs(), lessThan(3.0));

      // EC should be normalized towards standard 25°C reference
      expect(result.calibratedReading.conductivity, lessThan(1000));
    });

    test('handles zero / initial reading gracefully', () {
      final initial = SoilReading.initial();
      final result = DeepLearningCalibrator.calibrate(initial);
      expect(result.confidenceScore, equals(0.0));
      expect(result.calibratedReading.temperature, equals(0.0));
    });
  });
}
