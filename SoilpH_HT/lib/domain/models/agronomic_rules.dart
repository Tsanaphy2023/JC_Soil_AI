/// Bioavailability status for plant nutrients at a given soil pH
class NutrientAvailability {
  final String nameTh;
  final String nameEn;
  final String symbol;
  final double availabilityPercent; // 0 - 100%
  final String status;
  final String impactDetails;

  const NutrientAvailability({
    required this.nameTh,
    required this.nameEn,
    required this.symbol,
    required this.availabilityPercent,
    required this.status,
    required this.impactDetails,
  });
}

/// Comprehensive Agronomic Rules grounded in Soil Science & Chemistry
class AgronomicRules {
  AgronomicRules._();

  /// Calculate nutrient availability curves across pH 3.0 to 10.0
  static List<NutrientAvailability> evaluateNutrients(double ph) {
    return [
      _evaluateNitrogen(ph),
      _evaluatePhosphorus(ph),
      _evaluatePotassium(ph),
      _evaluateCalciumMagnesium(ph),
      _evaluateSulfur(ph),
      _evaluateIron(ph),
      _evaluateManganese(ph),
      _evaluateZincCopper(ph),
      _evaluateBoron(ph),
      _evaluateMolybdenum(ph),
    ];
  }

  static NutrientAvailability _evaluateNitrogen(double ph) {
    // Optimum 6.0 - 8.0, reduced in extreme acid due to nitrifying bacteria inhibition
    double pct = 100.0;
    if (ph < 6.0) pct = (50.0 + (ph - 3.0) * 16.0).clamp(20.0, 100.0);
    if (ph > 8.0) pct = (100.0 - (ph - 8.0) * 20.0).clamp(50.0, 100.0);
    return NutrientAvailability(
      nameTh: 'ไนโตรเจน',
      nameEn: 'Nitrogen',
      symbol: 'N',
      availabilityPercent: pct,
      status: pct >= 80 ? 'ดูดซึมได้ดีเยี่ยม' : 'ถูกตรึง/ชะลอการย่อยสลาย',
      impactDetails: ph < 5.5
          ? 'แบคทีเรียตรึงไนโตรเจนและ Nitrosomonas ทำงานลดลง ฮิวมัสย่อยสลายช้า'
          : 'การดูดซึมไนเตรตและแอมโมเนียมทำงานได้สมบูรณ์',
    );
  }

  static NutrientAvailability _evaluatePhosphorus(double ph) {
    // Strongly fixed by Fe/Al at pH < 5.5, and precipitated by Ca at pH > 7.5. Peak at 6.2 - 6.8
    double pct;
    if (ph < 6.5) {
      pct = (20.0 + (ph - 3.5) * 26.6).clamp(15.0, 100.0);
    } else {
      pct = (100.0 - (ph - 6.5) * 25.0).clamp(20.0, 100.0);
    }
    return NutrientAvailability(
      nameTh: 'ฟอสฟอรัส',
      nameEn: 'Phosphorus',
      symbol: 'P',
      availabilityPercent: pct,
      status: pct >= 75 ? 'ละลายน้ำดี ปลดปล่อยเต็มที่' : 'ถูกตรึงแน่น ไม่ละลาย',
      impactDetails: ph < 5.5
          ? 'ฟอสเฟตทำปฏิกิริยากับเหล็ก (Fe) และอะลูมิเนียม (Al) กลายเป็นสารไม่ละลายน้ำ'
          : ph > 7.5
              ? 'ฟอสเฟตทำปฏิกิริยากับแคลเซียม (Ca) กลายเป็น Tricalcium phosphate ไม่ละลาย'
              : 'ฟอสเฟตอิสระอยู่ในรูป H2PO4- ที่รากพืชดูดซึมได้เร็วที่สุด',
    );
  }

  static NutrientAvailability _evaluatePotassium(double ph) {
    double pct = 100.0;
    if (ph < 6.0) pct = (40.0 + (ph - 3.0) * 20.0).clamp(30.0, 100.0);
    return NutrientAvailability(
      nameTh: 'โพแทสเซียม',
      nameEn: 'Potassium',
      symbol: 'K',
      availabilityPercent: pct,
      status: pct >= 80 ? 'พร้อมใช้' : 'สูญเสียจากการชะล้าง',
      impactDetails: ph < 5.5
          ? 'ประจุบวก Al3+ และ H+ แย่งพื้นที่แลกเปลี่ยนบนอนุภาคดิน ทำให้ K+ ชะล้างง่าย'
          : 'ประจุโพแทสเซียมเกาะบนเม็ดดินได้สมดุลพร้อมปลดปล่อย',
    );
  }

  static NutrientAvailability _evaluateCalciumMagnesium(double ph) {
    double pct = 100.0;
    if (ph < 6.5) pct = (30.0 + (ph - 3.5) * 23.3).clamp(20.0, 100.0);
    return NutrientAvailability(
      nameTh: 'แคลเซียม & แมกนีเซียม',
      nameEn: 'Calcium & Magnesium',
      symbol: 'Ca & Mg',
      availabilityPercent: pct,
      status: pct >= 75 ? 'อุดมสมบูรณ์' : 'ขาดแคลนในดินกรด',
      impactDetails: ph < 5.5
          ? 'ดินกรดจัดขาดแคลน Ca/Mg อย่างรุนแรง ส่งผลให้เนื้อเยื่อพืชอ่อนแอ ก้นผลเน่า'
          : 'เสริมสร้างผนังเซลล์และคลอโรฟิลล์ได้อย่างมีประสิทธิภาพ',
    );
  }

  static NutrientAvailability _evaluateSulfur(double ph) {
    double pct = 100.0;
    if (ph < 6.0) pct = (60.0 + (ph - 3.0) * 13.3).clamp(40.0, 100.0);
    return NutrientAvailability(
      nameTh: 'กำมะถัน',
      nameEn: 'Sulfur',
      symbol: 'S',
      availabilityPercent: pct,
      status: pct >= 80 ? 'เพียงพอ' : 'ถูกตรึงปานกลาง',
      impactDetails: 'จำเป็นต่อการสร้างกรดอะมิโนและโปรตีนในพืช',
    );
  }

  static NutrientAvailability _evaluateIron(double ph) {
    // Readily available in acid, deficient in alkaline
    double pct;
    if (ph <= 6.0) {
      pct = 100.0;
    } else {
      pct = (100.0 - (ph - 6.0) * 28.0).clamp(10.0, 100.0);
    }
    return NutrientAvailability(
      nameTh: 'เหล็ก',
      nameEn: 'Iron',
      symbol: 'Fe',
      availabilityPercent: pct,
      status: pct >= 70 ? 'พร้อมใช้' : 'ตกตะกอน ขาดแคลน (ยอดเหลือง)',
      impactDetails: ph > 7.5
          ? 'เกิดอาการยอดเหลืองเส้นใบเขียว (Iron Chlorosis) จากการตกตะกอน Fe(OH)3'
          : 'ปลดปล่อยได้ดี (หาก pH < 4.5 อาจเกิดภาวะเป็นพิษต่อราก)',
    );
  }

  static NutrientAvailability _evaluateManganese(double ph) {
    double pct = ph <= 6.2 ? 100.0 : (100.0 - (ph - 6.2) * 26.0).clamp(15.0, 100.0);
    return NutrientAvailability(
      nameTh: 'แมงกานีส',
      nameEn: 'Manganese',
      symbol: 'Mn',
      availabilityPercent: pct,
      status: pct >= 70 ? 'พร้อมใช้' : 'ถูกตรึงในดินด่าง',
      impactDetails: ph < 4.8
          ? 'ระวัง! ความเข้มข้น Mn2+ สูงเกินไปอาจเป็นพิษต่อเนื้อเยื่อพืช'
          : 'ช่วยในกระบวนการสังเคราะห์แสงและกระตุ้นเอนไซม์',
    );
  }

  static NutrientAvailability _evaluateZincCopper(double ph) {
    double pct = ph <= 6.5 ? 95.0 : (95.0 - (ph - 6.5) * 25.0).clamp(15.0, 95.0);
    return NutrientAvailability(
      nameTh: 'สังกะสี & ทองแดง',
      nameEn: 'Zinc & Copper',
      symbol: 'Zn & Cu',
      availabilityPercent: pct,
      status: pct >= 70 ? 'สมบูรณ์' : 'ขาดแคลนในดินด่าง',
      impactDetails: ph > 7.2 ? 'พืชอาจมีอาการข้อปล้องสั้น แคระแกร็น' : 'พร้อมใช้สร้างฮอร์โมนออกซิน',
    );
  }

  static NutrientAvailability _evaluateBoron(double ph) {
    double pct = (ph >= 5.0 && ph <= 7.0) ? 95.0 : 60.0;
    return NutrientAvailability(
      nameTh: 'โบรอน',
      nameEn: 'Boron',
      symbol: 'B',
      availabilityPercent: pct,
      status: pct >= 80 ? 'ดูดซึมดี' : 'ชะล้างหรือถูกตรึง',
      impactDetails: 'ควบคุมการงอกของละอองเกสรและการติดผล',
    );
  }

  static NutrientAvailability _evaluateMolybdenum(double ph) {
    // Unique nutrient: availability increases with pH
    double pct = (ph < 6.0) ? (30.0 + (ph - 3.5) * 28.0).clamp(20.0, 100.0) : 100.0;
    return NutrientAvailability(
      nameTh: 'โมลิบดีนัม',
      nameEn: 'Molybdenum',
      symbol: 'Mo',
      availabilityPercent: pct,
      status: pct >= 80 ? 'เพียงพอ' : 'ขาดแคลนในดินกรด',
      impactDetails: ph < 5.5
          ? 'พืชตระกูลถั่วจะไม่สามารถสร้างปมตรึงไนโตรเจนได้เต็มที่'
          : 'จำเป็นต่อเอนไซม์ Nitrate Reductase',
    );
  }

  /// Check Aluminum & Heavy Metal Toxicity Alert
  static String? checkToxicityWarning(double ph) {
    if (ph < 4.5) {
      return '⚠️ คำเตือนวิกฤต: ดินมีสภาพกรดรุนแรงมาก เกิดการละลายตัวของไอออนอะลูมิเนียม (Al3+) และแมงกานีส (Mn2+) ซึ่งเป็นพิษต่อระบบรากพืชโดยตรง ทำให้รากุด ชะงักการเจริญเติบโต จำเป็นต้องหว่านปูนปรับปรุงดินด่วน';
    } else if (ph < 5.0) {
      return '⚠️ แจ้งเตือน: ดินเป็นกรดจัด เริ่มมีความเสี่ยงจากพิษอะลูมิเนียมและการตรึงฟอสฟอรัสอย่างรุนแรง ควรวางแผนใส่ปูนโดโลไมต์';
    } else if (ph > 8.5) {
      return '⚠️ แจ้งเตือน: ดินเป็นด่างจัด มักพบปัญหาขาดธาตุจุลธาตุเหล็กและสังกะสี และอาจเป็นดินเค็มโซดิก';
    }
    return null;
  }
}
