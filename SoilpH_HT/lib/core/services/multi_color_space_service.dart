import 'dart:math';
import 'package:flutter/material.dart';

/// ข้อมูลปริภูมิสีหลากมิติ (Multi-Color Space Metric)
class MultiColorMetric {
  final int r;
  final int g;
  final int b;
  final double hue;         // 0.0 - 360.0 องศา
  final double saturation;  // 0.0 - 1.0
  final double value;       // 0.0 - 1.0
  final double labL;        // 0.0 - 100.0 (ความสว่าง)
  final double labA;        // -128.0 - +127.0 (เขียว - แดง)
  final double labB;        // -128.0 - +127.0 (น้ำเงิน - เหลือง)
  final double yCbCrY;      // 0.0 - 255.0
  final double yCbCrCb;     // 0.0 - 255.0
  final double yCbCrCr;     // 0.0 - 255.0

  const MultiColorMetric({
    required this.r,
    required this.g,
    required this.b,
    required this.hue,
    required this.saturation,
    required this.value,
    required this.labL,
    required this.labA,
    required this.labB,
    required this.yCbCrY,
    required this.yCbCrCb,
    required this.yCbCrCr,
  });

  Color get toColor => Color.fromRGBO(r, g, b, 1.0);
  String get hexString => '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
  String get rgbDisplay => 'R $r, G $g, B $b';
  String get hsvDisplay => 'H ${hue.toStringAsFixed(0)}°, S ${(saturation * 100).toStringAsFixed(0)}%, V ${(value * 100).toStringAsFixed(0)}%';
  String get labDisplay => 'L* ${labL.toStringAsFixed(1)}, a* ${labA >= 0 ? "+" : ""}${labA.toStringAsFixed(1)}, b* ${labB >= 0 ? "+" : ""}${labB.toStringAsFixed(1)}';
  String get ycbcrDisplay => 'Y ${yCbCrY.toStringAsFixed(0)}, Cb ${yCbCrCb.toStringAsFixed(0)}, Cr ${yCbCrCr.toStringAsFixed(0)}';

  /// คำนวณระยะห่างความต่างสี CIE Delta E (Euclidean distance ใน CIE L*a*b*)
  double deltaE(MultiColorMetric other) {
    return sqrt(
      pow(labL - other.labL, 2) +
      pow(labA - other.labA, 2) +
      pow(labB - other.labB, 2),
    );
  }
}

/// บริการแปลงปริภูมิสีหลากมิติ (Multi-Color Space Engine)
class MultiColorSpaceService {
  MultiColorSpaceService._();

  /// แปลงค่าพิกเซลดิบ (R, G, B) เป็น MultiColorMetric
  static MultiColorMetric fromRgb(int r, int g, int b) {
    r = r.clamp(0, 255);
    g = g.clamp(0, 255);
    b = b.clamp(0, 255);

    // 1. คำนวณ HSV
    final double rNorm = r / 255.0;
    final double gNorm = g / 255.0;
    final double bNorm = b / 255.0;

    final double cMax = max(rNorm, max(gNorm, bNorm));
    final double cMin = min(rNorm, min(gNorm, bNorm));
    final double delta = cMax - cMin;

    double h = 0.0;
    if (delta > 0.00001) {
      if (cMax == rNorm) {
        h = 60.0 * (((gNorm - bNorm) / delta) % 6.0);
      } else if (cMax == gNorm) {
        h = 60.0 * (((bNorm - rNorm) / delta) + 2.0);
      } else {
        h = 60.0 * (((rNorm - gNorm) / delta) + 4.0);
      }
      if (h < 0) h += 360.0;
    }

    final double s = cMax == 0 ? 0.0 : delta / cMax;
    final double v = cMax;

    // 2. คำนวณ CIE L*a*b* อ้างอิงแหล่งกำเนิดแสงมาตรฐาน D65
    double pivotRgb(double n) {
      return (n > 0.04045) ? pow((n + 0.055) / 1.055, 2.4).toDouble() : n / 12.92;
    }

    final double rLin = pivotRgb(rNorm) * 100.0;
    final double gLin = pivotRgb(gNorm) * 100.0;
    final double bLin = pivotRgb(bNorm) * 100.0;

    // แปลงเข้าสู่ระบบ CIE XYZ (D65)
    final double x = rLin * 0.4124564 + gLin * 0.3575761 + bLin * 0.1804375;
    final double y = rLin * 0.2126729 + gLin * 0.7151522 + bLin * 0.0721750;
    final double z = rLin * 0.0193339 + gLin * 0.1191920 + bLin * 0.9503041;

    // ปรับเทียบด้วยจุดขาวมาตรฐาน D65 (White Point)
    const double refX = 95.047;
    const double refY = 100.000;
    const double refZ = 108.883;

    double pivotXyz(double n) {
      return (n > 0.008856) ? pow(n, 1.0 / 3.0).toDouble() : (7.787 * n) + (16.0 / 116.0);
    }

    final double xP = pivotXyz(x / refX);
    final double yP = pivotXyz(y / refY);
    final double zP = pivotXyz(z / refZ);

    final double labL = (116.0 * yP) - 16.0;
    final double labA = 500.0 * (xP - yP);
    final double labB = 200.0 * (yP - zP);

    // 3. คำนวณ YCbCr (มาตรฐานโทรทัศน์ดิจิทัล ITU-R BT.601)
    final double yCbCrY = 0.299 * r + 0.587 * g + 0.114 * b;
    final double yCbCrCb = 128.0 - 0.168736 * r - 0.331264 * g + 0.5 * b;
    final double yCbCrCr = 128.0 + 0.5 * r - 0.418688 * g - 0.081312 * b;

    return MultiColorMetric(
      r: r,
      g: g,
      b: b,
      hue: h,
      saturation: s,
      value: v,
      labL: labL,
      labA: labA,
      labB: labB,
      yCbCrY: yCbCrY,
      yCbCrCb: yCbCrCb,
      yCbCrCr: yCbCrCr,
    );
  }
}
