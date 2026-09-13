import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/geo_location_data.dart';
import '../models/soil_reading.dart';
import '../../domain/models/deep_learning_calibrator.dart';

/// Service for burning live sensor telemetry, GPS coordinates, targeting reticle,
/// and AI PINN metrics directly onto captured soil photos.
class SoilTelemetryOverlayService {
  SoilTelemetryOverlayService._();

  /// Burns real-time HUD telemetry overlay onto captured image bytes and returns encoded PNG/JPEG bytes.
  static Future<Uint8List> burnTelemetryOverlay({
    required Uint8List imageBytes,
    required SoilReading rawReading,
    required CalibratedSoilResult calibrated,
    GeoLocationData? location,
  }) async {
    // 1. Decode original image
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final ui.Image baseImage = frame.image;

    final width = baseImage.width.toDouble();
    final height = baseImage.height.toDouble();

    // Responsive scaling factor based on 1080p reference width
    final scale = (width / 1080.0).clamp(0.6, 3.5);

    // 2. Prepare Canvas Recorder
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, width, height));

    // 3. Draw base image
    canvas.drawImage(baseImage, ui.Offset.zero, ui.Paint());

    // 4. Draw Top Header Bar (App Branding + GPS + Timestamp)
    _drawTopHeader(
      canvas: canvas,
      width: width,
      scale: scale,
      location: location,
      reading: rawReading,
    );

    // 5. Draw Center Cyber Targeting Reticle
    _drawCenterReticle(
      canvas: canvas,
      width: width,
      height: height,
      scale: scale,
    );

    // 6. Draw Bottom Agronomic Telemetry HUD (8-in-1 parameters + AI PINN)
    _drawBottomTelemetryHud(
      canvas: canvas,
      width: width,
      height: height,
      scale: scale,
      reading: rawReading,
      calibrated: calibrated,
    );

    // 7. Finish recording and encode
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
    required SoilReading reading,
  }) {
    final barHeight = 110.0 * scale;
    final bgPaint = ui.Paint()
      ..shader = ui.Gradient.linear(
        const ui.Offset(0, 0),
        ui.Offset(0, barHeight),
        [
          const Color(0xDD000000),
          const Color(0x99000000),
          const Color(0x00000000),
        ],
        [0.0, 0.7, 1.0],
      );

    canvas.drawRect(ui.Rect.fromLTWH(0, 0, width, barHeight), bgPaint);

    final nowStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());

    // App Title
    _drawText(
      canvas: canvas,
      text: '🌱 JC SOIL AI ANALYZER  |  SciRBRU AgriPhysics',
      offset: ui.Offset(24 * scale, 18 * scale),
      fontSize: 22 * scale,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF00FFFF),
      letterSpacing: 0.8 * scale,
    );

    // GPS & Timestamp line
    final lat = location?.latitude ?? reading.latitude;
    final lon = location?.longitude ?? reading.longitude;
    final alt = location?.altitude ?? reading.altitude ?? 0.0;

    String gpsStr = '📍 GPS: ไม่ระบุพิกัด';
    if (lat != null && lon != null && (lat != 0.0 || lon != 0.0)) {
      gpsStr = '📍 ${lat.toStringAsFixed(5)}° N, ${lon.toStringAsFixed(5)}° E  |  Alt: ${alt.toStringAsFixed(1)}m';
    }

    _drawText(
      canvas: canvas,
      text: '$gpsStr   •   $nowStr',
      offset: ui.Offset(24 * scale, 48 * scale),
      fontSize: 14 * scale,
      fontWeight: FontWeight.w600,
      color: const Color(0xFFEEEEEE),
      fontFamily: 'monospace',
    );
  }

  static void _drawCenterReticle({
    required ui.Canvas canvas,
    required double width,
    required double height,
    required double scale,
  }) {
    final centerX = width / 2;
    final centerY = height / 2 - (30 * scale);
    final boxSize = 220.0 * scale;
    final half = boxSize / 2;
    final cornerLen = 28.0 * scale;

    final strokePaint = ui.Paint()
      ..color = const Color(0xAA00FFFF)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3.0 * scale;

    // Top-Left corner
    canvas.drawLine(ui.Offset(centerX - half, centerY - half), ui.Offset(centerX - half + cornerLen, centerY - half), strokePaint);
    canvas.drawLine(ui.Offset(centerX - half, centerY - half), ui.Offset(centerX - half, centerY - half + cornerLen), strokePaint);

    // Top-Right corner
    canvas.drawLine(ui.Offset(centerX + half, centerY - half), ui.Offset(centerX + half - cornerLen, centerY - half), strokePaint);
    canvas.drawLine(ui.Offset(centerX + half, centerY - half), ui.Offset(centerX + half, centerY - half + cornerLen), strokePaint);

    // Bottom-Left corner
    canvas.drawLine(ui.Offset(centerX - half, centerY + half), ui.Offset(centerX - half + cornerLen, centerY + half), strokePaint);
    canvas.drawLine(ui.Offset(centerX - half, centerY + half), ui.Offset(centerX - half, centerY + half - cornerLen), strokePaint);

    // Bottom-Right corner
    canvas.drawLine(ui.Offset(centerX + half, centerY + half), ui.Offset(centerX + half - cornerLen, centerY + half), strokePaint);
    canvas.drawLine(ui.Offset(centerX + half, centerY + half), ui.Offset(centerX + half, centerY + half - cornerLen), strokePaint);

    // Center Crosshair
    final crossLen = 14.0 * scale;
    canvas.drawLine(ui.Offset(centerX - crossLen, centerY), ui.Offset(centerX + crossLen, centerY), strokePaint);
    canvas.drawLine(ui.Offset(centerX, centerY - crossLen), ui.Offset(centerX, centerY + crossLen), strokePaint);

    // Reticle Label
    _drawText(
      canvas: canvas,
      text: '[ + ] SOIL TARGET ZONE',
      offset: ui.Offset(centerX - (70 * scale), centerY + half + (8 * scale)),
      fontSize: 12 * scale,
      fontWeight: FontWeight.bold,
      color: const Color(0xDD00FFFF),
      letterSpacing: 1.0 * scale,
    );
  }

  static void _drawBottomTelemetryHud({
    required ui.Canvas canvas,
    required double width,
    required double height,
    required double scale,
    required SoilReading reading,
    required CalibratedSoilResult calibrated,
  }) {
    final hudHeight = 220.0 * scale;
    final topY = height - hudHeight;

    // Background Gradient Panel
    final bgPaint = ui.Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(0, topY),
        ui.Offset(0, height),
        [
          const Color(0x00000000),
          const Color(0xCC0A0E14),
          const Color(0xF00A0E14),
        ],
        [0.0, 0.25, 1.0],
      );
    canvas.drawRect(ui.Rect.fromLTWH(0, topY, width, hudHeight), bgPaint);

    // 8-in-1 Parameter Cards (2 rows of 4 items)
    final marginX = 20.0 * scale;
    final cardW = (width - (marginX * 2) - (24 * scale)) / 4;
    final cardH = 50.0 * scale;
    final row1Y = topY + (45 * scale);
    final row2Y = row1Y + cardH + (10 * scale);

    final paramsRow1 = [
      _ParamItem('Temp', '${reading.temperature.toStringAsFixed(1)}°C', const Color(0xFF388E3C)),
      _ParamItem('Moisture', '${reading.moisture.toStringAsFixed(1)}%', const Color(0xFF1976D2)),
      _ParamItem('EC', '${reading.conductivity}µS', const Color(0xFF7B1FA2)),
      _ParamItem('pH', reading.ph.toStringAsFixed(2), const Color(0xFFE65100)),
    ];

    final paramsRow2 = [
      _ParamItem('N (Nitrogen)', '${reading.nitrogen} mg/kg', const Color(0xFFC2185B)),
      _ParamItem('P (Phosphorus)', '${reading.phosphorus} mg/kg', const Color(0xFF0288D1)),
      _ParamItem('K (Potassium)', '${reading.potassium} mg/kg', const Color(0xFF00897B)),
      _ParamItem('Fertility', '${reading.fertility}', const Color(0xFFE64A19)),
    ];

    for (int i = 0; i < 4; i++) {
      final x = marginX + (i * (cardW + (8 * scale)));
      _drawParamCard(canvas, x, row1Y, cardW, cardH, paramsRow1[i], scale);
      _drawParamCard(canvas, x, row2Y, cardW, cardH, paramsRow2[i], scale);
    }

    // AI PINN Calibration Banner at the very bottom
    final pinnY = row2Y + cardH + (10 * scale);
    final pinnBgPaint = ui.Paint()
      ..color = const Color(0xCC003B46)
      ..style = ui.PaintingStyle.fill;

    final pinnRect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(marginX, pinnY, width - (marginX * 2), 34 * scale),
      ui.Radius.circular(6 * scale),
    );
    canvas.drawRRect(pinnRect, pinnBgPaint);

    final confStr = calibrated.confidenceScore > 0
        ? ' (Conf: ${(calibrated.confidenceScore * 100).toStringAsFixed(1)}%)'
        : '';
    final pinnText =
        '🤖 AI PINN CALIBRATION: pH ${calibrated.calibratedReading.ph.toStringAsFixed(2)}  |  EC ${calibrated.calibratedReading.conductivity}µS  |  Moisture ${calibrated.calibratedReading.moisture.toStringAsFixed(1)}%$confStr';

    _drawText(
      canvas: canvas,
      text: pinnText,
      offset: ui.Offset(marginX + (12 * scale), pinnY + (8 * scale)),
      fontSize: 12.5 * scale,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF00FFAA),
      letterSpacing: 0.4 * scale,
    );
  }

  static void _drawParamCard(
    ui.Canvas canvas,
    double x,
    double y,
    double w,
    double h,
    _ParamItem item,
    double scale,
  ) {
    // Card background
    final bgPaint = ui.Paint()
      ..color = const Color(0xCC1A212B)
      ..style = ui.PaintingStyle.fill;
    final rrect = ui.RRect.fromRectAndRadius(
      ui.Rect.fromLTWH(x, y, w, h),
      ui.Radius.circular(6 * scale),
    );
    canvas.drawRRect(rrect, bgPaint);

    // Left colored accent border
    final borderPaint = ui.Paint()
      ..color = item.color
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    canvas.drawRRect(rrect, borderPaint);

    // Label
    _drawText(
      canvas: canvas,
      text: item.label,
      offset: ui.Offset(x + (6 * scale), y + (5 * scale)),
      fontSize: 9.5 * scale,
      fontWeight: FontWeight.w600,
      color: const Color(0xFFBBBBBB),
    );

    // Value
    _drawText(
      canvas: canvas,
      text: item.value,
      offset: ui.Offset(x + (6 * scale), y + (22 * scale)),
      fontSize: 14 * scale,
      fontWeight: FontWeight.bold,
      color: item.color,
      fontFamily: 'monospace',
    );
  }

  static void _drawText({
    required ui.Canvas canvas,
    required String text,
    required ui.Offset offset,
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.white,
    double letterSpacing = 0.0,
    String? fontFamily,
  }) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );

    builder.pushStyle(ui.TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      fontFamily: fontFamily,
    ));

    builder.addText(text);
    final paragraph = builder.build()..layout(const ui.ParagraphConstraints(width: 4000));
    canvas.drawParagraph(paragraph, offset);
  }
}

class _ParamItem {
  final String label;
  final String value;
  final Color color;

  const _ParamItem(this.label, this.value, this.color);
}
