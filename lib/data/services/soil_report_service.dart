import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/soil_dataset_item.dart';
import 'soil_dataset_service.dart';

/// Service responsible for:
/// 1. Generating professional A4 Soil Health & Diagnostic Certificates
/// 2. Exporting spatial geospatial datasets (GeoJSON & KML)
class SoilReportService {
  final Future<Directory> Function() getDataDir;

  SoilReportService({Future<Directory> Function()? dataDirProvider})
      : getDataDir = dataDirProvider ?? SoilDatasetService.getDataDirectory;

  /// Generates a comprehensive A4 Printable Soil Health Certificate
  /// and saves it to `soil_dataset/data/SOIL_REPORT_<sampleId>.html`
  Future<File> generateSoilCertificate(SoilDatasetItem item) async {
    final dataDir = await getDataDir();
    final fileName = 'SOIL_REPORT_${item.sampleId}.html';
    final targetFile = File('${dataDir.path}/$fileName');

    final htmlContent = _buildCertificateHtml(item);
    await targetFile.writeAsString(htmlContent, encoding: utf8);
    return targetFile;
  }

  /// Generates the certificate and immediately invokes Native Share Sheet
  Future<void> generateAndShareCertificate(SoilDatasetItem item) async {
    final file = await generateSoilCertificate(item);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'ใบรายงานผลวิเคราะห์คุณภาพดิน A4 - ${item.sampleId}',
      text: 'ใบรับรองผลตรวจคุณภาพดินและคำแนะนำปุ๋ยเฉพาะแปลง (SciRBRU AgriPhysics) รหัสตัวอย่าง: ${item.sampleId}',
    );
  }

  /// Exports all geotagged samples to RFC 7946 GeoJSON FeatureCollection
  Future<File> exportGeoJson(List<SoilDatasetItem> items) async {
    final dataDir = await getDataDir();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final targetFile = File('${dataDir.path}/soil_spatial_dataset_$timestamp.geojson');

    final features = <Map<String, dynamic>>[];

    for (final item in items) {
      if (item.hasGps) {
        final healthScore = _calculateHealthScore(item);
        features.add({
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [
              item.longitude,
              item.latitude,
              item.altitude,
            ],
          },
          'properties': {
            'sampleId': item.sampleId,
            'timestamp': item.timestamp.toIso8601String(),
            'mediaType': item.mediaType,
            'fileName': item.fileName,
            'temperature': item.temperature,
            'moisture': item.moisture,
            'ec': item.ec,
            'ph': item.ph,
            'nitrogen': item.nitrogen,
            'phosphorus': item.phosphorus,
            'potassium': item.potassium,
            'salinity': item.salinity,
            'soilColorHex': item.soilColorHex,
            'healthScore': healthScore,
          },
        });
      }
    }

    final geoJson = {
      'type': 'FeatureCollection',
      'name': 'JC_Soil_AI_Survey_Dataset',
      'crs': {
        'type': 'name',
        'properties': {'name': 'urn:ogc:def:crs:OGC:1.3:CRS84'}
      },
      'features': features,
    };

    final content = const JsonEncoder.withIndent('  ').convert(geoJson);
    await targetFile.writeAsString(content, encoding: utf8);
    return targetFile;
  }

  /// Exports all geotagged samples to OGC KML for Google Earth
  Future<File> exportKml(List<SoilDatasetItem> items) async {
    final dataDir = await getDataDir();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final targetFile = File('${dataDir.path}/soil_spatial_dataset_$timestamp.kml');

    final sb = StringBuffer();
    sb.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    sb.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    sb.writeln('  <Document>');
    sb.writeln('    <name>JC Soil AI Precision Survey Dataset</name>');
    sb.writeln('    <description>Ground-truth soil parameters collected via SciRBRU AgriPhysics 8-in-1 Modbus Probe</description>');

    for (final item in items) {
      if (item.hasGps) {
        final score = _calculateHealthScore(item);
        sb.writeln('    <Placemark>');
        sb.writeln('      <name>${item.sampleId}</name>');
        sb.writeln('      <description><![CDATA[');
        sb.writeln('        <h3>JC SOIL AI SURVEY POINT</h3>');
        sb.writeln('        <p><b>Date:</b> ${item.timestamp}</p>');
        sb.writeln('        <p><b>Soil Health:</b> $score / 100</p>');
        sb.writeln('        <table border="1" cellpadding="4" style="border-collapse:collapse;">');
        sb.writeln('          <tr><th>pH</th><td>${item.ph.toStringAsFixed(2)}</td></tr>');
        sb.writeln('          <tr><th>Moisture</th><td>${item.moisture.toStringAsFixed(1)} %</td></tr>');
        sb.writeln('          <tr><th>EC</th><td>${item.ec.toStringAsFixed(0)} µS/cm</td></tr>');
        sb.writeln('          <tr><th>Nitrogen (N)</th><td>${item.nitrogen.toStringAsFixed(1)} mg/kg</td></tr>');
        sb.writeln('          <tr><th>Phosphorus (P)</th><td>${item.phosphorus.toStringAsFixed(1)} mg/kg</td></tr>');
        sb.writeln('          <tr><th>Potassium (K)</th><td>${item.potassium.toStringAsFixed(1)} mg/kg</td></tr>');
        sb.writeln('          <tr><th>Temperature</th><td>${item.temperature.toStringAsFixed(1)} °C</td></tr>');
        sb.writeln('        </table>');
        sb.writeln('      ]]></description>');
        sb.writeln('      <Point>');
        sb.writeln('        <coordinates>${item.longitude},${item.latitude},${item.altitude}</coordinates>');
        sb.writeln('      </Point>');
        sb.writeln('    </Placemark>');
      }
    }

    sb.writeln('  </Document>');
    sb.writeln('</kml>');

    await targetFile.writeAsString(sb.toString(), encoding: utf8);
    return targetFile;
  }

  // --- Internal Helper Methods ---

  static int _calculateHealthScore(SoilDatasetItem item) {
    double score = 100.0;

    // pH penalty (optimal: 5.5 - 6.5)
    if (item.ph < 4.5 || item.ph > 8.0) {
      score -= 25;
    } else if (item.ph < 5.5 || item.ph > 7.0) {
      score -= 12;
    }

    // Moisture penalty (optimal: 30% - 60%)
    if (item.moisture < 20 || item.moisture > 75) {
      score -= 20;
    } else if (item.moisture < 30 || item.moisture > 65) {
      score -= 10;
    }

    // EC penalty (optimal: < 1000 µS/cm)
    if (item.ec > 1800) {
      score -= 25;
    } else if (item.ec > 1200) {
      score -= 12;
    }

    // NPK check
    if (item.nitrogen < 15) score -= 8;
    if (item.phosphorus < 10) score -= 8;
    if (item.potassium < 25) score -= 8;

    return score.clamp(15, 100).toInt();
  }

  String _buildCertificateHtml(SoilDatasetItem item) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(item.timestamp);
    final healthScore = _calculateHealthScore(item);

    final phStatus = item.ph < 4.5
        ? 'กรดจัดรุนแรง (Very Strong Acid)'
        : item.ph < 5.5
            ? 'กรดจัด (Strongly Acid)'
            : item.ph <= 6.5
                ? 'เหมาะสมดีมาก (Optimum)'
                : item.ph <= 7.5
                    ? 'เป็นกลาง (Neutral)'
                    : 'ดินด่าง (Alkaline)';

    final moistureStatus = item.moisture < 30
        ? 'ความชื้นต่ำ/แห้ง (Low/Dry)'
        : item.moisture <= 65
            ? 'เหมาะสมดี (Optimum)'
            : 'ความชื้นสูง/น้ำขัง (Excessive)';

    final ecStatus = item.ec < 800
        ? 'ปกติ/ปลอดเค็ม (Non-Saline)'
        : item.ec <= 1500
            ? 'ปานกลาง (Slightly Saline)'
            : 'ความเค็มสูง (Saline Hazard)';

    final nStatus = item.nitrogen < 20 ? 'ต่ำ (Low)' : item.nitrogen <= 45 ? 'ปานกลาง (Medium)' : 'สูง (High)';
    final pStatus = item.phosphorus < 15 ? 'ต่ำ (Low)' : item.phosphorus <= 35 ? 'ปานกลาง (Medium)' : 'สูง (High)';
    final kStatus = item.potassium < 30 ? 'ต่ำ (Low)' : item.potassium <= 65 ? 'ปานกลาง (Medium)' : 'สูง (High)';

    // Recommendations
    final dolomiteAdvice = item.ph < 4.5
        ? 'ดินเป็นกรดจัดรุนแรง แนะนำหว่านปูนโดโลไมต์ 250 - 300 กิโลกรัม/ไร่ เพื่อยกระดับ pH'
        : item.ph < 5.5
            ? 'ดินเป็นกรด แนะนำหว่านปูนโดโลไมต์ 100 - 150 กิโลกรัม/ไร่ เพื่อปรับสมดุลดิน'
            : 'ค่ากรด-ด่างอยู่ในเกณฑ์ที่เหมาะสม ไม่จำเป็นต้องใส่ปูนปรับสภาพดิน';

    final waterAdvice = item.moisture < 30
        ? 'ดินขาดความชื้น แนะนำให้น้ำระบบสปริงเกลอร์หรือน้ำหยดรอบละ 25-35 นาที วันเว้นวัน'
        : item.moisture > 65
            ? 'ดินแฉะเกินไป เสี่ยงต่อโรครากเน่าโคนเน่า แนะนำเปิดร่องระบายน้ำและงดการให้น้ำ'
            : 'ระดับความชื้นในดินเหมาะสม รักษาตารางการให้น้ำตามปกติ';

    final fertilizerFormula = item.nitrogen < 20 && item.phosphorus < 15
        ? 'ปุ๋ยสูตร 16-16-16 หรือ 15-15-15 อัตรา 25 กก./ไร่ ร่วมกับปุ๋ยหมักอินทรีย์ 300 กก./ไร่'
        : item.potassium < 30
            ? 'เสริมปุ๋ยโพแทสเซียม 0-0-60 อัตรา 15 กก./ไร่ ร่วมกับสูตรเสมอ 15-15-15'
            : 'ใช้ปุ๋ยอินทรีย์เคมีสูตรบำรุงต้นใบปกติ 15-15-15 อัตรา 20 กก./ไร่';

    return '''<!DOCTYPE html>
<html lang="th">
<head>
  <meta charset="UTF-8">
  <title>SOIL HEALTH CERTIFICATE - ${item.sampleId}</title>
  <style>
    @page {
      size: A4 portrait;
      margin: 10mm 12mm 10mm 12mm;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Sarabun', 'Helvetica Neue', Arial, sans-serif;
      color: #1f2937;
      background: #ffffff;
      line-height: 1.45;
      font-size: 13px;
      padding: 10px;
    }
    .cert-border {
      border: 2px solid #059669;
      border-radius: 8px;
      padding: 18px 22px;
      position: relative;
    }
    .cert-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      border-bottom: 2px solid #10b981;
      padding-bottom: 12px;
      margin-bottom: 14px;
    }
    .header-titles h1 {
      font-size: 18px;
      font-weight: 800;
      color: #065f46;
      letter-spacing: 0.5px;
    }
    .header-titles h2 {
      font-size: 13px;
      font-weight: 600;
      color: #047857;
    }
    .header-titles p {
      font-size: 11px;
      color: #4b5563;
    }
    .cert-badge {
      text-align: right;
    }
    .score-circle {
      display: inline-block;
      width: 58px;
      height: 58px;
      border-radius: 50%;
      background: #ecfdf5;
      border: 3px solid #10b981;
      color: #065f46;
      text-align: center;
      line-height: 52px;
      font-size: 20px;
      font-weight: bold;
    }
    .score-label {
      font-size: 10px;
      font-weight: bold;
      color: #059669;
      display: block;
      margin-top: 2px;
    }
    .meta-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 8px;
      background: #f9fafb;
      border: 1px solid #e5e7eb;
      border-radius: 6px;
      padding: 10px 14px;
      margin-bottom: 14px;
      font-size: 12px;
    }
    .meta-item b { color: #374151; }
    .section-title {
      font-size: 13px;
      font-weight: bold;
      color: #065f46;
      border-left: 4px solid #10b981;
      padding-left: 8px;
      margin: 12px 0 6px 0;
      text-transform: uppercase;
    }
    table.data-table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 12px;
    }
    table.data-table th {
      background: #f0fdf4;
      color: #065f46;
      border: 1px solid #d1fae5;
      padding: 6px 10px;
      font-size: 11.5px;
      text-align: left;
    }
    table.data-table td {
      border: 1px solid #e5e7eb;
      padding: 6px 10px;
      font-size: 11.5px;
    }
    table.data-table tr:nth-child(even) { background: #fafafa; }
    .status-optimum { color: #059669; font-weight: bold; }
    .status-warn { color: #d97706; font-weight: bold; }
    .status-alert { color: #dc2626; font-weight: bold; }
    .rx-box {
      background: #eff6ff;
      border: 1px solid #bfdbfe;
      border-radius: 6px;
      padding: 10px 14px;
      margin-bottom: 12px;
    }
    .rx-item {
      margin-bottom: 6px;
      font-size: 11.5px;
    }
    .rx-item b { color: #1e40af; }
    .footer-sign {
      display: grid;
      grid-template-columns: 1fr 1fr;
      margin-top: 18px;
      padding-top: 10px;
      border-top: 1px dashed #cbd5e1;
      font-size: 11px;
      color: #64748b;
    }
    .sign-box { text-align: center; }
    .sign-line {
      margin-top: 28px;
      border-top: 1px solid #94a3b8;
      width: 180px;
      display: inline-block;
    }
    @media print {
      body { padding: 0; }
      .cert-border { border: 1.5px solid #059669; }
    }
  </style>
</head>
<body>
  <div class="cert-border">
    <div class="cert-header">
      <div class="header-titles">
        <h1>JC SOIL AI ANALYZER | SciRBRU AgriPhysics</h1>
        <h2>ใบรับรองผลการตรวจวิเคราะห์คุณภาพดินและใบสั่งสูตรปุ๋ยแม่นยำสูง</h2>
        <p>หน่วยวิจัยฟิสิกส์เกษตรดิจิทัล คณะวิทยาศาสตร์และเทคโนโลยี มหาวิทยาลัยราชภัฏรำไพพรรณี</p>
      </div>
      <div class="cert-badge">
        <div class="score-circle">$healthScore</div>
        <span class="score-label">SOIL HEALTH SCORE</span>
      </div>
    </div>

    <div class="meta-grid">
      <div class="meta-item"><b>รหัสตัวอย่างดิน (Sample ID):</b> ${item.sampleId}</div>
      <div class="meta-item"><b>วันเวลาตรวจวัด (Survey Time):</b> $dateStr</div>
      <div class="meta-item"><b>พิกัดดาวเทียม (GPS Lat, Long):</b> ${item.latitude.toStringAsFixed(6)}, ${item.longitude.toStringAsFixed(6)}</div>
      <div class="meta-item"><b>ระดับความสูง / แฟ้มสื่อ:</b> ${item.altitude.toStringAsFixed(1)} m (${item.mediaType})</div>
    </div>

    <div class="section-title">1. ตารางผลการตรวจวัด 8 พารามิเตอร์ (Ground-Truth & PINN Diagnostics)</div>
    <table class="data-table">
      <thead>
        <tr>
          <th>พารามิเตอร์ (Parameter)</th>
          <th>ค่าที่ตรวจวัดได้ (Measured)</th>
          <th>เกณฑ์อ้างอิง FAO/พด. (Standard Range)</th>
          <th>การประเมินสถานะ (Diagnostic Status)</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><b>ความเป็นกรด-ด่าง (Soil pH)</b></td>
          <td><b>${item.ph.toStringAsFixed(2)}</b></td>
          <td>5.50 - 6.50 (ดินสวน/ไม้ผล)</td>
          <td class="${item.ph >= 5.5 && item.ph <= 6.5 ? 'status-optimum' : 'status-alert'}">$phStatus</td>
        </tr>
        <tr>
          <td><b>ความชื้นในดิน (Soil Moisture)</b></td>
          <td><b>${item.moisture.toStringAsFixed(1)} %</b></td>
          <td>35.0 - 60.0 % (VWC)</td>
          <td class="${item.moisture >= 30 && item.moisture <= 65 ? 'status-optimum' : 'status-warn'}">$moistureStatus</td>
        </tr>
        <tr>
          <td><b>สภาพนำไฟฟ้า (Conductivity EC)</b></td>
          <td><b>${item.ec.toStringAsFixed(0)} µS/cm</b></td>
          <td>< 1,000 µS/cm (ความเค็มปลอดภัย)</td>
          <td class="${item.ec < 1000 ? 'status-optimum' : 'status-alert'}">$ecStatus</td>
        </tr>
        <tr>
          <td><b>ไนโตรเจนที่ใช้ได้ (Available N)</b></td>
          <td><b>${item.nitrogen.toStringAsFixed(1)} mg/kg</b></td>
          <td>25.0 - 45.0 mg/kg</td>
          <td class="${item.nitrogen >= 20 ? 'status-optimum' : 'status-warn'}">$nStatus</td>
        </tr>
        <tr>
          <td><b>ฟอสฟอรัสที่เป็นประโยชน์ (Available P)</b></td>
          <td><b>${item.phosphorus.toStringAsFixed(1)} mg/kg</b></td>
          <td>15.0 - 35.0 mg/kg</td>
          <td class="${item.phosphorus >= 15 ? 'status-optimum' : 'status-warn'}">$pStatus</td>
        </tr>
        <tr>
          <td><b>โพแทสเซียมที่แลกเปลี่ยนได้ (Exchangeable K)</b></td>
          <td><b>${item.potassium.toStringAsFixed(1)} mg/kg</b></td>
          <td>40.0 - 80.0 mg/kg</td>
          <td class="${item.potassium >= 30 ? 'status-optimum' : 'status-warn'}">$kStatus</td>
        </tr>
        <tr>
          <td><b>อุณหภูมิในเขตราก (Soil Temperature)</b></td>
          <td><b>${item.temperature.toStringAsFixed(1)} °C</b></td>
          <td>24.0 - 32.0 °C (PINN Corrected)</td>
          <td class="status-optimum">ชดเชยอุณหภูมิเรียบร้อย</td>
        </tr>
        <tr>
          <td><b>สีดินดิจิทัล (Munsell Soil Color)</b></td>
          <td><b>${item.soilColorHex ?? '#5C4033'}</b></td>
          <td>CIE L*a*b* & Munsell Vision Target</td>
          <td class="status-optimum">ตรวจจับด้วยกล้อง AI</td>
        </tr>
      </tbody>
    </table>

    <div class="section-title">2. แผนข้อเสนอแนะและใบสั่งสูตรปุ๋ยเฉพาะแปลง (Agronomic Action Plan)</div>
    <div class="rx-box">
      <div class="rx-item"><b>🔘 การปรับปรุงค่ากรด-ด่างดิน:</b> $dolomiteAdvice</div>
      <div class="rx-item"><b>🔘 การบริหารจัดการน้ำในแปลง:</b> $waterAdvice</div>
      <div class="rx-item"><b>🔘 ใบสั่งสูตรปุ๋ยเฉพาะแปลง:</b> $fertilizerFormula</div>
      <div class="rx-item"><b>🔘 การป้องกันโรคทางดิน:</b> ใส่เชื้อราไตรโคเดอร์มาผสมปุ๋ยหมักรอบทรงพุ่มเพื่อยับยั้งเชื้อราไฟทอปธอรา (Phytophthora)</div>
    </div>

    <div class="footer-sign">
      <div>
        <p>เอกสารรับรองทางดิจิทัลจากระบบ JC Soil AI Analyzer v1.0.1</p>
        <p>บันทึกในฐานข้อมูลวิจัย: soil_dataset/data/dataset_manifest.json</p>
      </div>
      <div class="sign-box">
        <div class="sign-line"></div>
        <p>(นักวิจัย / ผู้ตรวจวัดภาคสนาม)</p>
        <p>SciRBRU Digital Agriphysics Lab</p>
      </div>
    </div>
  </div>
</body>
</html>''';
  }
}
