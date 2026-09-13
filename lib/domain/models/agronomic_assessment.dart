import 'package:flutter/material.dart';
import '../../data/models/soil_reading.dart';

enum MoistureStatus { dry, optimal, saturated }
enum SalinityStatus { nonSaline, optimal, moderate, highSalinity }
enum PhStatus { stronglyAcidic, moderatelyAcidic, optimal, alkaline }
enum AgronomicPriority { urgent, warning, optimal, info }

/// Itemized actionable agronomic recommendation based on LDD & FAO precision soil science
class AgronomicAdviceItem {
  final String category;
  final String title;
  final String detail;
  final String actionDose;
  final AgronomicPriority priority;
  final IconData icon;
  final Color color;

  const AgronomicAdviceItem({
    required this.category,
    required this.title,
    required this.detail,
    required this.actionDose,
    required this.priority,
    required this.icon,
    required this.color,
  });

  String get priorityLabel {
    switch (priority) {
      case AgronomicPriority.urgent:
        return 'ด่วนมาก';
      case AgronomicPriority.warning:
        return 'ควรปรับปรุง';
      case AgronomicPriority.optimal:
        return 'เหมาะสม';
      case AgronomicPriority.info:
        return 'คำแนะนำ';
    }
  }

  Color get priorityColor {
    switch (priority) {
      case AgronomicPriority.urgent:
        return const Color(0xFFE53935); // Crimson
      case AgronomicPriority.warning:
        return const Color(0xFFFFA000); // Amber
      case AgronomicPriority.optimal:
        return const Color(0xFF43A047); // Emerald
      case AgronomicPriority.info:
        return const Color(0xFF0288D1); // Cerulean
    }
  }
}

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

  // Enhanced Precision Recommendation fields
  final double healthScore; // 0 - 100
  final String healthStatusTitle;
  final Color healthStatusColor;
  final List<AgronomicAdviceItem> adviceList;

  const AgronomicAssessment({
    required this.moistureStatus,
    required this.moistureMessage,
    required this.salinityStatus,
    required this.salinityMessage,
    required this.phStatus,
    required this.phMessage,
    required this.npkSummary,
    required this.recommendation,
    this.healthScore = 50.0,
    this.healthStatusTitle = 'ปานกลาง (ควรปรับปรุง)',
    this.healthStatusColor = const Color(0xFFFFA000),
    this.adviceList = const [],
  });

  factory AgronomicAssessment.evaluate(SoilReading reading) {
    // 1. Moisture Evaluation
    MoistureStatus mStatus;
    String mMsg;
    double mScore = 0;
    if (reading.moisture < 35.0) {
      mStatus = MoistureStatus.dry;
      mMsg = 'ดินแห้ง (ความชื้นต่ำ ควรให้น้ำเพิ่ม)';
      mScore = (reading.moisture / 35.0 * 20.0).clamp(5.0, 20.0);
    } else if (reading.moisture <= 65.0) {
      mStatus = MoistureStatus.optimal;
      mMsg = 'ความชื้นเหมาะสมสำหรับการเจริญเติบโต';
      mScore = 25.0;
    } else {
      mStatus = MoistureStatus.saturated;
      mMsg = 'ดินชุ่มน้ำมากเกินไป (เสี่ยงต่อรากเน่า)';
      mScore = 15.0;
    }

    // 2. Salinity / EC Evaluation
    SalinityStatus sStatus;
    String sMsg;
    double sScore = 0;
    if (reading.conductivity < 300) {
      sStatus = SalinityStatus.nonSaline;
      sMsg = 'ความเค็มต่ำมาก ปริมาณเกลือแร่ธาตุน้อย';
      sScore = 18.0;
    } else if (reading.conductivity <= 1200) {
      sStatus = SalinityStatus.optimal;
      sMsg = 'ระดับการนำไฟฟ้าเหมาะสม (Ideal Nutrient Conductivity)';
      sScore = 25.0;
    } else if (reading.conductivity <= 2000) {
      sStatus = SalinityStatus.moderate;
      sMsg = 'เค็มปานกลาง ควรระวังการสะสมของปุ๋ยเคมี';
      sScore = 14.0;
    } else {
      sStatus = SalinityStatus.highSalinity;
      sMsg = 'ดินเค็มจัด อาจเกิดภาวะรากไหม้จากการสะสมของเกลือ';
      sScore = 5.0;
    }

    // 3. pH Evaluation
    PhStatus pStatus;
    String pMsg;
    double pScore = 0;
    if (reading.ph < 5.2) {
      pStatus = PhStatus.stronglyAcidic;
      pMsg = 'ดินกรดจัด แนะนำปรับสภาพด้วยปูนโดโลไมต์';
      pScore = 8.0;
    } else if (reading.ph < 5.8) {
      pStatus = PhStatus.moderatelyAcidic;
      pMsg = 'ดินกรดเล็กน้อย พืชส่วนใหญ่ยังเจริญเติบโตได้';
      pScore = 18.0;
    } else if (reading.ph <= 7.2) {
      pStatus = PhStatus.optimal;
      pMsg = 'ระดับ pH เป็นกลาง เหมาะสมที่สุดต่อการดูดซึมปุ๋ย';
      pScore = 25.0;
    } else {
      pStatus = PhStatus.alkaline;
      pMsg = 'ดินด่าง ควรปรับสภาพด้วยยิปซัมหรืออินทรียวัตถุ';
      pScore = 12.0;
    }

    // 4. NPK Balance & Scoring
    final double npkAvg = (reading.nitrogen + reading.phosphorus + reading.potassium) / 3.0;
    final double npkScore = (npkAvg / 100.0 * 25.0).clamp(5.0, 25.0);
    final npk = 'N: ${reading.nitrogen} | P: ${reading.phosphorus} | K: ${reading.potassium} mg/kg';

    // Total Health Score (0 - 100)
    final double totalScore = (mScore + sScore + pScore + npkScore).clamp(10.0, 100.0);
    String healthTitle;
    Color healthColor;
    if (totalScore >= 75) {
      healthTitle = 'ดินอุดมสมบูรณ์ดีเยี่ยม (Optimal Soil)';
      healthColor = const Color(0xFF43A047); // Green
    } else if (totalScore >= 50) {
      healthTitle = 'ดินปานกลาง (ควรปรับปรุงธาตุอาหาร)';
      healthColor = const Color(0xFFFFA000); // Amber
    } else {
      healthTitle = 'ดินวิกฤต (ต้องการการฟื้นฟูด่วน)';
      healthColor = const Color(0xFFE53935); // Red
    }

    // 5. Itemized Precision Recommendations
    final List<AgronomicAdviceItem> items = [];

    // 5.1 pH & Liming Recommendation
    if (reading.ph < 4.5) {
      items.add(
        const AgronomicAdviceItem(
          category: 'การปรับปรุงค่ากรด-ด่าง (Soil pH & Liming)',
          title: 'แก้ดินกรดรุนแรงด้วยปูนโดโลไมต์ 200-300 กก./ไร่',
          detail: 'ดินมีความเป็นกรดสูงมาก ธาตุเหล็กและอะลูมิเนียมละลายออกมาเป็นพิษต่อราก และตรึงฟอสฟอรัส ควรหว่านปูนโดโลไมต์หรือปูนมาร์ล แล้วไถพรวนคลุกเคล้าทิ้งไว้ 15-20 วันก่อนปลูกพืช',
          actionDose: 'โดโลไมต์ 200 - 300 กก./ไร่',
          priority: AgronomicPriority.urgent,
          icon: Icons.science,
          color: Color(0xFFE53935),
        ),
      );
    } else if (reading.ph < 5.5) {
      items.add(
        const AgronomicAdviceItem(
          category: 'การปรับปรุงค่ากรด-ด่าง (Soil pH & Liming)',
          title: 'ปรับสภาพดินกรดด้วยปูนโดโลไมต์ 100-150 กก./ไร่',
          detail: 'ดินกรดปานกลาง แนะนำใส่ปูนโดโลไมต์เพื่อเพิ่มค่า pH ให้เข้าสู่ช่วง 6.0-6.5 ซึ่งเป็นช่วงที่พืชดูดซึมปุ๋ยไนโตรเจนและฟอสฟอรัสได้ดีที่สุด',
          actionDose: 'โดโลไมต์ 100 - 150 กก./ไร่',
          priority: AgronomicPriority.warning,
          icon: Icons.science_outlined,
          color: Color(0xFFFFA000),
        ),
      );
    } else if (reading.ph > 7.5) {
      items.add(
        const AgronomicAdviceItem(
          category: 'การปรับปรุงค่ากรด-ด่าง (Soil pH & Liming)',
          title: 'ปรับลดความด่างด้วยยิปซัมการเกษตรหรือปุ๋ยหมักอินทรีย์',
          detail: 'ดินมีสภาพเป็นด่าง ธาตุสังกะสี เหล็ก และแมงกานีสละลายได้ยาก ควรใส่ยิปซัม 50-80 กก./ไร่ หรือเติมอินทรียวัตถุเพื่อสร้างกรดฮิวมิกช่วยปรับสมดุล',
          actionDose: 'ยิปซัมการเกษตร 50 - 80 กก./ไร่',
          priority: AgronomicPriority.warning,
          icon: Icons.science,
          color: Color(0xFF0288D1),
        ),
      );
    } else {
      items.add(
        const AgronomicAdviceItem(
          category: 'การปรับปรุงค่ากรด-ด่าง (Soil pH & Liming)',
          title: 'ระดับ pH เหมาะสมดีเยี่ยม (pH 5.5 - 7.5)',
          detail: 'ความเป็นกรด-ด่างอยู่ในเกณฑ์มาตรฐาน ดินมีความพร้อมในการปลดปล่อยธาตุอาหารให้พืชดูดซึมได้เต็มประสิทธิภาพ ไม่จำเป็นต้องใส่ปูนปรับสภาพ',
          actionDose: 'ไม่ต้องใส่สารปรับสภาพดิน',
          priority: AgronomicPriority.optimal,
          icon: Icons.check_circle_outline,
          color: Color(0xFF43A047),
        ),
      );
    }

    // 5.2 Water & Moisture Management
    if (reading.moisture < 35.0) {
      items.add(
        const AgronomicAdviceItem(
          category: 'การจัดการระบบน้ำ & ความชื้น (Irrigation)',
          title: 'ดินแห้งเสี่ยงพืชเหี่ยวเฉา ให้น้ำทันที 20-30 นาที',
          detail: 'ความชื้นในดินต่ำเกินไป ทำให้การดูดซึมสารละลายธาตุอาหารชะงัก แนะนำเปิดระบบน้ำสปริงเกลอร์หรือน้ำหยดช่วงเช้าตรู่ (06:00-08:00 น.) พร้อมคลุมโคนด้วยฟางหรือเศษหญ้าหนา 5-10 ซม.',
          actionDose: 'ให้น้ำหยด/สปริงเกลอร์ 20 - 30 นาที',
          priority: AgronomicPriority.urgent,
          icon: Icons.water_drop,
          color: Color(0xFF0288D1),
        ),
      );
    } else if (reading.moisture > 65.0) {
      items.add(
        const AgronomicAdviceItem(
          category: 'การจัดการระบบน้ำ & ความชื้น (Irrigation)',
          title: 'ดินชุ่มน้ำเกินไป ระวังรากเน่าและเชื้อราไฟทอปธอร่า',
          detail: 'ดินอุ้มน้ำมากเกินไปทำให้ช่องว่างในดินขาดออกซิเจน เสี่ยงต่อโรครากเน่าโคนเน่า ควรเปิดร่องระบายน้ำรอบแปลง และงดให้น้ำจนกว่าความชื้นจะลดลงสู่ระดับ 40-50%',
          actionDose: 'ชะลอการให้น้ำ + เปิดร่องระบายน้ำ',
          priority: AgronomicPriority.warning,
          icon: Icons.warning_amber_rounded,
          color: Color(0xFFFFA000),
        ),
      );
    } else {
      items.add(
        const AgronomicAdviceItem(
          category: 'การจัดการระบบน้ำ & ความชื้น (Irrigation)',
          title: 'ความชื้นดินสมดุลดีเยี่ยม (Moisture 35 - 65%)',
          detail: 'ระดับน้ำในดินพอเหมาะต่อการหายใจของรากและการแพร่ของสารละลายปุ๋ย ควรรักษารอบการให้น้ำตามปกติอย่างสม่ำเสมอ',
          actionDose: 'รักษารอบการให้น้ำตามโปรแกรมปกติ',
          priority: AgronomicPriority.optimal,
          icon: Icons.water_drop_outlined,
          color: Color(0xFF43A047),
        ),
      );
    }

    // 5.3 Precision NPK Fertilizer Prescription
    if (reading.nitrogen < 30 && reading.phosphorus < 15 && reading.potassium < 50) {
      items.add(
        const AgronomicAdviceItem(
          category: 'การให้ปุ๋ยธาตุอาหาร N-P-K (Fertilizer Prescription)',
          title: 'เสริมปุ๋ยสูตรเสมอ 15-15-15 หรือ 16-16-16 ด่วน',
          detail: 'ดินขาดธาตุอาหารหลักทุกตัวอย่างรุนแรง พืชจะชะงักการเจริญเติบโต ใบเหลือง แคระแกร็น แนะนำใส่ปุ๋ยเคมีสูตรเสมอ 25-30 กก./ไร่ ควบคู่ปุ๋ยคอกหมัก 300-500 กก./ไร่ เพื่อสร้างอินทรียวัตถุ',
          actionDose: 'สูตร 15-15-15 (25-30 กก./ไร่) + ปุ๋ยคอก 500 กก./ไร่',
          priority: AgronomicPriority.urgent,
          icon: Icons.grass,
          color: Color(0xFFE53935),
        ),
      );
    } else {
      // Individual NPK Advice
      final List<String> npkActions = [];
      if (reading.nitrogen < 30) {
        npkActions.add('เสริม 46-0-0 (ยูเรีย) หรือมูลไก่หมักเพื่อกระตุ้นใบ');
      }
      if (reading.phosphorus < 15) {
        npkActions.add('เสริม 18-46-0 (DAP) หรือหินฟอสเฟตเพื่อสร้างราก');
      }
      if (reading.potassium < 50) {
        npkActions.add('เสริม 0-0-60 เพื่อขยายผลและสร้างเนื้อแป้งน้ำตาล');
      }

      if (npkActions.isNotEmpty) {
        items.add(
          AgronomicAdviceItem(
            category: 'การให้ปุ๋ยธาตุอาหาร N-P-K (Fertilizer Prescription)',
            title: 'เติมธาตุอาหารหลักเฉพาะตัวที่ขาด (${npkActions.length} ธาตุ)',
            detail: 'วิเคราะห์รายธาตุ: ${npkActions.join(" | ")} แนะนำใส่ปุ๋ยตามระยะการเจริญเติบโตของพืชเพื่อความคุ้มค่าสูงสุด',
            actionDose: 'ปรับใส่ปุ๋ยเฉพาะส่วนที่ขาดตามคำแนะนำ',
            priority: AgronomicPriority.warning,
            icon: Icons.eco,
            color: const Color(0xFFFFA000),
          ),
        );
      } else {
        items.add(
          const AgronomicAdviceItem(
            category: 'การให้ปุ๋ยธาตุอาหาร N-P-K (Fertilizer Prescription)',
            title: 'ธาตุอาหาร N-P-K สมดุลพอดีสำหรับแปลงเพาะปลูก',
            detail: 'ปริมาณไนโตรเจน ฟอสฟอรัส และโพแทสเซียมในดินเพียงพอ ไม่จำเป็นต้องเร่งปุ๋ยเคมีเพิ่ม เพียงให้ปุ๋ยบำรุงตามรอบปกติ',
            actionDose: 'ให้ปุ๋ยบำรุงตามรอบปกติ',
            priority: AgronomicPriority.optimal,
            icon: Icons.check_circle_outline,
            color: Color(0xFF43A047),
          ),
        );
      }
    }

    // 5.4 EC / Salinity Management
    if (reading.conductivity > 1500) {
      items.add(
        const AgronomicAdviceItem(
          category: 'ความเค็ม & สุขภาพดิน (EC & Salinity)',
          title: 'งดปุ๋ยเคมีชั่วคราว + ให้น้ำสะอาดชะล้างเกลือสะสม',
          detail: 'ค่าความเค็ม EC สูงเกินเกณฑ์ เสี่ยงต่อภาวะรากไหม้และพืชขาดน้ำเทียม แนะนำหยุดใส่ปุ๋ยเคมีทุกชนิด รดน้ำชะล้างดินระบายออก 2-3 รอบเพื่อลดระดับเกลือ',
          actionDose: 'งดปุ๋ยเคมี + ชะล้างด้วยน้ำสะอาด',
          priority: AgronomicPriority.urgent,
          icon: Icons.flash_on,
          color: Color(0xFFE53935),
        ),
      );
    } else {
      items.add(
        const AgronomicAdviceItem(
          category: 'ความเค็ม & สุขภาพดิน (EC & Salinity)',
          title: 'ค่าการนำไฟฟ้า EC ปลอดภัย (เกลือแร่ธาตุไม่ตกค้าง)',
          detail: 'ระดับความเค็มในดินอยู่ในเกณฑ์ปกติ ไม่พบการสะสมของเกลือเคมีตกค้าง พืชสามารถดูดซึมน้ำและสารละลายแร่ธาตุได้อย่างอิสระ',
          actionDose: 'ระดับเกลือปลอดภัย เหมาะสม',
          priority: AgronomicPriority.optimal,
          icon: Icons.bolt,
          color: Color(0xFF43A047),
        ),
      );
    }

    // 5.5 Soil Microbiome & Organic Soil Regeneration
    items.add(
      const AgronomicAdviceItem(
        category: 'การฟื้นฟูชีวภาพ & จุลินทรีย์ดิน (Soil Microbiome)',
        title: 'เติมเชื้อราไตรโคเดอร์มา + ปุ๋ยหมักชีวภาพคลุมดิน',
        detail: 'เสริมจุลินทรีย์ปฏิปักษ์ไตรโคเดอร์มาเพื่อป้องกันเชื้อราโรครากเน่าโคนเน่า และเติมน้ำหมักชีวภาพช่วยย่อยสลายตรึงธาตุอาหาร ทำให้โครงสร้างดินโปร่งร่วนซุย',
        actionDose: 'ไตรโคเดอร์มา 1 กก. ผสมปุ๋ยหมัก 100 กก. หว่านรอบโคน',
        priority: AgronomicPriority.info,
        icon: Icons.coronavirus_outlined,
        color: Color(0xFF00B0FF),
      ),
    );

    // 6. Synthesis Summary String
    final rec = StringBuffer();
    if (reading.ph < 5.2) {
      rec.write('ปรับค่า pH ดินด้วยโดโลไมต์ 150-250 กก./ไร่. ');
    }
    if (reading.moisture < 35) {
      rec.write('ระบบน้ำควรรดเพิ่ม 20-30 นาที พร้อมคลุมโคน. ');
    }
    if (reading.nitrogen < 30) {
      rec.write('ควรเสริมปุ๋ยสูตรเสมอหรือไนโตรเจนเพื่อส่งเสริมการแตกใบ. ');
    } else if (reading.conductivity > 1500) {
      rec.write('ควรงดให้ปุ๋ยเคมีชั่วคราวเพื่อลดความเค็มสะสม. ');
    } else {
      rec.write('สภาพดินโดยรวมมีความพร้อมสำหรับการเพาะปลูก.');
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
      healthScore: totalScore,
      healthStatusTitle: healthTitle,
      healthStatusColor: healthColor,
      adviceList: items,
    );
  }
}

