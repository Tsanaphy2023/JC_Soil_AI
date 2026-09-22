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

    test('handles extreme numerical inputs and avoids NaN / Infinity', () {
      // Test extreme temperature that would previously cause tanh/gelu overflow
      final extremeTemp = SoilReading.mock(
        temp: 80.0,
        moist: 95.0,
        ec: 15000,
        phVal: 12.0,
      );
      final result = DeepLearningCalibrator.calibrate(extremeTemp);
      expect(result.calibratedReading.temperature.isNaN, isFalse);
      expect(result.calibratedReading.moisture.isNaN, isFalse);
      expect(result.calibratedReading.conductivity.isNaN, isFalse);
      expect(result.calibratedReading.ph.isNaN, isFalse);
      expect(result.confidenceScore.isNaN, isFalse);
    });

    test('handles out-of-physical-range sensor anomalies safely', () {
      final outOfRange = SoilReading.mock(
        temp: -50.0, // Far below physical soil probe operating range
        moist: -10.0,
        ec: 50000,
        phVal: 15.0,
      );
      final result = DeepLearningCalibrator.calibrate(outOfRange);
      expect(result.compensationReason, contains('out of physical boundaries'));
      expect(result.confidenceScore, equals(0.50));
    });

    test('tanh and gelu numerical bounds verification', () {
      // Verify tanh bounds directly prevent IEEE-754 overflow
      expect(DeepLearningCalibrator.tanh(500.0), equals(1.0));
      expect(DeepLearningCalibrator.tanh(-500.0), equals(-1.0));
      expect(DeepLearningCalibrator.tanh(0.0), equals(0.0));
    });
  });
}
