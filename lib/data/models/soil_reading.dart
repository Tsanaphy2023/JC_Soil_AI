import 'package:intl/intl.dart';
import 'geo_location_data.dart';

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
  final GeoLocationData? location;

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
    this.location,
  });

  double? get latitude => location?.latitude;
  double? get longitude => location?.longitude;
  double? get altitude => location?.altitude;

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
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
    };
  }

  Map<String, dynamic> toJson() => toMap();

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
        'Latitude',
        'Longitude',
        'Altitude (m)',
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
        location != null ? location!.latitude.toStringAsFixed(6) : '-',
        location != null ? location!.longitude.toStringAsFixed(6) : '-',
        location != null ? location!.altitude.toStringAsFixed(1) : '-',
      ];

  SoilReading copyWith({
    double? temperature,
    double? moisture,
    int? conductivity,
    double? ph,
    int? nitrogen,
    int? phosphorus,
    int? potassium,
    int? fertility,
    DateTime? timestamp,
    GeoLocationData? location,
  }) {
    return SoilReading(
      temperature: temperature ?? this.temperature,
      moisture: moisture ?? this.moisture,
      conductivity: conductivity ?? this.conductivity,
      ph: ph ?? this.ph,
      nitrogen: nitrogen ?? this.nitrogen,
      phosphorus: phosphorus ?? this.phosphorus,
      potassium: potassium ?? this.potassium,
      fertility: fertility ?? this.fertility,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
    );
  }
}
