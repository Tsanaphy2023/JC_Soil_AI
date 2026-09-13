import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soil_app/domain/models/soil_color_scale.dart';

void main() {
  group('SoilColorScale Colorimetry Tests', () {
    test('pH scale categorizes ultra acidic, optimal, and strongly alkaline correctly', () {
      final acidic = SoilColorScale.evaluatePh(3.8);
      expect(acidic.level, SoilColorLevel.veryLow);
      expect(acidic.color, const Color(0xFFD32F2F));

      final optimal = SoilColorScale.evaluatePh(6.8);
      expect(optimal.level, SoilColorLevel.medium);
      expect(optimal.color, const Color(0xFF43A047));

      final alkaline = SoilColorScale.evaluatePh(8.8);
      expect(alkaline.level, SoilColorLevel.veryHigh);
      expect(alkaline.color, const Color(0xFF5E35B1));
    });

    test('Nitrogen Griess scale categorizes levels accurately', () {
      final lowN = SoilColorScale.evaluateNitrogen(10);
      expect(lowN.level, SoilColorLevel.veryLow);

      final medN = SoilColorScale.evaluateNitrogen(45);
      expect(medN.level, SoilColorLevel.medium);
      expect(medN.color, const Color(0xFFE91E63));

      final highN = SoilColorScale.evaluateNitrogen(100);
      expect(highN.level, SoilColorLevel.veryHigh);
    });

    test('Phosphorus Molybdenum blue scale categorizes levels accurately', () {
      final lowP = SoilColorScale.evaluatePhosphorus(4);
      expect(lowP.level, SoilColorLevel.veryLow);

      final medP = SoilColorScale.evaluatePhosphorus(25);
      expect(medP.level, SoilColorLevel.medium);
      expect(medP.color, const Color(0xFF0288D1));

      final highP = SoilColorScale.evaluatePhosphorus(60);
      expect(highP.level, SoilColorLevel.veryHigh);
    });

    test('Potassium Cobaltinitrite scale categorizes levels accurately', () {
      final lowK = SoilColorScale.evaluatePotassium(30);
      expect(lowK.level, SoilColorLevel.veryLow);

      final medK = SoilColorScale.evaluatePotassium(90);
      expect(medK.level, SoilColorLevel.medium);
      expect(medK.color, const Color(0xFFFFB300));

      final highK = SoilColorScale.evaluatePotassium(180);
      expect(highK.level, SoilColorLevel.veryHigh);
    });
  });
}
