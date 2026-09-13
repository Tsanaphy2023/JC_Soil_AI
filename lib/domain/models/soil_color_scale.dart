import 'package:flutter/material.dart';

/// Nutrient & pH level classification based on Land Development Department (LDD Thailand)
/// and International Colorimetric Soil Field Test Kit Standards (FAO / LaMotte).
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

  const SoilColorMetric({
    required this.level,
    required this.labelThai,
    required this.color,
    required this.advice,
    required this.normalized,
  });
}

class SoilColorScale {
  SoilColorScale._();

  // -------------------------------------------------------------
  // 1. Soil pH Color Scale (Universal Indicator / LDD Standard)
  // -------------------------------------------------------------
  static SoilColorMetric evaluatePh(double ph) {
    if (ph < 4.5) {
      return const SoilColorMetric(
        level: SoilColorLevel.veryLow,
        labelThai: 'กรดจัดมาก (< 4.5)',
        color: Color(0xFFD32F2F), // Crimson Red
        advice: 'ดินเป็นกรดรุนแรง ธาตุ Al/Mn เป็นพิษ ควรใส่ปูนโดโลไมต์ปรับสภาพดินทันที',
        normalized: 0.15,
      );
    } else if (ph < 5.5) {
      return const SoilColorMetric(
        level: SoilColorLevel.low,
        labelThai: 'กรดจัด (4.5 - 5.5)',
        color: Color(0xFFFB8C00), // Amber Orange
        advice: 'ดินกรด ฟอสฟอรัสถูกตรึงสูง ควรใส่ปูนมาร์ลหรือปูนขาวปรับค่า pH',
        normalized: 0.35,
      );
    } else if (ph <= 6.5) {
      return const SoilColorMetric(
        level: SoilColorLevel.medium,
        labelThai: 'กรดอ่อนๆ (5.5 - 6.5)',
        color: Color(0xFFC0CA33), // Yellow-Green
        advice: 'สภาพกรดอ่อน พืชเขตร้อนส่วนใหญ่ดูดซึมธาตุอาหารได้ดีเยี่ยม',
        normalized: 0.55,
      );
    } else if (ph <= 7.5) {
      return const SoilColorMetric(
        level: SoilColorLevel.medium,
        labelThai: 'เป็นกลาง (6.5 - 7.5)',
        color: Color(0xFF43A047), // Grass Emerald Green
        advice: 'เป็นกลาง เหมาะสมที่สุดต่อการดูดซึมธาตุอาหารหลัก N-P-K',
        normalized: 0.70,
      );
    } else if (ph <= 8.5) {
      return const SoilColorMetric(
        level: SoilColorLevel.high,
        labelThai: 'ด่างปานกลาง (7.5 - 8.5)',
        color: Color(0xFF0288D1), // Cerulean Blue
        advice: 'ดินด่าง ธาตุเหล็กและสังกะสีละลายได้ลดลง ควรเติมอินทรียวัตถุ',
        normalized: 0.85,
      );
    } else {
      return const SoilColorMetric(
        level: SoilColorLevel.veryHigh,
        labelThai: 'ด่างจัด (> 8.5)',
        color: Color(0xFF5E35B1), // Deep Violet
        advice: 'ดินด่างรุนแรงหรือมีเกลือโซเดียมสะสม ควรปรับปรุงด้วยยิปซัม',
        normalized: 1.0,
      );
    }
  }

  // -------------------------------------------------------------
  // 2. Nitrogen (NO3-N) Griess Reaction (Pink to Deep Magenta)
  // -------------------------------------------------------------
  static SoilColorMetric evaluateNitrogen(int nitrogenMgKg) {
    if (nitrogenMgKg < 15) {
      return const SoilColorMetric(
        level: SoilColorLevel.veryLow,
        labelThai: 'ต่ำมาก (< 15 mg/kg)',
        color: Color(0xFFFFCDD2), // Very Light Pink
        advice: 'ขาดไนโตรเจนรุนแรง พืชชะงักการเจริญเติบโต ควรใส่ปุ๋ยไนโตรเจน',
        normalized: 0.15,
      );
    } else if (nitrogenMgKg < 30) {
      return const SoilColorMetric(
        level: SoilColorLevel.low,
        labelThai: 'ต่ำ (15 - 30 mg/kg)',
        color: Color(0xFFF06292), // Light Rose
        advice: 'ระดับไนโตรเจนค่อนข้างต่ำ ควรเสริมปุ๋ยอินทรีย์หรือยูเรียบำรุงต้น',
        normalized: 0.35,
      );
    } else if (nitrogenMgKg <= 60) {
      return const SoilColorMetric(
        level: SoilColorLevel.medium,
        labelThai: 'ปานกลาง (30 - 60 mg/kg)',
        color: Color(0xFFE91E63), // Rose Pink
        advice: 'ระดับไนโตรเจนสมดุลพอดีสำหรับการเจริญเติบโตปกติ',
        normalized: 0.60,
      );
    } else if (nitrogenMgKg <= 90) {
      return const SoilColorMetric(
        level: SoilColorLevel.high,
        labelThai: 'สูง (60 - 90 mg/kg)',
        color: Color(0xFFC2185B), // Crimson Pink
        advice: 'ไนโตรเจนสูงเพียงพอ ไม่จำเป็นต้องใส่ปุ๋ยเร่งใบเพิ่ม',
        normalized: 0.85,
      );
    } else {
      return const SoilColorMetric(
        level: SoilColorLevel.veryHigh,
        labelThai: 'สูงมาก (> 90 mg/kg)',
        color: Color(0xFF880E4F), // Deep Magenta
        advice: 'ไนโตรเจนเกิน พืชอาจบ้าใบและเสี่ยงต่อโรคแมลง ควรงดปุ๋ย N',
        normalized: 1.0,
      );
    }
  }

  // -------------------------------------------------------------
  // 3. Available Phosphorus (Bray II / Molybdenum Blue Scale)
  // -------------------------------------------------------------
  static SoilColorMetric evaluatePhosphorus(int phosphorusMgKg) {
    if (phosphorusMgKg < 8) {
      return const SoilColorMetric(
        level: SoilColorLevel.veryLow,
        labelThai: 'ต่ำมาก (< 8 mg/kg)',
        color: Color(0xFFB3E5FC), // Pale Sky Blue
        advice: 'ขาดฟอสฟอรัส รากพืชแคระแกร็น ไม่ออกดอก ควรเสริมฟอสเฟต',
        normalized: 0.15,
      );
    } else if (phosphorusMgKg < 18) {
      return const SoilColorMetric(
        level: SoilColorLevel.low,
        labelThai: 'ต่ำ (8 - 18 mg/kg)',
        color: Color(0xFF4FC3F7), // Light Cyan Blue
        advice: 'ฟอสฟอรัสต่ำ ควรใส่ปุ๋ย 16-20-0 หรือหินฟอสเฟตรองก้นหลุม',
        normalized: 0.35,
      );
    } else if (phosphorusMgKg <= 35) {
      return const SoilColorMetric(
        level: SoilColorLevel.medium,
        labelThai: 'ปานกลาง (18 - 35 mg/kg)',
        color: Color(0xFF0288D1), // Cyan Cerulean Blue
        advice: 'ระดับฟอสฟอรัสเหมาะสมต่อการพัฒนาระบบรากและตาดอก',
        normalized: 0.60,
      );
    } else if (phosphorusMgKg <= 50) {
      return const SoilColorMetric(
        level: SoilColorLevel.high,
        labelThai: 'สูง (35 - 50 mg/kg)',
        color: Color(0xFF1565C0), // Cobalt Blue
        advice: 'ฟอสฟอรัสสะสมสมบูรณ์ ชะลอการให้ปุ๋ยฟอสเฟต',
        normalized: 0.85,
      );
    } else {
      return const SoilColorMetric(
        level: SoilColorLevel.veryHigh,
        labelThai: 'สูงมาก (> 50 mg/kg)',
        color: Color(0xFF0D47A1), // Deep Navy Midnight
        advice: 'ฟอสฟอรัสสูงเกินไป อาจขัดขวางการดูดซึมธาตุสังกะสีและเหล็ก',
        normalized: 1.0,
      );
    }
  }

  // -------------------------------------------------------------
  // 4. Available Potassium (Cobaltinitrite / Amber-Orange Scale)
  // -------------------------------------------------------------
  static SoilColorMetric evaluatePotassium(int potassiumMgKg) {
    if (potassiumMgKg < 40) {
      return const SoilColorMetric(
        level: SoilColorLevel.veryLow,
        labelThai: 'ต่ำมาก (< 40 mg/kg)',
        color: Color(0xFFFFF9C4), // Pale Amber
        advice: 'ขาดโพแทสเซียม ขอบใบไหม้ ลำต้นล้มง่าย ผลผลิตรสชาติจืด',
        normalized: 0.15,
      );
    } else if (potassiumMgKg < 70) {
      return const SoilColorMetric(
        level: SoilColorLevel.low,
        labelThai: 'ต่ำ (40 - 70 mg/kg)',
        color: Color(0xFFFFD54F), // Amber Gold
        advice: 'โพแทสเซียมต่ำ ควรบำรุงด้วยปุ๋ย 0-0-60 หรือขี้เถ้าถ่าน',
        normalized: 0.35,
      );
    } else if (potassiumMgKg <= 110) {
      return const SoilColorMetric(
        level: SoilColorLevel.medium,
        labelThai: 'ปานกลาง (70 - 110 mg/kg)',
        color: Color(0xFFFFB300), // Rich Amber
        advice: 'ระดับโพแทสเซียมเหมาะสม สำหรับการสร้างแป้งและน้ำตาล',
        normalized: 0.60,
      );
    } else if (potassiumMgKg <= 160) {
      return const SoilColorMetric(
        level: SoilColorLevel.high,
        labelThai: 'สูง (110 - 160 mg/kg)',
        color: Color(0xFFFB8C00), // Deep Orange Amber
        advice: 'โพแทสเซียมสะสมสูง ช่วยให้พืชทนแล้งและผลผลิตเนื้อแน่น',
        normalized: 0.85,
      );
    } else {
      return const SoilColorMetric(
        level: SoilColorLevel.veryHigh,
        labelThai: 'สูงมาก (> 160 mg/kg)',
        color: Color(0xFFE65100), // Burnt Orange
        advice: 'โพแทสเซียมสูงเกิน อาจรบกวนการดูดซึมแคลเซียมและแมกนีเซียม',
        normalized: 1.0,
      );
    }
  }
}
