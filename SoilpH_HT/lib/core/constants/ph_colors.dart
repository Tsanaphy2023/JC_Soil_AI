import 'package:flutter/material.dart';

/// Scientific Soil pH Color Palette & Classification Standards
/// Aligned 100% with Chapter 2 Table 2.3 Ground Truth Calibration Matrix
/// and Land Development Department (LDD Thailand) Guidelines
class PhColors {
  PhColors._();

  // Cyber Dark UI Palette
  static const Color background = Color(0xFF0A0F1D);
  static const Color surface = Color(0xFF131B2E);
  static const Color cardBg = Color(0xFF1B253D);
  static const Color cardBorder = Color(0xFF2B3A5A);
  
  static const Color neonGreen = Color(0xFF00E676);
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color neonAmber = Color(0xFFFFB300);
  static const Color neonOrange = Color(0xFFFF7043);
  static const Color neonRed = Color(0xFFFF5252);
  static const Color neonPurple = Color(0xFFB388FF);

  // Soil pH Scale Colors - Table 2.3 Calibration Standard (7 Tiers)
  static const Color ultraAcidic = Color(0xFFE63946);        // < 4.5 กรดจัดรุนแรง (#e63946)
  static const Color veryStrongAcidic = Color(0xFFF4A261);   // 4.5 - 5.2 กรดจัด (#f4a261)
  static const Color strongAcidic = Color(0xFFF4A261);       // Alias for backward compatibility
  static const Color moderateAcidic = Color(0xFFE9C46A);     // 5.3 - 6.0 กรดปานกลาง (#e9c46a)
  static const Color slightlyAcidic = Color(0xFFA7C957);     // 6.1 - 6.8 กรดเล็กน้อย (#a7c957)
  static const Color optimumNeutral = Color(0xFF2A9D8F);     // 6.9 - 7.5 เป็นกลาง (เหมาะสม) (#2a9d8f)
  static const Color slightlyAlkaline = Color(0xFF457B9D);   // 7.6 - 8.4 ด่างปานกลาง (#457b9d)
  static const Color moderateAlkaline = Color(0xFF457B9D);   // Alias for backward compatibility
  static const Color strongAlkaline = Color(0xFF1D3557);     // > 8.4 ด่างรุนแรง (#1d3557)
  static const Color veryStrongAlkaline = Color(0xFF1D3557); // > 8.4 ด่างรุนแรง (#1d3557)

  /// Get color according to measured pH matching Table 2.3 7 Tiers
  static Color getColorForPh(double ph) {
    if (ph < 4.5) return ultraAcidic;        // < 4.5 (#e63946)
    if (ph <= 5.2) return veryStrongAcidic;  // 4.5 - 5.2 (#f4a261)
    if (ph <= 6.0) return moderateAcidic;    // 5.3 - 6.0 (#e9c46a)
    if (ph <= 6.8) return slightlyAcidic;    // 6.1 - 6.8 (#a7c957)
    if (ph <= 7.5) return optimumNeutral;    // 6.9 - 7.5 (#2a9d8f)
    if (ph <= 8.4) return slightlyAlkaline;  // 7.6 - 8.4 (#457b9d)
    return veryStrongAlkaline;               // > 8.4 (#1d3557)
  }

  /// Get localized descriptive label for pH matching Table 2.3
  static String getLabelForPh(double ph, {bool isThai = true}) {
    if (ph < 4.5) {
      return isThai ? 'กรดจัดรุนแรง (< 4.5)' : 'Ultra Acidic (< 4.5)';
    } else if (ph <= 5.2) {
      return isThai ? 'กรดจัด (4.5 - 5.2)' : 'Strongly Acidic (4.5 - 5.2)';
    } else if (ph <= 6.0) {
      return isThai ? 'กรดปานกลาง (5.3 - 6.0)' : 'Moderately Acidic (5.3 - 6.0)';
    } else if (ph <= 6.8) {
      return isThai ? 'กรดเล็กน้อย (6.1 - 6.8)' : 'Slightly Acidic (6.1 - 6.8)';
    } else if (ph <= 7.5) {
      return isThai ? 'เป็นกลาง (เหมาะสม) (6.9 - 7.5)' : 'Optimum Neutral (6.9 - 7.5)';
    } else if (ph <= 8.4) {
      return isThai ? 'ด่างปานกลาง (7.6 - 8.4)' : 'Moderately Alkaline (7.6 - 8.4)';
    } else {
      return isThai ? 'ด่างรุนแรง (> 8.4)' : 'Strongly Alkaline (> 8.4)';
    }
  }

  /// Evaluates agronomic health score (0 - 100) based on pH distance from optimum 6.5 - 7.0
  static double getPhHealthScore(double ph) {
    final diff = (ph - 6.8).abs();
    if (diff <= 0.4) return 100.0;
    final score = 100.0 - (diff * 26.0);
    return score.clamp(10.0, 100.0);
  }
}
