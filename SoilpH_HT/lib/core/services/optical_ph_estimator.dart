import 'dart:math';
import 'package:flutter/material.dart';
import 'multi_color_space_service.dart';

/// แบบจำลองผลการประเมินค่า pH จากภาพถ่ายร่วมกับเซนเซอร์
class PhComparisonResult {
  final double visionPh;
  final double sensorPh;
  final double deltaPh;
  final MultiColorMetric colorMetric;
  final String agreementStatus;
  final Color statusColor;

  const PhComparisonResult({
    required this.visionPh,
    required this.sensorPh,
    required this.deltaPh,
    required this.colorMetric,
    required this.agreementStatus,
    required this.statusColor,
  });
}

/// ระบบประเมินค่าความเป็นกรดด่างดินจากภาพถ่ายเชิงแสง (Optical Soil pH Estimator)
/// ถอดรหัสแถบสีมาตรฐานตามตารางที่ 2.3 (7 ระดับ) ในงานวิจัยฟิสิกส์เกษตร
class OpticalPhEstimator {
  OpticalPhEstimator._();

  // จุดอ้างอิงมาตรฐาน 7 ระดับตามตารางที่ 2.3
  static final List<({double ph, MultiColorMetric metric, String tierLabel})> referenceStandards = [
    (
      ph: 4.0,
      metric: MultiColorSpaceService.fromRgb(230, 57, 70), // #E63946
      tierLabel: 'กรดจัดรุนแรง (< 4.5)',
    ),
    (
      ph: 4.85,
      metric: MultiColorSpaceService.fromRgb(244, 162, 97), // #F4A261
      tierLabel: 'กรดจัด (4.5 - 5.2)',
    ),
    (
      ph: 5.65,
      metric: MultiColorSpaceService.fromRgb(233, 196, 106), // #E9C46A
      tierLabel: 'กรดปานกลาง (5.3 - 6.0)',
    ),
    (
      ph: 6.45,
      metric: MultiColorSpaceService.fromRgb(167, 201, 87), // #A7C957
      tierLabel: 'กรดเล็กน้อย (6.1 - 6.8)',
    ),
    (
      ph: 7.20,
      metric: MultiColorSpaceService.fromRgb(42, 157, 143), // #2A9D8F
      tierLabel: 'เป็นกลาง (6.9 - 7.5)',
    ),
    (
      ph: 8.00,
      metric: MultiColorSpaceService.fromRgb(69, 123, 157), // #457B9D
      tierLabel: 'ด่างปานกลาง (7.6 - 8.4)',
    ),
    (
      ph: 9.00,
      metric: MultiColorSpaceService.fromRgb(29, 53, 87), // #1D3557
      tierLabel: 'ด่างรุนแรง (> 8.4)',
    ),
  ];

  /// คำนวณประมาณการค่า pH จากข้อมูลปริภูมิสีด้วยเทคนิค Inverse Distance Weighting (IDW) ใน CIE Delta E
  static double estimatePh(MultiColorMetric current) {
    double sumWeight = 0.0;
    double weightedPh = 0.0;

    for (final ref in referenceStandards) {
      final double dE = current.deltaE(ref.metric);
      if (dE < 0.1) return ref.ph;
      final double weight = 1.0 / pow(dE + 0.001, 2.0);
      weightedPh += ref.ph * weight;
      sumWeight += weight;
    }

    if (sumWeight == 0) return 7.0;
    return (weightedPh / sumWeight).clamp(3.5, 10.5);
  }

  /// วิเคราะห์เปรียบเทียบผลระหว่าง Optical pH (กล้อง) และ Sensor pH (โพรบ)
  static PhComparisonResult compare({
    required MultiColorMetric currentMetric,
    required double sensorPh,
  }) {
    final double vPh = estimatePh(currentMetric);
    final double diff = (vPh - sensorPh).abs();

    String status;
    Color color;

    if (diff <= 0.3) {
      status = 'สอดคล้องระดับดีเยี่ยม (Δ ≤ 0.3 pH)';
      color = const Color(0xFF00E676); // Neon Green
    } else if (diff <= 0.7) {
      status = 'สอดคล้องในเกณฑ์ยอมรับ (Δ ≤ 0.7 pH)';
      color = const Color(0xFFFFB300); // Neon Amber
    } else {
      status = 'มีความคลาดเคลื่อนสูง (Δ > 0.7 pH)';
      color = const Color(0xFFFF5252); // Neon Red
    }

    return PhComparisonResult(
      visionPh: vPh,
      sensorPh: sensorPh,
      deltaPh: diff,
      colorMetric: currentMetric,
      agreementStatus: status,
      statusColor: color,
    );
  }
}
