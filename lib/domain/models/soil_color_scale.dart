import 'package:flutter/material.dart';

/// Nutrient & pH level classification based on Land Development Department (LDD Thailand),
/// FAO Soil Color Standards, and Chapter 2 Table 2.3 Ground Truth calibration.
enum SoilColorLevel {
  veryLow,
  low,
  medium,
  high,
  veryHigh,
}

class SoilColorMetric {
  final SoilColorLevel level;
  final String labelThai;
  final Color color;
  final String advice;
  final double normalized; // 0.0 to 1.0 for progress indicator
  final double hue; // 0.0 to 360.0 degrees
  final double saturation; // 0.0 to 1.0
  final double value; // 0.0 to 1.0
  final double labL; // CIE L* (0 to 100)
  final double labA; // CIE a* (-128 to +127)
  final double labB; // CIE b* (-128 to +127)

  const SoilColorMetric({
    required this.level,
    required this.labelThai,
    required this.color,
    required this.advice,
    required this.normalized,
    this.hue = 0.0,
    this.saturation = 0.0,
    this.value = 0.0,
    this.labL = 0.0,
    this.labA = 0.0,
    this.labB = 0.0,
  });

  String get hsvString => "HSV: ${hue.toStringAsFixed(0)}°, ${(saturation * 100).toStringAsFixed(0)}%, ${(value * 100).toStringAsFixed(0)}%";
  String get labString => "L*=${labL.toStringAsFixed(1)}, a*=${labA >= 0 ? "+" : ""}${labA.toStringAsFixed(1)}, b*=${labB >= 0 ? "+" : ""}${labB.toStringAsFixed(1)}";
}

class SoilColorScale {
  SoilColorScale._();

  // -------------------------------------------------------------
  // 1. Soil pH Color Scale (Table 2.3 - 7 Tiers)
  // -------------------------------------------------------------
  static SoilColorMetric evaluatePh(double ph) {
    if (ph < 4.5) {
      return const SoilColorMetric(
        level: SoilColorLevel.veryLow,
        labelThai: 'กรดจัดรุนแรง (< 4.5)',
        color: Color(0xFFE63946), // Carmine Red (#e63946)
        advice: 'ดินเป็นกรดรุนแรง ธาตุ Al/Mn ละลายตัวเป็นพิษ ควรใส่ปูนโดโลไมต์ปรับสภาพดินทันที',
        normalized: 0.14,
      );
    } else if (ph <= 5.2) {
      return const SoilColorMetric(
        level: SoilColorLevel.low,
        labelThai: 'กรดจัด (4.5 - 5.2)',
        color: Color(0xFFF4A261), // Sandy Orange (#f4a261)
        advice: 'ดินกรดจัด ฟอสฟอรัสถูกตรึงสูง ควรใส่ปูนมาร์ลหรือปูนขาวปรับค่า pH',
        normalized: 0.28,
      );
    } else if (ph <= 6.0) {
      return const SoilColorMetric(
        level: SoilColorLevel.low,
        labelThai: 'กรดปานกลาง (5.3 - 6.0)',
        color: Color(0xFFE9C46A), // Mustard Yellow (#e9c46a)
        advice: 'ดินกรดปานกลาง เหมาะสมต่อพืชทนกรด ควรเติมอินทรียวัตถุเพื่อรักษาโครงสร้างดิน',
        normalized: 0.43,
      );
    } else if (ph <= 6.8) {
      return const SoilColorMetric(
        level: SoilColorLevel.medium,
        labelThai: 'กรดเล็กน้อย (6.1 - 6.8)',
        color: Color(0xFFA7C957), // Yellow Green (#a7c957)
        advice: 'สภาพกรดเล็กน้อย พืชเขตร้อนและทุเรียนดูดซึมธาตุอาหารได้อย่างสมบูรณ์',
        normalized: 0.57,
      );
    } else if (ph <= 7.5) {
      return const SoilColorMetric(
        level: SoilColorLevel.medium,
        labelThai: 'เป็นกลาง (เหมาะสม) (6.9 - 7.5)',
        color: Color(0xFF2A9D8F), // Teal Emerald (#2a9d8f)
        advice: 'เป็นกลาง เหมาะสมที่สุดต่อการดูดซึมธาตุอาหารหลัก N-P-K และจุลินทรีย์ดิน',
        normalized: 0.71,
      );
    } else if (ph <= 8.4) {
      return const SoilColorMetric(
        level: SoilColorLevel.high,
        labelThai: 'ด่างปานกลาง (7.6 - 8.4)',
        color: Color(0xFF457B9D), // Ocean Blue (#457b9d)
        advice: 'ดินด่างปานกลาง ธาตุเหล็ก สังกะสี และทองแดงละลายได้ลดลง ควรเติมอินทรียวัตถุหรือกำมะถันผง',
        normalized: 0.86,
      );
    } else {
      return const SoilColorMetric(
        level: SoilColorLevel.veryHigh,
        labelThai: 'ด่างรุนแรง (> 8.4)',
        color: Color(0xFF1D3557), // Deep Navy (#1d3557)
        advice: 'ดินด่างรุนแรง มักเป็นดินเค็มโซดิก ควรระบายน้ำล้างเกลือและปรับปรุงด้วยยิปซัม',
        normalized: 1.0,
      );
    }
  }

  // -------------------------------------------------------------
  // 2. Nitrogen (NO3-N) Standard Scale (Table 2.3 - 5 Tiers)
  // -------------------------------------------------------------
  static SoilColorMetric evaluateNitrogen(int nitrogenMgKg) {
    if (nitrogenMgKg < 10) {
      return const SoilColorMetric(
        level: SoilColorLevel.veryLow,
        labelThai: 'ต่ำมาก (< 10 mg/kg)',
        color: Color(0xFFFEFAE0), // Cream Tint (#fefae0)
        advice: 'ขาดไนโตรเจนรุนแรง พืชชะงักการเจริญเติบโต ใบเหลือง ควรใส่ปุ๋ยไนโตรเจนหรืออินทรีย์วัตถุ',
        normalized: 0.15,
      );
    } else if (nitrogenMgKg <= 25) {
      return const SoilColorMetric(
        level: SoilColorLevel.low,
        labelThai: 'ต่ำ (10 - 25 mg/kg)',
        color: Color(0xFFF4A261), // Sandy Orange (#f4a261)
        advice: 'ระดับไนโตรเจนค่อนข้างต่ำ ควรเสริมปุ๋ยอินทรีย์หรือยูเรียบำรุงต้นระยะเจริญเติบโต',
        normalized: 0.35,
      );
    } else if (nitrogenMgKg <= 50) {
      return const SoilColorMetric(
        level: SoilColorLevel.medium,
        labelThai: 'ปานกลาง (เหมาะสม) (26 - 50 mg/kg)',
        color: Color(0xFFE76F51), // Coral Orange (#e76f51)
        advice: 'ระดับไนโตรเจนสมดุลเหมาะสมต่อการเจริญเติบโตทางลำต้นและใบ',
        normalized: 0.60,
      );
    } else if (nitrogenMgKg <= 80) {
      return const SoilColorMetric(
        level: SoilColorLevel.high,
        labelThai: 'สูง (51 - 80 mg/kg)',
        color: Color(0xFFD62828), // Crimson Red (#d62828)
        advice: 'ไนโตรเจนสูงเพียงพอ ไม่จำเป็นต้องใส่ปุ๋ยเร่งใบเพิ่มในระยะนี้',
        normalized: 0.85,
      );
    } else {
      return const SoilColorMetric(
        level: SoilColorLevel.veryHigh,
        labelThai: 'สูงมาก (> 80 mg/kg)',
        color: Color(0xFF7209B7), // Deep Violet (#7209b7)
        advice: 'ไนโตรเจนสะสมเกิน พืชเสี่ยงต่อการบ้าใบและโรคแมลง ควรงดปุ๋ยเคมีสูตรไนโตรเจนสูง',
        normalized: 1.0,
      );
    }
  }

  // -------------------------------------------------------------
  // 3. Available Phosphorus Standard Scale (Table 2.3 - 5 Tiers)
  // -------------------------------------------------------------
  static SoilColorMetric evaluatePhosphorus(int phosphorusMgKg) {
    if (phosphorusMgKg < 5) {
      return const SoilColorMetric(
        level: SoilColorLevel.veryLow,
        labelThai: 'ต่ำมาก (< 5 mg/kg)',
        color: Color(0xFFFAF0CA), // Pale Vanilla (#faf0ca)
        advice: 'ขาดฟอสฟอรัสรุนแรง รากพืชแคระแกร็น ไม่ออกดอก ควรเสริมปุ๋ยฟอสเฟตหรือหินฟอสเฟต',
        normalized: 0.15,
      );
    } else if (phosphorusMgKg <= 15) {
      return const SoilColorMetric(
        level: SoilColorLevel.low,
        labelThai: 'ต่ำ (5 - 15 mg/kg)',
        color: Color(0xFFA2D2FF), // Soft Blue (#a2d2ff)
        advice: 'ฟอสฟอรัสต่ำ ควรใส่ปุ๋ย 16-20-0 หรือปุ๋ยหมักรองก้นหลุมเพื่อกระตุ้นราก',
        normalized: 0.35,
      );
    } else if (phosphorusMgKg <= 30) {
      return const SoilColorMetric(
        level: SoilColorLevel.medium,
        labelThai: 'ปานกลาง (เหมาะสม) (16 - 30 mg/kg)',
        color: Color(0xFF3A86FF), // Royal Azure (#3a86ff)
        advice: 'ระดับฟอสฟอรัสเหมาะสมต่อการพัฒนาระบบราก การแตกตาดอก และการติดผล',
        normalized: 0.60,
      );
    } else if (phosphorusMgKg <= 60) {
      return const SoilColorMetric(
        level: SoilColorLevel.high,
        labelThai: 'สูง (31 - 60 mg/kg)',
        color: Color(0xFF003049), // Deep Prussian (#003049)
        advice: 'ฟอสฟอรัสสะสมสมบูรณ์เพียงพอ ชะลอการให้ปุ๋ยกลุ่มฟอสเฟต',
        normalized: 0.85,
      );
    } else {
      return const SoilColorMetric(
        level: SoilColorLevel.veryHigh,
        labelThai: 'สูงมาก (> 60 mg/kg)',
        color: Color(0xFF03045E), // Midnight Navy (#03045e)
        advice: 'ฟอสฟอรัสสูงเกินไป อาจขัดขวางการดูดซึมจุลธาตุสังกะสีและเหล็ก',
        normalized: 1.0,
      );
    }
  }

  // -------------------------------------------------------------
  // 4. Exchangeable Potassium Standard Scale (Table 2.3 - 5 Tiers)
  // -------------------------------------------------------------
  static SoilColorMetric evaluatePotassium(int potassiumMgKg) {
    if (potassiumMgKg < 40) {
      return const SoilColorMetric(
        level: SoilColorLevel.veryLow,
        labelThai: 'ต่ำมาก (< 40 mg/kg)',
        color: Color(0xFFEDF2F4), // Clean Light (#edf2f4)
        advice: 'ขาดโพแทสเซียม ขอบใบไหม้ ลำต้นล้มง่าย ผลผลิตรสชาติจืด ควรใส่ปุ๋ย 0-0-60',
        normalized: 0.15,
      );
    } else if (potassiumMgKg <= 80) {
      return const SoilColorMetric(
        level: SoilColorLevel.low,
        labelThai: 'ต่ำ (40 - 80 mg/kg)',
        color: Color(0xFFFFD166), // Golden Yellow (#ffd166)
        advice: 'โพแทสเซียมต่ำ ควรบำรุงด้วยปุ๋ยโพแทสเซียมหรือขี้เถ้าถ่านก่อนช่วงติดผล',
        normalized: 0.35,
      );
    } else if (potassiumMgKg <= 150) {
      return const SoilColorMetric(
        level: SoilColorLevel.medium,
        labelThai: 'ปานกลาง (เหมาะสม) (81 - 150 mg/kg)',
        color: Color(0xFFF3722C), // Vivid Orange (#f3722c)
        advice: 'ระดับโพแทสเซียมเหมาะสม สำหรับการสร้างเนื้อแป้ง น้ำตาล และคุณภาพผลผลิต',
        normalized: 0.60,
      );
    } else if (potassiumMgKg <= 250) {
      return const SoilColorMetric(
        level: SoilColorLevel.high,
        labelThai: 'สูง (151 - 250 mg/kg)',
        color: Color(0xFFD90429), // Deep Amber Crimson (#d90429)
        advice: 'โพแทสเซียมสะสมสูง ช่วยให้พืชทนแล้งและเนื้อผลแน่น ชะลอการให้ปุ๋ย K เพิ่ม',
        normalized: 0.85,
      );
    } else {
      return const SoilColorMetric(
        level: SoilColorLevel.veryHigh,
        labelThai: 'สูงมาก (> 250 mg/kg)',
        color: Color(0xFF6A040F), // Dark Mahogany Red (#6a040f)
        advice: 'โพแทสเซียมสูงเกิน อาจรบกวนการดูดซึมแคลเซียมและแมกนีเซียม ทำให้ผลแตก',
        normalized: 1.0,
      );
    }
  }
}
