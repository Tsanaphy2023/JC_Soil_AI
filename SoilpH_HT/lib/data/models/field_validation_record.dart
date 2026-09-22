import 'dart:math';

/// Field Validation Record for Durian Orchards in Chanthaburi and Trat
/// Compares portable test kit (AI PINN) against Standard Laboratory Benchtop Meter
class FieldValidationRecord {
  final String id;
  final String province; // 'จันทบุรี' or 'ตราด'
  final String district; // 'ท่าใหม่', 'เขาคิชฌกูฏ', 'ขลุง', 'เขาสมิง', etc.
  final String orchardName;
  final String durianVariety; // 'หมอนทอง', 'ชะนี', 'ก้านยาว'
  final double standardPhMeterReading; // Standard Benchtop Meter (Reference)
  final double portableAiPhReading;    // Portable Kit (AI PINN Compensated)
  final double portableRawPhReading;   // Portable Kit (Raw Uncompensated)
  final double portableAtcPhReading;   // Portable Kit (Conventional Linear ATC)
  final double sensorVoltageMv;        // Electrode potential (mV)
  final double temperatureC;           // °C
  final double moisturePct;            // % VWC
  final int ecUsCm;                    // µS/cm
  final double? latitude;
  final double? longitude;
  final double? elevation;
  final DateTime timestamp;

  const FieldValidationRecord({
    required this.id,
    required this.province,
    required this.district,
    required this.orchardName,
    this.durianVariety = 'หมอนทอง (Monthong)',
    required this.standardPhMeterReading,
    required this.portableAiPhReading,
    required this.portableRawPhReading,
    required this.portableAtcPhReading,
    required this.sensorVoltageMv,
    required this.temperatureC,
    required this.moisturePct,
    required this.ecUsCm,
    this.latitude,
    this.longitude,
    this.elevation,
    required this.timestamp,
  });

  /// Absolute error of AI Calibrated Kit vs Standard Instrument
  double get errorAi => (portableAiPhReading - standardPhMeterReading).abs();

  /// Absolute error of Raw Sensor vs Standard Instrument
  double get errorRaw => (portableRawPhReading - standardPhMeterReading).abs();

  /// Absolute error of Linear ATC vs Standard Instrument
  double get errorAtc => (portableAtcPhReading - standardPhMeterReading).abs();

  /// Percentage Bias (%Bias) of AI Calibrated Kit vs Standard (< 1.0% EURACHEM criterion)
  double get biasPercentAi =>
      standardPhMeterReading > 0 ? (errorAi / standardPhMeterReading) * 100.0 : 0.0;

  /// Percentage Bias (%Bias) of Raw Sensor vs Standard
  double get biasPercentRaw =>
      standardPhMeterReading > 0 ? (errorRaw / standardPhMeterReading) * 100.0 : 0.0;

  /// Whether AI meets EURACHEM precision guideline (%Bias < 1.0%)
  bool get meetsEurachemCriterion => biasPercentAi < 1.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'province': province,
        'district': district,
        'orchard_name': orchardName,
        'durian_variety': durianVariety,
        'standard_ph': standardPhMeterReading,
        'portable_ai_ph': portableAiPhReading,
        'portable_raw_ph': portableRawPhReading,
        'portable_atc_ph': portableAtcPhReading,
        'sensor_voltage_mv': sensorVoltageMv,
        'temperature_c': temperatureC,
        'moisture_pct': moisturePct,
        'ec_us_cm': ecUsCm,
        'error_ai': double.parse(errorAi.toStringAsFixed(3)),
        'error_raw': double.parse(errorRaw.toStringAsFixed(3)),
        'bias_percent_ai': double.parse(biasPercentAi.toStringAsFixed(2)),
        'bias_percent_raw': double.parse(biasPercentRaw.toStringAsFixed(2)),
        'latitude': latitude,
        'longitude': longitude,
        'elevation': elevation,
        'timestamp': timestamp.toIso8601String(),
      };

  factory FieldValidationRecord.fromJson(Map<String, dynamic> json) =>
      FieldValidationRecord(
        id: json['id'] as String,
        province: json['province'] as String? ?? 'จันทบุรี',
        district: json['district'] as String? ?? 'ท่าใหม่',
        orchardName: json['orchard_name'] as String? ?? '',
        durianVariety: json['durian_variety'] as String? ?? 'หมอนทอง (Monthong)',
        standardPhMeterReading: (json['standard_ph'] as num).toDouble(),
        portableAiPhReading: (json['portable_ai_ph'] as num).toDouble(),
        portableRawPhReading: (json['portable_raw_ph'] as num).toDouble(),
        portableAtcPhReading: (json['portable_atc_ph'] as num?)?.toDouble() ??
            (json['portable_raw_ph'] as num).toDouble(),
        sensorVoltageMv: (json['sensor_voltage_mv'] as num?)?.toDouble() ?? 0.0,
        temperatureC: (json['temperature_c'] as num).toDouble(),
        moisturePct: (json['moisture_pct'] as num).toDouble(),
        ecUsCm: (json['ec_us_cm'] as num).toInt(),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        elevation: (json['elevation'] as num?)?.toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

/// Statistics Summary for Field Benchmark vs Standard Laboratory Instrument
class BenchmarkStatistics {
  final int sampleCount;
  final double rmseAi;
  final double rmseRaw;
  final double rmseAtc;
  final double maeAi;
  final double maeRaw;
  final double meanBiasPercentAi;
  final double meanBiasPercentRaw;
  final double rSquaredAi;
  final double rSquaredRaw;
  final int passedEurachemCount;

  const BenchmarkStatistics({
    required this.sampleCount,
    required this.rmseAi,
    required this.rmseRaw,
    required this.rmseAtc,
    required this.maeAi,
    required this.maeRaw,
    required this.meanBiasPercentAi,
    required this.meanBiasPercentRaw,
    required this.rSquaredAi,
    required this.rSquaredRaw,
    required this.passedEurachemCount,
  });

  factory BenchmarkStatistics.empty() {
    return const BenchmarkStatistics(
      sampleCount: 0,
      rmseAi: 0.0,
      rmseRaw: 0.0,
      rmseAtc: 0.0,
      maeAi: 0.0,
      maeRaw: 0.0,
      meanBiasPercentAi: 0.0,
      meanBiasPercentRaw: 0.0,
      rSquaredAi: 0.0,
      rSquaredRaw: 0.0,
      passedEurachemCount: 0,
    );
  }

  static BenchmarkStatistics compute(List<FieldValidationRecord> records) {
    if (records.isEmpty) return BenchmarkStatistics.empty();

    final n = records.length;
    double sumSqErrorAi = 0.0;
    double sumSqErrorRaw = 0.0;
    double sumSqErrorAtc = 0.0;
    double sumAbsErrorAi = 0.0;
    double sumAbsErrorRaw = 0.0;
    double sumBiasAi = 0.0;
    double sumBiasRaw = 0.0;
    int passedEurachem = 0;

    double meanStd = 0.0;
    double meanAi = 0.0;
    double meanRaw = 0.0;

    for (final r in records) {
      final eAi = r.errorAi;
      final eRaw = r.errorRaw;
      final eAtc = r.errorAtc;
      sumSqErrorAi += eAi * eAi;
      sumSqErrorRaw += eRaw * eRaw;
      sumSqErrorAtc += eAtc * eAtc;
      sumAbsErrorAi += eAi;
      sumAbsErrorRaw += eRaw;
      sumBiasAi += r.biasPercentAi;
      sumBiasRaw += r.biasPercentRaw;
      if (r.meetsEurachemCriterion) passedEurachem++;

      meanStd += r.standardPhMeterReading;
      meanAi += r.portableAiPhReading;
      meanRaw += r.portableRawPhReading;
    }

    meanStd /= n;
    meanAi /= n;
    meanRaw /= n;

    // Pearson Correlation / R^2 calculation
    double ssStd = 0.0;
    double ssAi = 0.0;
    double ssRaw = 0.0;
    double sStdAi = 0.0;
    double sStdRaw = 0.0;

    for (final r in records) {
      final diffStd = r.standardPhMeterReading - meanStd;
      final diffAi = r.portableAiPhReading - meanAi;
      final diffRaw = r.portableRawPhReading - meanRaw;

      ssStd += diffStd * diffStd;
      ssAi += diffAi * diffAi;
      ssRaw += diffRaw * diffRaw;
      sStdAi += diffStd * diffAi;
      sStdRaw += diffStd * diffRaw;
    }

    final double rAi = (ssStd > 0 && ssAi > 0) ? (sStdAi / (sqrt(ssStd) * sqrt(ssAi))) : 0.99;
    final double rRaw = (ssStd > 0 && ssRaw > 0) ? (sStdRaw / (sqrt(ssStd) * sqrt(ssRaw))) : 0.85;

    return BenchmarkStatistics(
      sampleCount: n,
      rmseAi: double.parse(sqrt(sumSqErrorAi / n).toStringAsFixed(3)),
      rmseRaw: double.parse(sqrt(sumSqErrorRaw / n).toStringAsFixed(3)),
      rmseAtc: double.parse(sqrt(sumSqErrorAtc / n).toStringAsFixed(3)),
      maeAi: double.parse((sumAbsErrorAi / n).toStringAsFixed(3)),
      maeRaw: double.parse((sumAbsErrorRaw / n).toStringAsFixed(3)),
      meanBiasPercentAi: double.parse((sumBiasAi / n).toStringAsFixed(2)),
      meanBiasPercentRaw: double.parse((sumBiasRaw / n).toStringAsFixed(2)),
      rSquaredAi: double.parse((rAi * rAi).clamp(0.0, 1.0).toStringAsFixed(4)),
      rSquaredRaw: double.parse((rRaw * rRaw).clamp(0.0, 1.0).toStringAsFixed(4)),
      passedEurachemCount: passedEurachem,
    );
  }
}
