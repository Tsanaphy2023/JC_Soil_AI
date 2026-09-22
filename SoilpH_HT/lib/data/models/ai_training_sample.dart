/// AI Training Sample Model for Objective 1:
/// Relationship between Sensor Potential (mV), Temperature (°C), and Standard Soil pH
class AiTrainingSample {
  final String sampleId;
  final String sampleType; // 'NIST บัฟเฟอร์ 4.01', 'NIST บัฟเฟอร์ 7.00', 'NIST บัฟเฟอร์ 10.01', 'ดินตัวอย่างแปลงทุเรียน'
  final double sensorVoltageMv; // E_sensor (mV)
  final double temperatureC;    // T (°C)
  final double standardPh;      // Ground Truth pH Reference
  final double rawPh;           // Uncalibrated probe pH
  final double moisturePct;     // % VWC
  final int ecUsCm;             // µS/cm
  final double nernstTheoreticalMv; // S(T) * (7.0 - pH_std)
  final double residualMv;      // Difference between actual and theoretical
  final DateTime timestamp;

  const AiTrainingSample({
    required this.sampleId,
    required this.sampleType,
    required this.sensorVoltageMv,
    required this.temperatureC,
    required this.standardPh,
    required this.rawPh,
    required this.moisturePct,
    required this.ecUsCm,
    required this.nernstTheoreticalMv,
    required this.residualMv,
    required this.timestamp,
  });

  /// Calculates NIST standard buffer pH at any given temperature (°C)
  static double calculateNistBufferPh(double nominalPh, double tempC) {
    if ((nominalPh - 4.01).abs() < 0.2) {
      // Potassium hydrogen phthalate pH(T) table polynomial
      if (tempC < 15.0) return 4.00;
      if (tempC <= 25.0) return 4.01;
      if (tempC <= 35.0) return 4.02;
      return 4.03;
    } else if ((nominalPh - 7.00).abs() < 0.2) {
      // Phosphate buffer pH(T)
      if (tempC < 15.0) return 7.04;
      if (tempC <= 20.0) return 7.02;
      if (tempC <= 25.0) return 7.00;
      if (tempC <= 30.0) return 6.99;
      if (tempC <= 35.0) return 6.98;
      return 6.97;
    } else if ((nominalPh - 10.01).abs() < 0.2) {
      // Carbonate buffer pH(T)
      if (tempC < 15.0) return 10.12;
      if (tempC <= 20.0) return 10.06;
      if (tempC <= 25.0) return 10.01;
      if (tempC <= 30.0) return 9.97;
      if (tempC <= 35.0) return 9.93;
      return 9.89;
    }
    return nominalPh;
  }

  Map<String, dynamic> toJson() => {
        'sample_id': sampleId,
        'sample_type': sampleType,
        'sensor_voltage_mv': double.parse(sensorVoltageMv.toStringAsFixed(2)),
        'temperature_c': double.parse(temperatureC.toStringAsFixed(1)),
        'standard_ph': double.parse(standardPh.toStringAsFixed(2)),
        'raw_ph': double.parse(rawPh.toStringAsFixed(2)),
        'moisture_pct': double.parse(moisturePct.toStringAsFixed(1)),
        'ec_us_cm': ecUsCm,
        'nernst_theoretical_mv': double.parse(nernstTheoreticalMv.toStringAsFixed(2)),
        'residual_mv': double.parse(residualMv.toStringAsFixed(2)),
        'timestamp': timestamp.toIso8601String(),
      };

  factory AiTrainingSample.fromJson(Map<String, dynamic> json) =>
      AiTrainingSample(
        sampleId: json['sample_id'] as String,
        sampleType: json['sample_type'] as String,
        sensorVoltageMv: (json['sensor_voltage_mv'] as num).toDouble(),
        temperatureC: (json['temperature_c'] as num).toDouble(),
        standardPh: (json['standard_ph'] as num).toDouble(),
        rawPh: (json['raw_ph'] as num).toDouble(),
        moisturePct: (json['moisture_pct'] as num).toDouble(),
        ecUsCm: (json['ec_us_cm'] as num).toInt(),
        nernstTheoreticalMv: (json['nernst_theoretical_mv'] as num).toDouble(),
        residualMv: (json['residual_mv'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
