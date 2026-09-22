import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soil_app/domain/models/soil_color_scale.dart';

void main() {
  group('SoilColorScale Colorimetry Tests (Table 2.3 Standards)', () {
    test('pH scale categorizes ultra acidic, optimal, and strongly alkaline correctly', () {
      final acidic = SoilColorScale.evaluatePh(3.8);
      expect(acidic.level, SoilColorLevel.veryLow);
      expect(acidic.color, const Color(0xFFE63946)); // #e63946

      final optimal = SoilColorScale.evaluatePh(7.2);
      expect(optimal.level, SoilColorLevel.medium);
      expect(optimal.color, const Color(0xFF2A9D8F)); // #2a9d8f

      final alkaline = SoilColorScale.evaluatePh(8.8);
      expect(alkaline.level, SoilColorLevel.veryHigh);
      expect(alkaline.color, const Color(0xFF1D3557)); // #1d3557
    });

    test('Nitrogen Griess scale categorizes levels accurately', () {
      final lowN = SoilColorScale.evaluateNitrogen(8);
      expect(lowN.level, SoilColorLevel.veryLow);
      expect(lowN.color, const Color(0xFFFEFAE0)); // #fefae0

      final medN = SoilColorScale.evaluateNitrogen(45);
      expect(medN.level, SoilColorLevel.medium);
      expect(medN.color, const Color(0xFFE76F51)); // #e76f51

      final highN = SoilColorScale.evaluateNitrogen(100);
      expect(highN.level, SoilColorLevel.veryHigh);
      expect(highN.color, const Color(0xFF7209B7)); // #7209b7
    });

    test('Phosphorus Molybdenum blue scale categorizes levels accurately', () {
      final lowP = SoilColorScale.evaluatePhosphorus(4);
      expect(lowP.level, SoilColorLevel.veryLow);
      expect(lowP.color, const Color(0xFFFAF0CA)); // #faf0ca

      final medP = SoilColorScale.evaluatePhosphorus(25);
      expect(medP.level, SoilColorLevel.medium);
      expect(medP.color, const Color(0xFF3A86FF)); // #3a86ff

      final highP = SoilColorScale.evaluatePhosphorus(70);
      expect(highP.level, SoilColorLevel.veryHigh);
      expect(highP.color, const Color(0xFF03045E)); // #03045e
    });

    test('Potassium Cobaltinitrite scale categorizes levels accurately', () {
      final lowK = SoilColorScale.evaluatePotassium(30);
      expect(lowK.level, SoilColorLevel.veryLow);
      expect(lowK.color, const Color(0xFFEDF2F4)); // #edf2f4

      final medK = SoilColorScale.evaluatePotassium(100);
      expect(medK.level, SoilColorLevel.medium);
      expect(medK.color, const Color(0xFFF3722C)); // #f3722c

      final highK = SoilColorScale.evaluatePotassium(280);
      expect(highK.level, SoilColorLevel.veryHigh);
      expect(highK.color, const Color(0xFF6A040F)); // #6a040f
    });
  });
}
