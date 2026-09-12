import '../../data/models/soil_reading.dart';

enum MoistureStatus { dry, optimal, saturated }
enum SalinityStatus { nonSaline, optimal, moderate, highSalinity }
enum PhStatus { stronglyAcidic, moderatelyAcidic, optimal, alkaline }

/// Agronomic evaluation engine for precision agriculture soil diagnostics
class AgronomicAssessment {
  final MoistureStatus moistureStatus;
  final String moistureMessage;

  final SalinityStatus salinityStatus;
  final String salinityMessage;

  final PhStatus phStatus;
  final String phMessage;

  final String npkSummary;
  final String recommendation;

  const AgronomicAssessment({
    required this.moistureStatus,
    required this.moistureMessage,
    required this.salinityStatus,
    required this.salinityMessage,
    required this.phStatus,
    required this.phMessage,
    required this.npkSummary,
    required this.recommendation,
  });

  factory AgronomicAssessment.evaluate(SoilReading reading) {
    // 1. Moisture Evaluation
    MoistureStatus mStatus;
    String mMsg;
    if (reading.moisture < 35.0) {
      mStatus = MoistureStatus.dry;
      mMsg = 'ดินแห้ง (ความชื้นต่ำ ควรให้น้ำเพิ่ม)';
    } else if (reading.moisture <= 65.0) {
      mStatus = MoistureStatus.optimal;
      mMsg = 'ความชื้นเหมาะสมสำหรับการเจริญเติบโต';
    } else {
      mStatus = MoistureStatus.saturated;
      mMsg = 'ดินชุ่มน้ำมากเกินไป (เสี่ยงต่อรากเน่า)';
    }

    // 2. Salinity / EC Evaluation
    SalinityStatus sStatus;
    String sMsg;
    if (reading.conductivity < 300) {
      sStatus = SalinityStatus.nonSaline;
      sMsg = 'ความเค็มต่ำมาก ปริมาณเกลือแร่ธาตุน้อย';
    } else if (reading.conductivity <= 1200) {
      sStatus = SalinityStatus.optimal;
      sMsg = 'ระดับการนำไฟฟ้าเหมาะสม (Ideal Nutrient Conductivity)';
    } else if (reading.conductivity <= 2000) {
      sStatus = SalinityStatus.moderate;
      sMsg = 'เค็มปานกลาง ควรระวังการสะสมของปุ๋ยเคมี';
    } else {
      sStatus = SalinityStatus.highSalinity;
      sMsg = 'ดินเค็มจัด อาจเกิดภาวะรากไหม้จากการสะสมของเกลือ';
    }

    // 3. pH Evaluation
    PhStatus pStatus;
    String pMsg;
    if (reading.ph < 5.2) {
      pStatus = PhStatus.stronglyAcidic;
      pMsg = 'ดินกรดจัด แนะนำปรับสภาพด้วยปูนโดโลไมต์';
    } else if (reading.ph < 5.8) {
      pStatus = PhStatus.moderatelyAcidic;
      pMsg = 'ดินกรดเล็กน้อย พืชส่วนใหญ่ยังเจริญเติบโตได้';
    } else if (reading.ph <= 7.2) {
      pStatus = PhStatus.optimal;
      pMsg = 'ระดับ pH เป็นกลาง เหมาะสมที่สุดต่อการดูดซึมปุ๋ย';
    } else {
      pStatus = PhStatus.alkaline;
      pMsg = 'ดินด่าง ควรปรับสภาพด้วยยิปซัมหรืออินทรียวัตถุ';
    }

    // 4. NPK Balance
    final npk = 'N: ${reading.nitrogen} | P: ${reading.phosphorus} | K: ${reading.potassium} mg/kg';

    // 5. Synthesis Recommendation
    final rec = StringBuffer();
    if (reading.ph < 5.2) {
      rec.write('ปรับค่า pH ดินด้วยโดโลไมต์ 100-200 กก./ไร่. ');
    }
    if (reading.moisture < 35) {
      rec.write('ระบบน้ำควรรดเพิ่ม 15-20 นาที. ');
    }
    if (reading.nitrogen < 80) {
      rec.write('ควรเสริมปุ๋ยไนโตรเจนเพื่อส่งเสริมการแตกใบ. ');
    } else if (reading.conductivity > 1500) {
      rec.write('ควรงดให้ปุ๋ยเคมีชั่วคราวเพื่อลดความเค็มสะสม. ');
    } else {
      rec.write('สภาพดินโดยรวมอุดมสมบูรณ์พร้อมเพาะปลูก.');
    }

    return AgronomicAssessment(
      moistureStatus: mStatus,
      moistureMessage: mMsg,
      salinityStatus: sStatus,
      salinityMessage: sMsg,
      phStatus: pStatus,
      phMessage: pMsg,
      npkSummary: npk,
      recommendation: rec.toString().trim(),
    );
  }
}
