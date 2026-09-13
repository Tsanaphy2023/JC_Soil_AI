/// Agricultural GPS Geotagging Data Model
class GeoLocationData {
  final double latitude;
  final double longitude;
  final double altitude; // Altitude in meters above mean sea level (MSL)
  final double accuracy; // Position accuracy in meters
  final DateTime timestamp;
  final bool isFallback;

  const GeoLocationData({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    this.accuracy = 5.0,
    required this.timestamp,
    this.isFallback = false,
  });

  /// Chanthaburi Durian Experimental Research Plot baseline fallback
  factory GeoLocationData.defaultFallback() {
    return GeoLocationData(
      latitude: 12.6083,
      longitude: 102.1154,
      altitude: 42.5,
      accuracy: 10.0,
      timestamp: DateTime.now(),
      isFallback: true,
    );
  }

  /// Latitude in DMS or decimal string: e.g. "12.6083° N"
  String get formattedLat {
    final dir = latitude >= 0 ? 'N' : 'S';
    return '${latitude.abs().toStringAsFixed(5)}° $dir';
  }

  /// Longitude in decimal string: e.g. "102.1154° E"
  String get formattedLon {
    final dir = longitude >= 0 ? 'E' : 'W';
    return '${longitude.abs().toStringAsFixed(5)}° $dir';
  }

  /// Combined formatted coordinates: e.g. "12.6083° N, 102.1154° E"
  String get formattedCoordinates => '$formattedLat, $formattedLon';

  /// Formatted altitude: e.g. "42.5 m"
  String get formattedAltitude => '${altitude.toStringAsFixed(1)} m';

  /// Complete summary string: e.g. "12.6083° N, 102.1154° E | Alt: 42.5m"
  String get summary => '$formattedCoordinates | Alt: $formattedAltitude';

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'is_fallback': isFallback,
    };
  }

  factory GeoLocationData.fromJson(Map<String, dynamic> json) {
    return GeoLocationData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: (json['altitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 5.0,
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      isFallback: json['is_fallback'] as bool? ?? false,
    );
  }

  GeoLocationData copyWith({
    double? latitude,
    double? longitude,
    double? altitude,
    double? accuracy,
    DateTime? timestamp,
    bool? isFallback,
  }) {
    return GeoLocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      isFallback: isFallback ?? this.isFallback,
    );
  }
}
