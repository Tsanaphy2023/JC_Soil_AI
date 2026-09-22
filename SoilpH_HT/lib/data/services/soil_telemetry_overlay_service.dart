import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/ph_colors.dart';
import '../models/geo_location_data.dart';
import '../models/ph_sensor_reading.dart';

/// Burns real-time HUD telemetry, GPS coordinates, targeting reticle,
/// and AI PINN metrics directly onto captured soil photos.
class SoilTelemetryOverlayService {
  SoilTelemetryOverlayService._();

  static Future<Uint8List> burnTelemetryOverlay({
    required Uint8List imageBytes,
    required CalibratedPhResult result,
    GeoLocationData? location,
  }) async {
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final ui.Image baseImage = frame.image;

    final width = baseImage.width.toDouble();
    final height = baseImage.height.toDouble();
    final scale = (width / 1080.0).clamp(0.6, 3.5);

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, width, height));

    // 1. Draw base photo
    canvas.drawImage(baseImage, ui.Offset.zero, ui.Paint());

    // 2. Draw Top Header Bar (Branding + GPS Coordinates + Timestamp)
    _drawTopHeader(
      canvas: canvas,
      width: width,
      scale: scale,
      location: location,
    );

    // 3. Draw Center Cyber Targeting Reticle
    _drawCenterReticle(
      canvas: canvas,
      width: width,
      height: height,
      scale: scale,
    );

    // 4. Draw Bottom Telemetry HUD
    _drawBottomTelemetryHud(
      canvas: canvas,
      width: width,
      height: height,
      scale: scale,
      result: result,
    );

    final picture = recorder.endRecording();
    final compositedImage = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await compositedImage.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  static void _drawTopHeader({
    required ui.Canvas canvas,
    required double width,
    required double scale,
    required GeoLocationData? location,
  }) {
    final barHeight = 90.0 * scale;
    final bgPaint = ui.Paint()
      ..shader = ui.Gradient.linear(
        const ui.Offset(0, 0),
        ui.Offset(0, barHeight),
        [
          const Color(0xEE0A0F1D),
          const Color(0x990A0F1D),
          const Color(0x000A0F1D),
        ],
        [0.0, 0.7, 1.0],
      );

    canvas.drawRect(ui.Rect.fromLTWH(0, 0, width, barHeight), bgPaint);

    final nowStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());

    // Title
    _drawText(
      canvas: canvas,
      text: '🌱 SoilpH-HT AI Field Diagnostics',
      offset: ui.Offset(24 * scale, 18 * scale),
      fontSize: 22 * scale,
      color: PhColors.neonGreen,
      fontWeight: FontWeight.w900,
    );

    // Timestamp & GPS
    final locText = location != null ? location.summary : 'GPS: Unavailable';
    _drawText(
      canvas: canvas,
      text: '$nowStr  |  $locText',
      offset: ui.Offset(24 * scale, 48 * scale),
      fontSize: 14 * scale,
      color: Colors.white.withOpacity(0.85),
      fontWeight: FontWeight.w500,
    );
  }

  static void _drawCenterReticle({
    required ui.Canvas canvas,
    required double width,
    required double height,
    required double scale,
  }) {
    final cx = width / 2;
    final cy = height / 2;
    final reticleSize = 140.0 * scale;
    final cornerLength = 30.0 * scale;

    final paint = ui.Paint()
      ..color = PhColors.neonCyan.withOpacity(0.7)
      ..strokeWidth = 2.5 * scale
      ..style = ui.PaintingStyle.stroke;

    // Top-Left
    canvas.drawLine(ui.Offset(cx - reticleSize, cy - reticleSize), ui.Offset(cx - reticleSize + cornerLength, cy - reticleSize), paint);
    canvas.drawLine(ui.Offset(cx - reticleSize, cy - reticleSize), ui.Offset(cx - reticleSize, cy - reticleSize + cornerLength), paint);

    // Top-Right
    canvas.drawLine(ui.Offset(cx + reticleSize, cy - reticleSize), ui.Offset(cx + reticleSize - cornerLength, cy - reticleSize), paint);
    canvas.drawLine(ui.Offset(cx + reticleSize, cy - reticleSize), ui.Offset(cx + reticleSize, cy - reticleSize + cornerLength), paint);

    // Bottom-Left
    canvas.drawLine(ui.Offset(cx - reticleSize, cy + reticleSize), ui.Offset(cx - reticleSize + cornerLength, cy + reticleSize), paint);
    canvas.drawLine(ui.Offset(cx - reticleSize, cy + reticleSize), ui.Offset(cx - reticleSize, cy + reticleSize - cornerLength), paint);

    // Bottom-Right
    canvas.drawLine(ui.Offset(cx + reticleSize, cy + reticleSize), ui.Offset(cx + reticleSize - cornerLength, cy + reticleSize), paint);
    canvas.drawLine(ui.Offset(cx + reticleSize, cy + reticleSize), ui.Offset(cx + reticleSize, cy + reticleSize - cornerLength), paint);

    // Center Crosshair Dot
    canvas.drawCircle(ui.Offset(cx, cy), 4 * scale, ui.Paint()..color = PhColors.neonGreen);

    // Label
    _drawText(
      canvas: canvas,
      text: '[ + ] SOIL pH TARGET ZONE',
      offset: ui.Offset(cx - 95 * scale, cy + reticleSize + 10 * scale),
      fontSize: 13 * scale,
      color: PhColors.neonCyan,
      fontWeight: FontWeight.bold,
    );
  }

  static void _drawBottomTelemetryHud({
    required ui.Canvas canvas,
    required double width,
    required double height,
    required double scale,
    required CalibratedPhResult result,
  }) {
    final raw = result.rawReading;
    final hudHeight = 175.0 * scale;
    final top = height - hudHeight;

    final bgPaint = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(0, top),
        ui.Offset(0, height),
        [
          const Color(0x000A0F1D),
          const Color(0xD90A0F1D),
          const Color(0xF20A0F1D),
        ],
        [0.0, 0.25, 1.0],
      );

    canvas.drawRect(ui.Rect.fromLTWH(0, top, width, hudHeight), bgPaint);

    final phColor = PhColors.getColorForPh(result.phCalibrated);
    final phCategory = PhColors.getLabelForPh(result.phCalibrated);

    // Row 1: Large Calibrated pH Display
    _drawText(
      canvas: canvas,
      text: 'pH ${result.phCalibrated.toStringAsFixed(2)}',
      offset: ui.Offset(24 * scale, top + 34 * scale),
      fontSize: 36 * scale,
      color: phColor,
      fontWeight: FontWeight.w900,
    );

    // Delta badge
    final deltaStr = 'Δ ${result.deltaPhTotal > 0 ? '+' : ''}${result.deltaPhTotal.toStringAsFixed(2)} (PINN)';
    _drawText(
      canvas: canvas,
      text: deltaStr,
      offset: ui.Offset(190 * scale, top + 44 * scale),
      fontSize: 15 * scale,
      color: result.deltaPhTotal > 0 ? PhColors.neonGreen : PhColors.neonAmber,
      fontWeight: FontWeight.bold,
    );

    // Category Label
    _drawText(
      canvas: canvas,
      text: phCategory,
      offset: ui.Offset(24 * scale, top + 76 * scale),
      fontSize: 14 * scale,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    );

    // Row 2: Secondary Sensors Line 1 (pH raw, Temp, Moisture)
    final metricsLine1 = 'Raw: ${raw.phRaw.toStringAsFixed(2)} pH  •  T: ${raw.temperature.toStringAsFixed(1)}°C  •  H: ${raw.moisture.toStringAsFixed(1)}%';
    _drawText(
      canvas: canvas,
      text: metricsLine1,
      offset: ui.Offset(24 * scale, top + 98 * scale),
      fontSize: 12.5 * scale,
      color: Colors.white.withOpacity(0.9),
      fontWeight: FontWeight.w600,
    );

    // Row 3: Secondary Sensors Line 2 (EC, AI Confidence)
    final metricsLine2 = 'EC: ${raw.conductivity} µS/cm  •  PINN AI Conf: ${(result.confidenceScore * 100).toStringAsFixed(1)}%';
    _drawText(
      canvas: canvas,
      text: metricsLine2,
      offset: ui.Offset(24 * scale, top + 120 * scale),
      fontSize: 12 * scale,
      color: PhColors.neonCyan.withOpacity(0.9),
      fontWeight: FontWeight.w500,
    );

    // Row 4: Diagnostic Interpretation
    _drawText(
      canvas: canvas,
      text: 'AI Diagnostic: ${result.physicalInterpretation}',
      offset: ui.Offset(24 * scale, top + 142 * scale),
      fontSize: 11 * scale,
      color: Colors.white70,
      fontWeight: FontWeight.normal,
    );
  }

  static void _drawText({
    required ui.Canvas canvas,
    required String text,
    required ui.Offset offset,
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(textAlign: TextAlign.left, fontSize: fontSize),
    )
      ..pushStyle(ui.TextStyle(color: color, fontWeight: fontWeight))
      ..addText(text);

    final paragraph = builder.build()..layout(const ui.ParagraphConstraints(width: 4000));
    canvas.drawParagraph(paragraph, offset);
  }
}
