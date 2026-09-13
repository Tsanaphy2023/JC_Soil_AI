import 'dart:io';
import 'package:intl/intl.dart';

/// Data model representing a captured multimodal soil dataset item (Photo or Video)
/// with linked GPS coordinates, 8-in-1 Modbus ground-truth, and AI PINN telemetry.
class SoilDatasetItem {
  final String sampleId;
  final DateTime timestamp;
  final String mediaType; // 'image' or 'video'
  final String filePath;
  final String fileName;
  final double latitude;
  final double longitude;
  final double altitude;
  final int? durationSeconds;

  // Sensor ground-truth measurements
  final double temperature;
  final double moisture;
  final int conductivity;
  final double ph;
  final int nitrogen;
  final int phosphorus;
  final int potassium;
  final int fertility;

  // AI PINN Calibrated values (if available)
  final double? aiMoisture;
  final int? aiConductivity;
  final double? aiPh;
  final int? aiNitrogen;
  final int? aiPhosphorus;
  final int? aiPotassium;
  final double? aiConfidenceScore;

  const SoilDatasetItem({
    required this.sampleId,
    required this.timestamp,
    required this.mediaType,
    required this.filePath,
    required this.fileName,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    this.durationSeconds,
    required this.temperature,
    required this.moisture,
    required this.conductivity,
    required this.ph,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.fertility,
    this.aiMoisture,
    this.aiConductivity,
    this.aiPh,
    this.aiNitrogen,
    this.aiPhosphorus,
    this.aiPotassium,
    this.aiConfidenceScore,
  });

  bool get isImage => mediaType == 'image';
  bool get isVideo => mediaType == 'video';

  bool get fileExists => File(filePath).existsSync();

  int get fileSizeBytes {
    try {
      final file = File(filePath);
      return file.existsSync() ? file.lengthSync() : 0;
    } catch (_) {
      return 0;
    }
  }

  String get formattedFileSize {
    final bytes = fileSizeBytes;
    if (bytes <= 0) return '0 KB';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String get formattedDate {
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(timestamp);
  }

  String get formattedShortDate {
    return DateFormat('dd MMM yyyy, HH:mm').format(timestamp);
  }

  String get formattedGps {
    if (latitude == 0.0 && longitude == 0.0) return 'พิกัด: ไม่ระบุ (No GPS)';
    return '${latitude.toStringAsFixed(5)}°, ${longitude.toStringAsFixed(5)}° (Alt: ${altitude.toStringAsFixed(1)}m)';
  }

  String get googleMapsUrl {
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }

  /// Formatted comprehensive caption text suitable for instant sharing (LINE, WhatsApp, Email, etc.)
  String toFormattedCaption() {
    final dateStr = formattedDate;
    final typeStr = isImage ? '📷 ภาพถ่ายตัวอย่างดิน (Soil Image)' : '🎥 วิดีโอแปลงดิน (Soil Video)';
    final durationStr = isVideo && durationSeconds != null ? 'ความยาวคลิป: $durationSeconds วินาที\n' : '';

    return '''
🌿 [SOIL AI ANALYZER - ข้อมูลตัวอย่างดินวิจัย]
รหัสตัวอย่าง: $sampleId
ประเภท: $typeStr
เวลาบันทึก: $dateStr
$durationStr📍 พิกัดแปลงเกษตร: ${latitude.toStringAsFixed(5)}° N, ${longitude.toStringAsFixed(5)}° E
ความสูงระดับน้ำทะเล: ${altitude.toStringAsFixed(1)} เมตร
แผนที่: $googleMapsUrl

📊 ผลการตรวจวัดเซนเซอร์ 8-in-1 (Sensor Ground-Truth):
• อุณหภูมิดิน (Temp): ${temperature.toStringAsFixed(1)} °C
• ความชื้นในดิน (Moist): ${moisture.toStringAsFixed(1)} %
• การนำไฟฟ้า (EC): $conductivity µS/cm
• ความเป็นกรด-ด่าง (pH): ${ph.toStringAsFixed(2)}
• ไนโตรเจน (N): $nitrogen mg/kg
• ฟอสฟอรัส (P): $phosphorus mg/kg
• โพแทสเซียม (K): $potassium mg/kg
• ดัชนีความอุดมสมบูรณ์: $fertility

🤖 การสอบเทียบปัญญาประดิษฐ์ (AI PINN Model):
${aiConfidenceScore != null ? '• ดัชนีความเชื่อมั่น (Confidence): ${(aiConfidenceScore! * 100).toStringAsFixed(1)}%\n' : ''}• pH หลังสอบเทียบ: ${aiPh?.toStringAsFixed(2) ?? ph.toStringAsFixed(2)}
• EC หลังสอบเทียบ: ${aiConductivity ?? conductivity} µS/cm
• ความชื้นหลังสอบเทียบ: ${aiMoisture?.toStringAsFixed(1) ?? moisture.toStringAsFixed(1)}%

บันทึกโดยแอปพลิเคชัน: SOIL AI ANALYZER (JC Soil AI)
มหาวิทยาลัยราชภัฏรำไพพรรณี (RBRU Agriphysics)
'''.trim();
  }

  factory SoilDatasetItem.fromJson(Map<String, dynamic> json) {
    final gps = (json['gps'] as Map<String, dynamic>?) ?? {};
    final sensor = (json['sensor_ground_truth'] as Map<String, dynamic>?) ?? {};
    final pinn = (json['ai_pinn_calibrated'] as Map<String, dynamic>?) ?? {};

    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['timestamp'] as String? ?? '');
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return SoilDatasetItem(
      sampleId: json['sample_id'] as String? ?? 'SAMPLE_${parsedDate.millisecondsSinceEpoch}',
      timestamp: parsedDate,
      mediaType: json['media_type'] as String? ?? 'image',
      filePath: json['file_path'] as String? ?? '',
      fileName: json['file_name'] as String? ?? '',
      latitude: (gps['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (gps['longitude'] as num?)?.toDouble() ?? 0.0,
      altitude: (gps['altitude'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: json['duration_seconds'] as int?,
      temperature: (sensor['temperature'] as num?)?.toDouble() ?? 0.0,
      moisture: (sensor['moisture'] as num?)?.toDouble() ?? 0.0,
      conductivity: (sensor['conductivity_ec'] as num?)?.toInt() ?? 0,
      ph: (sensor['ph'] as num?)?.toDouble() ?? 7.0,
      nitrogen: (sensor['nitrogen'] as num?)?.toInt() ?? 0,
      phosphorus: (sensor['phosphorus'] as num?)?.toInt() ?? 0,
      potassium: (sensor['potassium'] as num?)?.toInt() ?? 0,
      fertility: (sensor['fertility'] as num?)?.toInt() ?? 0,
      aiMoisture: (pinn['moisture'] as num?)?.toDouble(),
      aiConductivity: (pinn['conductivity_ec'] as num?)?.toInt(),
      aiPh: (pinn['ph'] as num?)?.toDouble(),
      aiNitrogen: (pinn['nitrogen'] as num?)?.toInt(),
      aiPhosphorus: (pinn['phosphorus'] as num?)?.toInt(),
      aiPotassium: (pinn['potassium'] as num?)?.toInt(),
      aiConfidenceScore: (pinn['confidence_score'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sample_id': sampleId,
      'timestamp': timestamp.toIso8601String(),
      'media_type': mediaType,
      'file_path': filePath,
      'file_name': fileName,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      'gps': {
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
      },
      'sensor_ground_truth': {
        'temperature': temperature,
        'moisture': moisture,
        'conductivity_ec': conductivity,
        'ph': ph,
        'nitrogen': nitrogen,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'fertility': fertility,
      },
      if (aiConfidenceScore != null || aiPh != null)
        'ai_pinn_calibrated': {
          if (aiMoisture != null) 'moisture': aiMoisture,
          if (aiConductivity != null) 'conductivity_ec': aiConductivity,
          if (aiPh != null) 'ph': aiPh,
          if (aiNitrogen != null) 'nitrogen': aiNitrogen,
          if (aiPhosphorus != null) 'phosphorus': aiPhosphorus,
          if (aiPotassium != null) 'potassium': aiPotassium,
          if (aiConfidenceScore != null) 'confidence_score': aiConfidenceScore,
        },
    };
  }
}
