enum SoilTexture {
  sandy('ดินทราย (Sandy Soil)', 0.65),
  loamy('ดินร่วน (Loam Soil)', 1.00),
  clay('ดินเหนียว (Clay Soil)', 1.45);

  final String label;
  final double bufferFactor;
  const SoilTexture(this.label, this.bufferFactor);
}

/// Scientific Soil Amendment / Lime Prescription
class LimePrescription {
  final double currentPh;
  final double targetPh;
  final SoilTexture texture;
  final double dolomiteKgPerRai;
  final double agriculturalLimeKgPerRai;
  final double gypsumKgPerRai;
  final String applicationGuideline;
  final bool isAdjustmentNeeded;

  const LimePrescription({
    required this.currentPh,
    required this.targetPh,
    required this.texture,
    required this.dolomiteKgPerRai,
    required this.agriculturalLimeKgPerRai,
    required this.gypsumKgPerRai,
    required this.applicationGuideline,
    required this.isAdjustmentNeeded,
  });

  factory LimePrescription.calculate({
    required double currentPh,
    double targetPh = 6.50,
    SoilTexture texture = SoilTexture.loamy,
  }) {
    if (currentPh >= 6.2 && currentPh <= 7.3) {
      return LimePrescription(
        currentPh: currentPh,
        targetPh: targetPh,
        texture: texture,
        dolomiteKgPerRai: 0,
        agriculturalLimeKgPerRai: 0,
        gypsumKgPerRai: 0,
        applicationGuideline: 'ดินมีระดับกรด-ด่างที่สมดุลดีเลิศ (Optimal pH) ไม่จำเป็นต้องใส่ปูนปรับสภาพ แนะนำรักษาอินทรียวัตถุด้วยปุ๋ยหมัก 500-1,000 กก./ไร่',
        isAdjustmentNeeded: false,
      );
    }

    if (currentPh < 6.2) {
      // Acidic Soil -> Lime/Dolomite Calculation (LDD Standard)
      final double deltaPh = (targetPh - currentPh).clamp(0.0, 3.5);
      // Base rate: approx 150 kg Dolomite per rai for 0.5 pH raise in loam soil
      final double baseDolomite = deltaPh * 320.0 * texture.bufferFactor;
      final double baseAgLime = deltaPh * 280.0 * texture.bufferFactor;

      final guideline = StringBuffer();
      guideline.writeln('คำแนะนำการแก้ดินกรด (Acid Soil Remediation)');
      guideline.writeln('1. แนะนำใช้ ปูนโดโลไมต์ เพื่อเสริมทั้งแคลเซียม (Ca) และแมกนีเซียม (Mg)');
      guideline.writeln('2. หว่านให้ทั่วแปลงและไถพรวนคลุกเคล้ากับดินลึก 15-20 ซม.');
      guideline.writeln('3. รดน้ำให้ดินมีความชื้นพอเหมาะและทิ้งไว้ 10-14 วัน ก่อนปลูกพืชหรือใส่ปุ๋ยเคมี');
      if (baseDolomite > 500) {
        guideline.writeln('4. ปริมาณปูนสูง (>500 กก./ไร่) ควรแบ่งใส่ 2 รอบ ห่างกัน 1-2 เดือนเพื่อป้องกัน Shock');
      }

      return LimePrescription(
        currentPh: currentPh,
        targetPh: targetPh,
        texture: texture,
        dolomiteKgPerRai: double.parse(baseDolomite.toStringAsFixed(0)),
        agriculturalLimeKgPerRai: double.parse(baseAgLime.toStringAsFixed(0)),
        gypsumKgPerRai: 0,
        applicationGuideline: guideline.toString(),
        isAdjustmentNeeded: true,
      );
    } else {
      // Alkaline Soil (> 7.3) -> Gypsum / Elemental Sulfur
      final double deltaPh = (currentPh - 7.0).clamp(0.0, 3.0);
      final double gypsumRate = deltaPh * 220.0 * texture.bufferFactor;

      final guideline = StringBuffer();
      guideline.writeln('คำแนะนำการลดความกระด้างหรือด่างของดิน (Alkaline Remediation)');
      guideline.writeln('1. แนะนำใช้ ยิปซัมเกษตร (Calcium Sulfate) หรือกำมะถันผง');
      guideline.writeln('2. หลีกเลี่ยงการใช้ปุ๋ยที่มีโซเดียมสูง เสริมปุ๋ยอินทรีย์หมักมูลสัตว์เพื่อเพิ่มกรดฮิวมิก');
      guideline.writeln('3. ให้น้ำชะล้างเกลือโซเดียมออกทางร่องระบายน้ำ');

      return LimePrescription(
        currentPh: currentPh,
        targetPh: targetPh,
        texture: texture,
        dolomiteKgPerRai: 0,
        agriculturalLimeKgPerRai: 0,
        gypsumKgPerRai: double.parse(gypsumRate.toStringAsFixed(0)),
        applicationGuideline: guideline.toString(),
        isAdjustmentNeeded: true,
      );
    }
  }
}
