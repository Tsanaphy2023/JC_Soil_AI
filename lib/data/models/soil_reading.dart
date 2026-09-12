import 'package:intl/intl.dart';

/// Clean immutable model representing a complete 8-parameter soil sensor measurement
class SoilReading {
  final double temperature;
  final double moisture;
  final int conductivity;
  final double ph;
  final int nitrogen;
  final int phosphorus;
  final int potassium;
  final int fertility;
  final DateTime timestamp;

  const SoilReading({
    required this.temperature,
    required this.moisture,
    required this.conductivity,
    required this.ph,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.fertility,
    required this.timestamp,
  });

  /// Initial placeholder or disconnected state
  factory SoilReading.initial() {
    return SoilReading(
      temperature: 0.0,
      moisture: 0.0,
      conductivity: 0,
      ph: 0.0,
      nitrogen: 0,
      phosphorus: 0,
      potassium: 0,
      fertility: 0,
      timestamp: DateTime.now(),
    );
  }

  /// Create a sample reading for demo / simulation testing
  factory SoilReading.mock({
    double? temp,
    double? moist,
    int? ec,
    double? phVal,
    int? n,
    int? p,
    int? k,
    int? fert,
  }) {
    return SoilReading(
      temperature: temp ?? 28.5,
      moisture: moist ?? 54.2,
      conductivity: ec ?? 480,
      ph: phVal ?? 6.4,
      nitrogen: n ?? 125,
      phosphorus: p ?? 38,
      potassium: k ?? 185,
      fertility: fert ?? 348,
      timestamp: DateTime.now(),
    );
  }

  String get formattedTimestamp =>
      DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);

  Map<String, dynamic> toMap() {
    return {
      'timestamp': formattedTimestamp,
      'temperature': temperature,
      'moisture': moisture,
      'conductivity': conductivity,
      'ph': ph,
      'nitrogen': nitrogen,
      'phosphorus': phosphorus,
      'potassium': potassium,
      'fertility': fertility,
    };
  }

  static List<String> get csvHeaders => [
        'Timestamp',
        'Temperature (°C)',
        'Moisture (%)',
        'Conductivity EC (µS/cm)',
        'pH',
        'Nitrogen N (mg/kg)',
        'Phosphorus P (mg/kg)',
        'Potassium K (mg/kg)',
        'Fertility (mg/kg)',
      ];

  List<dynamic> toCsvRow() => [
        formattedTimestamp,
        temperature.toStringAsFixed(1),
        moisture.toStringAsFixed(1),
        conductivity,
        ph.toStringAsFixed(2),
        nitrogen,
        phosphorus,
        potassium,
        fertility,
      ];
}
