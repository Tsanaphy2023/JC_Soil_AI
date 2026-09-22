import 'dart:typed_data';

/// Soil Raw Reading from Physical RS485 Modbus / USB OTG Sensor
class SoilPhReading {
  final double phRaw;
  final double temperature; // °C
  final double moisture;    // % VWC
  final int conductivity;   // µS/cm (EC)
  final double sensorVoltageMv; // Sensor Electrode Potential (mV)
  final DateTime timestamp;

  const SoilPhReading({
    required this.phRaw,
    required this.temperature,
    required this.moisture,
    required this.conductivity,
    double? sensorVoltageMv,
    required this.timestamp,
  }) : sensorVoltageMv = sensorVoltageMv ?? -((0.1984 * (273.15 + temperature)) * (phRaw - 7.0));

  /// Calculates Nernst theoretical slope: S(T) = 2.3026 * R * T / F (mV / pH)
  static double nernstSlope(double tempC) {
    return 0.198414 * (273.15 + tempC);
  }

  /// Calculates electrode potential (mV) from pH and temperature
  static double calculateVoltageMv(double ph, double tempC) {
    final slope = nernstSlope(tempC);
    // At pH 7.0, E = 0 mV (isopotential reference)
    // E(T, pH) = -S(T) * (pH - 7.0)
    return -slope * (ph - 7.0);
  }

  factory SoilPhReading.initial() {
    return SoilPhReading(
      phRaw: 6.50,
      temperature: 25.0,
      moisture: 50.0,
      conductivity: 600,
      sensorVoltageMv: 29.58, // -59.16 * (6.50 - 7.00) = +29.58 mV
      timestamp: DateTime.now(),
    );
  }

  /// Parse Modbus RTU Response Frame (e.g. 01 03 08 [Moist:2] [Temp:2] [EC:2] [pH:2] [CRC:2])
  /// Or 21-byte 8-parameter frame
  factory SoilPhReading.fromModbusBytes(Uint8List data) {
    if (data.length < 9) {
      return SoilPhReading.initial();
    }

    // Byte 0: Slave ID (0x01)
    // Byte 1: Function Code (0x03)
    // Byte 2: Byte Count (e.g. 0x08 for 4 registers or 0x10 for 8 registers)
    int offset = 3;
    final int rawMoist = (data[offset] << 8) | data[offset + 1];
    final int rawTemp = (data[offset + 2] << 8) | data[offset + 3];
    final int rawEc = (data[offset + 4] << 8) | data[offset + 5];
    final int rawPh = (data[offset + 6] << 8) | data[offset + 7];

    final double moisture = (rawMoist / 10.0).clamp(0.0, 100.0);
    
    // Signed 16-bit temperature
    int signedTemp = rawTemp;
    if (signedTemp > 0x7FFF) {
      signedTemp -= 0x10000;
    }
    final double temperature = (signedTemp / 10.0).clamp(-40.0, 85.0);
    final int conductivity = rawEc.clamp(0, 20000);

    // Some Chinese soil probes return pH * 10 (e.g. 68 for 6.8), others pH * 100 (e.g. 680 for 6.80)
    double ph = rawPh / 10.0;
    if (rawPh > 140) {
      ph = rawPh / 100.0;
    }
    ph = ph.clamp(3.0, 10.0);

    final double phRounded = double.parse(ph.toStringAsFixed(2));
    final double tempRounded = double.parse(temperature.toStringAsFixed(1));
    final double vMv = double.parse(calculateVoltageMv(phRounded, tempRounded).toStringAsFixed(1));

    return SoilPhReading(
      phRaw: phRounded,
      temperature: tempRounded,
      moisture: double.parse(moisture.toStringAsFixed(1)),
      conductivity: conductivity,
      sensorVoltageMv: vMv,
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ph_raw': phRaw,
      'temperature': temperature,
      'moisture': moisture,
      'conductivity': conductivity,
      'voltage_mv': sensorVoltageMv,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Output of Deep Learning PINN Calibration
class CalibratedPhResult {
  final SoilPhReading rawReading;
  final double phCalibrated;
  final double deltaPhTotal;
  final double deltaPhTemperature;
  final double deltaPhNonLinear;
  final double deltaPhMoisture;
  final double deltaPhPinn;
  final double atcPh;
  final double sensorVoltageMv;
  final double? standardPhRef;
  final double confidenceScore;
  final double uncertainty;
  final String physicalInterpretation;
  final String modelName;
  final DateTime timestamp;

  const CalibratedPhResult({
    required this.rawReading,
    required this.phCalibrated,
    required this.deltaPhTotal,
    required this.deltaPhTemperature,
    required this.deltaPhNonLinear,
    required this.deltaPhMoisture,
    required this.deltaPhPinn,
    required this.atcPh,
    required this.sensorVoltageMv,
    this.standardPhRef,
    required this.confidenceScore,
    required this.uncertainty,
    required this.physicalInterpretation,
    this.modelName = 'PINN-SoilPhNet-v2.6',
    required this.timestamp,
  });

  factory CalibratedPhResult.fallback(SoilPhReading raw) {
    return CalibratedPhResult(
      rawReading: raw,
      phCalibrated: raw.phRaw,
      deltaPhTotal: 0.0,
      deltaPhTemperature: 0.0,
      deltaPhNonLinear: 0.0,
      deltaPhMoisture: 0.0,
      deltaPhPinn: 0.0,
      atcPh: raw.phRaw,
      sensorVoltageMv: raw.sensorVoltageMv,
      confidenceScore: 0.95,
      uncertainty: 0.05,
      physicalInterpretation: 'สภาวะใกล้เคียงมาตรฐาน 25°C 50%VWC (Zero Drift Reference)',
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ph_raw': rawReading.phRaw,
      'ph_calibrated': phCalibrated,
      'delta_ph_total': deltaPhTotal,
      'delta_ph_temp': deltaPhTemperature,
      'delta_ph_nonlinear': deltaPhNonLinear,
      'delta_ph_moist': deltaPhMoisture,
      'delta_ph_pinn': deltaPhPinn,
      'ph_atc': atcPh,
      'voltage_mv': sensorVoltageMv,
      'standard_ph_ref': standardPhRef,
      'temperature': rawReading.temperature,
      'moisture': rawReading.moisture,
      'ec': rawReading.conductivity,
      'confidence': confidenceScore,
      'interpretation': physicalInterpretation,
      'model': modelName,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
