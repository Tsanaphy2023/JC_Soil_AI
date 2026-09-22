import 'package:flutter_test/flutter_test.dart';
import 'package:soil_ph_ht/data/models/ph_sensor_reading.dart';
import 'package:soil_ph_ht/domain/ml/ph_deep_pinn_model.dart';
import 'package:soil_ph_ht/domain/models/agronomic_rules.dart';
import 'package:soil_ph_ht/domain/models/lime_prescription.dart';

void main() {
  group('Physics-Informed Neural Network (PINN) Model Tests', () {
    test('Standard Reference Condition (25°C, 50% VWC) produces near-zero drift', () {
      final raw = SoilPhReading(
        phRaw: 6.50,
        temperature: 25.0,
        moisture: 50.0,
        conductivity: 600,
        timestamp: DateTime.now(),
      );

      final result = PhDeepPinnModel.compensate(raw);

      expect(result.phCalibrated, closeTo(6.50, 0.15));
      expect(result.deltaPhTemperature, closeTo(0.0, 0.05));
      expect(result.deltaPhMoisture, closeTo(0.0, 0.05));
      expect(result.confidenceScore, greaterThan(0.95));
      expect(result.physicalInterpretation, contains('สภาวะแวดล้อมใกล้เคียงมาตรฐาน'));
    });

    test('Hot & Dry Soil (40°C, 12% VWC) compensates both thermal and dry impedance errors', () {
      final raw = SoilPhReading(
        phRaw: 5.40,
        temperature: 40.0,
        moisture: 12.0,
        conductivity: 1200,
        timestamp: DateTime.now(),
      );

      final result = PhDeepPinnModel.compensate(raw);

      // In hot soil (40°C > 25°C), Nernst slope increases, producing temperature delta
      expect(result.deltaPhTemperature.abs(), greaterThan(0.02));
      // In dry soil (12% < 30%), contact impedance correction is negative
      expect(result.deltaPhMoisture, lessThan(0.0));
      expect(result.physicalInterpretation, contains('ชดเชยอุณหภูมิ Nernst'));
      expect(result.physicalInterpretation, contains('ค่าความต้านทานรอยต่อดินแห้ง'));
    });

    test('Numerical Stability: Handles boundary edge cases without NaN or crash', () {
      final extreme1 = SoilPhReading(
        phRaw: 3.0,
        temperature: -15.0,
        moisture: 5.0,
        conductivity: 50,
        timestamp: DateTime.now(),
      );
      final res1 = PhDeepPinnModel.compensate(extreme1);
      expect(res1.phCalibrated.isNaN, false);
      expect(res1.confidenceScore.isInfinite, false);

      final extreme2 = SoilPhReading(
        phRaw: 9.8,
        temperature: 65.0,
        moisture: 95.0,
        conductivity: 15000,
        timestamp: DateTime.now(),
      );
      final res2 = PhDeepPinnModel.compensate(extreme2);
      expect(res2.phCalibrated.isNaN, false);
      expect(res2.phCalibrated, inInclusiveRange(3.0, 10.0));
    });
  });

  group('Agronomic Rules & Lime Prescription Tests', () {
    test('Evaluates 10 essential nutrients with correct bioavailability curves', () {
      final nutrients = AgronomicRules.evaluateNutrients(6.5);
      expect(nutrients.length, 10);

      // At pH 6.5, Phosphorus is near maximum availability
      final p = nutrients.firstWhere((n) => n.symbol == 'P');
      expect(p.availabilityPercent, greaterThan(80.0));

      // At pH 4.0, Phosphorus should be heavily locked by Al/Fe
      final acidNutrients = AgronomicRules.evaluateNutrients(4.0);
      final acidP = acidNutrients.firstWhere((n) => n.symbol == 'P');
      expect(acidP.availabilityPercent, lessThan(40.0));
    });

    test('Calculates heavier dolomite requirement for Clay than Sandy soil', () {
      final sandPrescription = LimePrescription.calculate(
        currentPh: 4.8,
        targetPh: 6.5,
        texture: SoilTexture.sandy,
      );
      final clayPrescription = LimePrescription.calculate(
        currentPh: 4.8,
        targetPh: 6.5,
        texture: SoilTexture.clay,
      );

      expect(sandPrescription.isAdjustmentNeeded, true);
      expect(clayPrescription.isAdjustmentNeeded, true);
      expect(clayPrescription.dolomiteKgPerRai, greaterThan(sandPrescription.dolomiteKgPerRai));
    });
  });
}
