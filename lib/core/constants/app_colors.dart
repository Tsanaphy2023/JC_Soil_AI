import 'package:flutter/material.dart';

/// Palette matching the Soil Parameter Detector reference interface
class AppColors {
  AppColors._();

  // Header Gradient
  static const Color headerGradientStart = Color(0xFF1565C0);
  static const Color headerGradientEnd = Color(0xFF42A5F5);

  // 8 Parameter Tile Colors (Exact theme from prototype)
  static const Color temperature = Color(0xFF388E3C);     // Green
  static const Color moisture = Color(0xFF1976D2);        // Blue
  static const Color conductivity = Color(0xFF6A1B9A);    // Deep Purple / Violet
  static const Color ph = Color(0xFFE65100);              // Bright Orange
  static const Color nitrogen = Color(0xFFC2185B);        // Deep Pink / Magenta
  static const Color phosphorus = Color(0xFF0288D1);      // Cyan / Light Blue
  static const Color potassium = Color(0xFF00897B);       // Teal / Sea Green
  static const Color fertility = Color(0xFFE64A19);       // Coral / Salmon

  // Background & UI Accents
  static const Color background = Color(0xFF0D1117);
  static const Color cardSurface = Color(0xFF161B22);
  static const Color textWhite = Colors.white;
  static const Color textLight = Color(0xFFE0E0E0);
  static const Color textMuted = Color(0xFF9E9E9E);
  
  // Status Colors
  static const Color connected = Color(0xFF00E676);
  static const Color disconnected = Color(0xFFFF5252);
  static const Color simulating = Color(0xFFFFD600);
}
