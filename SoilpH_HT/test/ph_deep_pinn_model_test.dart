import 'package:flutter_test/flutter_test.dart';
import 'package:soil_ph_ht/data/models/ai_training_sample.dart';
import 'package:soil_ph_ht/data/models/field_validation_record.dart';
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
      expect(result.sensorVoltageMv, closeTo(29.58, 1.0));
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
      expect(result.physicalInterpretation, contains('ชดเชยอุณหภูมิ'));
      expect(result.physicalInterpretation, contains('ความต้านทานรอยต่อดินแห้ง'));
    });

    test('Decouples Temperature Effect and Sensor Non-linearity explicitly (Objective 2)', () {
      final acidReading = SoilPhReading(
        phRaw: 4.20,
        temperature: 33.0,
        moisture: 55.0,
        conductivity: 700,
        timestamp: DateTime.now(),
      );

      final result = PhDeepPinnModel.compensate(acidReading);

      // Temperature Effect should be non-zero (33°C != 25°C)
      expect(result.deltaPhTemperature.abs(), greaterThan(0.01));
      // Non-linearity should capture sub-Nernstian deviation for pH < 4.8
      expect(result.deltaPhNonLinear.abs(), greaterThan(0.01));
      // Calibrated pH is clamped and realistic
      expect(result.phCalibrated, inInclusiveRange(3.5, 5.0));
    });

    test('Nernst Slope & Sensor Potential mV Calculation (Objective 1)', () {
      // At 25°C, Nernst slope = 59.16 mV / pH
      final slope25 = SoilPhReading.nernstSlope(25.0);
      expect(slope25, closeTo(59.16, 0.1));

      // At pH 7.00, potential = 0.0 mV
      final v7 = SoilPhReading.calculateVoltageMv(7.00, 25.0);
      expect(v7, closeTo(0.0, 0.01));

      // At pH 4.00, potential = +177.48 mV
      final v4 = SoilPhReading.calculateVoltageMv(4.00, 25.0);
      expect(v4, closeTo(177.48, 0.5));
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

  group('Field Benchmark Statistics & EURACHEM Verification (Objective 3)', () {
    test('Calculates RMSE, %Bias and R^2 correctly', () {
      final records = [
        FieldValidationRecord(
          id: 'TEST_01',
          province: 'จันทบุรี',
          district: 'ท่าใหม่',
          orchardName: 'สวนทดสอบ 1',
          standardPhMeterReading: 5.50,
          portableAiPhReading: 5.52,
          portableRawPhReading: 5.15,
          portableAtcPhReading: 5.30,
          sensorVoltageMv: 88.7,
          temperatureC: 30.0,
          moisturePct: 55.0,
          ecUsCm: 500,
          timestamp: DateTime.now(),
        ),
        FieldValidationRecord(
          id: 'TEST_02',
          province: 'ตราด',
          district: 'เขาสมิง',
          orchardName: 'สวนทดสอบ 2',
          standardPhMeterReading: 6.00,
          portableAiPhReading: 5.98,
          portableRawPhReading: 5.70,
          portableAtcPhReading: 5.85,
          sensorVoltageMv: 59.1,
          temperatureC: 32.0,
          moisturePct: 60.0,
          ecUsCm: 600,
          timestamp: DateTime.now(),
        ),
      ];

      final stats = BenchmarkStatistics.compute(records);

      expect(stats.sampleCount, 2);
      expect(stats.rmseAi, lessThan(0.05)); // AI RMSE < 0.05 pH
      expect(stats.rmseRaw, greaterThan(0.30)); // Raw error much higher
      expect(stats.meanBiasPercentAi, lessThan(1.0)); // Meets EURACHEM
      expect(stats.passedEurachemCount, 2);
      expect(stats.rSquaredAi, greaterThan(0.95));
    });

    test('NIST Buffer Temperature compensation for calibration samples', () {
      final buf4At25 = AiTrainingSample.calculateNistBufferPh(4.01, 25.0);
      expect(buf4At25, 4.01);

      final buf7At25 = AiTrainingSample.calculateNistBufferPh(7.00, 25.0);
      expect(buf7At25, 7.00);

      final buf10At25 = AiTrainingSample.calculateNistBufferPh(10.01, 25.0);
      expect(buf10At25, 10.01);
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

