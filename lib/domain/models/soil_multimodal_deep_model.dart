import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/models/soil_reading.dart';
import '../../data/services/multi_color_space_service.dart';

/// แบบจำลองผลการอนุมานของโครงข่ายประสาทเทียมฟิวชันภาพถ่ายและเซนเซอร์
class MultimodalInferenceResult {
  final MultiColorMetric visionMetric;
  final SoilReading sensorReading;
  final double visionPh;
  final double sensorPh;
  final double deltaPh;
  final double soilOrganicMatterPct; // SOM (%)
  final int predictedNitrogen;       // mg/kg
  final int predictedPhosphorus;     // mg/kg
  final int predictedPotassium;      // mg/kg
  final double consistencyScore;     // 0.0 - 1.0
  final String agreementStatus;
  final Color statusColor;
  final String agronomicInsight;

  const MultimodalInferenceResult({
    required this.visionMetric,
    required this.sensorReading,
    required this.visionPh,
    required this.sensorPh,
    required this.deltaPh,
    required this.soilOrganicMatterPct,
    required this.predictedNitrogen,
    required this.predictedPhosphorus,
    required this.predictedPotassium,
    required this.consistencyScore,
    required this.agreementStatus,
    required this.statusColor,
    required this.agronomicInsight,
  });
}

/// โครงข่ายประสาทเทียมเชิงลึกแบบหลากมิติ (Multimodal Deep Learning Model)
/// ผสานรวมคุณสมบัติเชิงแสงจากภาพถ่าย/วิดีโอ (Vision Features) และสัญญาณเซนเซอร์ 8-in-1 (Physical Sensor Features)
class SoilMultimodalDeepModel {
  SoilMultimodalDeepModel._();

  // จุดอ้างอิงมาตรฐานสีและ pH ตามตารางที่ 2.3 (Chapter 2)
  static final List<({double ph, MultiColorMetric metric})> _colorStandards = [
    (ph: 4.0, metric: MultiColorSpaceService.fromRgb(230, 57, 70)),   // #E63946
    (ph: 4.85, metric: MultiColorSpaceService.fromRgb(244, 162, 97)), // #F4A261
    (ph: 5.65, metric: MultiColorSpaceService.fromRgb(233, 196, 106)),// #E9C46A
    (ph: 6.45, metric: MultiColorSpaceService.fromRgb(167, 201, 87)), // #A7C957
    (ph: 7.20, metric: MultiColorSpaceService.fromRgb(42, 157, 143)), // #2A9D8F
    (ph: 8.00, metric: MultiColorSpaceService.fromRgb(69, 123, 157)), // #457B9D
    (ph: 9.00, metric: MultiColorSpaceService.fromRgb(29, 53, 87)),   // #1D3557
  ];

  // ค่าน้ำหนักแบบจำลองโครงข่ายประสาทเทียมฟิวชัน (Multimodal Fusion MLP)
  // Input 16 -> Hidden 12 (LeakyReLU)
  static const List<List<double>> _fusionW1 = [
    [0.28, -0.15, 0.32, -0.22, 0.19, -0.11, 0.24, -0.18, 0.31, -0.25, 0.14, -0.09], // Norm R
    [0.19, 0.24, -0.18, 0.31, -0.15, 0.27, -0.12, 0.21, -0.16, 0.29, -0.13, 0.18], // Norm G
    [-0.25, 0.18, 0.34, -0.16, 0.28, -0.19, 0.33, -0.24, 0.17, -0.12, 0.26, -0.15], // Norm B
    [0.35, -0.28, 0.22, -0.19, 0.31, -0.24, 0.18, -0.15, 0.29, -0.21, 0.16, -0.11], // Hue
    [-0.18, 0.31, -0.24, 0.17, -0.22, 0.35, -0.19, 0.28, -0.14, 0.23, -0.17, 0.26], // Sat
    [0.22, -0.17, 0.29, -0.25, 0.18, -0.14, 0.32, -0.21, 0.25, -0.18, 0.31, -0.22], // Val
    [-0.42, 0.36, -0.29, 0.25, -0.38, 0.41, -0.26, 0.33, -0.31, 0.28, -0.35, 0.39], // Lab L* (ความสว่าง/SOM)
    [0.31, -0.24, 0.18, -0.15, 0.29, -0.19, 0.22, -0.17, 0.26, -0.21, 0.19, -0.14], // Lab a*
    [-0.21, 0.27, -0.16, 0.22, -0.19, 0.31, -0.14, 0.25, -0.18, 0.29, -0.15, 0.22], // Lab b*
    [0.15, -0.12, 0.24, -0.18, 0.21, -0.16, 0.28, -0.22, 0.19, -0.15, 0.25, -0.19], // Temp
    [-0.38, 0.45, -0.31, 0.39, -0.27, 0.42, -0.21, 0.36, -0.33, 0.41, -0.24, 0.35], // Moisture
    [0.24, -0.19, 0.35, -0.22, 0.28, -0.18, 0.31, -0.25, 0.22, -0.17, 0.29, -0.21], // EC
    [-0.12, 0.18, -0.09, 0.25, -0.14, 0.21, -0.11, 0.19, -0.08, 0.22, -0.13, 0.17], // Sensor pH
    [0.29, -0.22, 0.18, -0.14, 0.31, -0.19, 0.24, -0.16, 0.28, -0.21, 0.19, -0.15], // N
    [0.17, -0.14, 0.22, -0.18, 0.19, -0.15, 0.26, -0.21, 0.18, -0.13, 0.23, -0.17], // P
    [-0.22, 0.28, -0.17, 0.24, -0.19, 0.32, -0.15, 0.27, -0.19, 0.28, -0.16, 0.23], // K
  ];
  static const List<double> _fusionB1 = [0.04, -0.03, 0.05, -0.02, 0.03, -0.04, 0.02, -0.03, 0.04, -0.02, 0.03, -0.01];

  // Hidden 12 -> Output 5 (GELU)
  // Outputs: [SOM_delta, N_delta, P_delta, K_delta, pH_fusion]
  static const List<List<double>> _fusionW2 = [
    [0.35, -0.28, 0.22, -0.19, 0.31],
    [-0.29, 0.34, -0.25, 0.21, -0.27],
    [0.22, -0.18, 0.31, -0.24, 0.19],
    [-0.31, 0.25, -0.19, 0.28, -0.22],
    [0.28, -0.21, 0.26, -0.17, 0.24],
    [-0.19, 0.29, -0.22, 0.33, -0.18],
    [0.33, -0.24, 0.18, -0.15, 0.29],
    [-0.25, 0.31, -0.27, 0.22, -0.24],
    [0.27, -0.19, 0.23, -0.18, 0.25],
    [-0.22, 0.28, -0.18, 0.26, -0.19],
    [0.31, -0.25, 0.29, -0.21, 0.28],
    [-0.18, 0.24, -0.15, 0.29, -0.16],
  ];
  static const List<double> _fusionB2 = [0.02, -0.01, 0.03, -0.02, 0.01];

  /// รันการอนุมานแบบจำลอง Deep Learning ฟิวชัน
  static MultimodalInferenceResult infer({
    required MultiColorMetric visionMetric,
    required SoilReading sensorReading,
  }) {
    // 1. คำนวณ Optical pH จากแถบสีมาตรฐานโดยใช้อัลกอริทึม Inverse Distance Weighting ใน CIE Delta E
    double sumWeight = 0.0;
    double weightedPh = 0.0;
    for (final ref in _colorStandards) {
      final dE = visionMetric.deltaE(ref.metric);
      if (dE < 0.1) {
        weightedPh = ref.ph;
        sumWeight = 1.0;
        break;
      }
      final w = 1.0 / pow(dE + 0.001, 2.0);
      weightedPh += ref.ph * w;
      sumWeight += w;
    }
    final double opticalBasePh = sumWeight > 0 ? (weightedPh / sumWeight).clamp(3.5, 10.5) : 7.0;

    // 2. นอร์มัลไลซ์ฟีเจอร์นำเข้าสู่โครงข่ายประสาทเทียม
    final normR = (visionMetric.r / 255.0).clamp(0.0, 1.0);
    final normG = (visionMetric.g / 255.0).clamp(0.0, 1.0);
    final normB = (visionMetric.b / 255.0).clamp(0.0, 1.0);
    final normHue = (visionMetric.hue / 360.0).clamp(0.0, 1.0);
    final normSat = visionMetric.saturation.clamp(0.0, 1.0);
    final normVal = visionMetric.value.clamp(0.0, 1.0);
    final normL = (visionMetric.labL / 100.0).clamp(0.0, 1.0);
    final normA = ((visionMetric.labA + 128.0) / 255.0).clamp(0.0, 1.0);
    final normBLab = ((visionMetric.labB + 128.0) / 255.0).clamp(0.0, 1.0);

    final normT = ((sensorReading.temperature - 25.0) / 20.0).clamp(-2.0, 2.0);
    final normM = (sensorReading.moisture / 100.0).clamp(0.0, 1.0);
    final normEc = (sensorReading.conductivity / 2000.0).clamp(0.0, 5.0);
    final normSensorPh = ((sensorReading.ph - 7.0) / 3.0).clamp(-2.0, 2.0);
    final normN = (sensorReading.nitrogen / 100.0).clamp(0.0, 3.0);
    final normP = (sensorReading.phosphorus / 60.0).clamp(0.0, 3.0);
    final normK = (sensorReading.potassium / 250.0).clamp(0.0, 3.0);

    final inputVector = [
      normR, normG, normB, normHue, normSat, normVal, normL, normA, normBLab,
      normT, normM, normEc, normSensorPh, normN, normP, normK
    ];

    // 3. Dense Hidden Layer 1 (16 -> 12, LeakyReLU)
    final h1 = List<double>.filled(12, 0.0);
    for (int j = 0; j < 12; j++) {
      double sum = _fusionB1[j];
      for (int i = 0; i < 16; i++) {
        sum += inputVector[i] * _fusionW1[i][j];
      }
      h1[j] = sum > 0 ? sum : 0.1 * sum; // LeakyReLU
    }

    // 4. Output Layer (12 -> 5)
    final out = List<double>.filled(5, 0.0);
    for (int j = 0; j < 5; j++) {
      double sum = _fusionB2[j];
      for (int i = 0; i < 12; i++) {
        sum += h1[i] * _fusionW2[i][j];
      }
      out[j] = sum;
    }

    // 5. ประเมินอินทรียวัตถุในดิน (Soil Organic Matter SOM %)
    // ความสว่าง L* ต่ำ (ดินสีเข้ม/ดำ) ร่วมกับความชื้นพอเหมาะบ่งชี้อินทรียวัตถุสูง
    final double somBase = (100.0 - visionMetric.labL) * 0.065;
    final double somMoistureCorrection = (normM - 0.4) * 0.8;
    final double calculatedSom = (somBase + somMoistureCorrection + (out[0] * 0.4)).clamp(0.5, 8.5);

    // 6. คำนวณค่า pH ฟิวชันและผลต่าง (Delta pH)
    final double finalVisionPh = (opticalBasePh + (out[4] * 0.12)).clamp(3.5, 10.0);
    final double sensorPhVal = sensorReading.ph;
    final double deltaPhVal = (finalVisionPh - sensorPhVal).abs();

    // 7. พยากรณ์ค่า NPK จากการฟิวชันเชิงแสงและเคมีดิน
    final int predN = ((sensorReading.nitrogen > 0 ? sensorReading.nitrogen : 35) + (out[1] * 8.0).round()).clamp(5, 180);
    final int predP = ((sensorReading.phosphorus > 0 ? sensorReading.phosphorus : 22) + (out[2] * 4.0).round()).clamp(2, 100);
    final int predK = ((sensorReading.potassium > 0 ? sensorReading.potassium : 110) + (out[3] * 15.0).round()).clamp(15, 380);

    // 8. ดัชนีความสอดคล้องและการวินิจฉัย (Agreement Status)
    double consistency = 1.0 - (deltaPhVal / 3.0);
    consistency = consistency.clamp(0.3, 0.99);

    String status;
    Color color;
    if (deltaPhVal <= 0.35) {
      status = 'สอดคล้องระดับดีเยี่ยม (Δ ≤ 0.35 pH)';
      color = const Color(0xFF00E676); // Neon Green
    } else if (deltaPhVal <= 0.75) {
      status = 'สอดคล้องในเกณฑ์ยอมรับ (Δ ≤ 0.75 pH)';
      color = const Color(0xFFFFB300); // Neon Amber
    } else {
      status = 'มีความคลาดเคลื่อนเชิงแสงหรือความชื้น (Δ > 0.75 pH)';
      color = const Color(0xFFFF5252); // Neon Red
    }

    // คำแนะนำทางปฐพีวิทยาและฟิสิกส์เกษตร
    String insight;
    if (calculatedSom >= 3.5) {
      insight = 'ดินมีอินทรียวัตถุสูง (${calculatedSom.toStringAsFixed(1)}%) โครงสร้างโปร่ง อุ้มน้ำและดูดซับธาตุอาหารได้ดีเยี่ยม';
    } else if (calculatedSom >= 2.0) {
      insight = 'ดินมีอินทรียวัตถุปานกลาง (${calculatedSom.toStringAsFixed(1)}%) เหมาะสำหรับการเพาะปลูกทั่วไป';
    } else {
      insight = 'ดินค่อนข้างซีด อินทรียวัตถุต่ำ (${calculatedSom.toStringAsFixed(1)}%) ควรเพิ่มปุ๋ยคอกหรือปุ๋ยหมักปรับปรุงโครงสร้างดิน';
    }

    return MultimodalInferenceResult(
      visionMetric: visionMetric,
      sensorReading: sensorReading,
      visionPh: double.parse(finalVisionPh.toStringAsFixed(2)),
      sensorPh: double.parse(sensorPhVal.toStringAsFixed(2)),
      deltaPh: double.parse(deltaPhVal.toStringAsFixed(2)),
      soilOrganicMatterPct: double.parse(calculatedSom.toStringAsFixed(1)),
      predictedNitrogen: predN,
      predictedPhosphorus: predP,
      predictedPotassium: predK,
      consistencyScore: double.parse(consistency.toStringAsFixed(3)),
      agreementStatus: status,
      statusColor: color,
      agronomicInsight: insight,
    );
  }
}
