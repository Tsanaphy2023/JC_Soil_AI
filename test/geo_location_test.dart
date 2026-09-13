import 'package:flutter_test/flutter_test.dart';
import 'package:soil_app/data/models/geo_location_data.dart';
import 'package:soil_app/data/models/soil_reading.dart';

void main() {
  group('GeoLocationData Tests', () {
    test('defaultFallback provides valid research plot coordinates', () {
      final loc = GeoLocationData.defaultFallback();
      expect(loc.latitude, closeTo(12.6083, 0.001));
      expect(loc.longitude, closeTo(102.1154, 0.001));
      expect(loc.altitude, closeTo(42.5, 0.1));
      expect(loc.isFallback, isTrue);
      expect(loc.formattedLat, contains('12.60830° N'));
      expect(loc.formattedLon, contains('102.11540° E'));
      expect(loc.formattedAltitude, equals('42.5 m'));
      expect(loc.summary, contains('Alt: 42.5 m'));
    });

    test('toJson and fromJson serialize and deserialize correctly', () {
      final original = GeoLocationData(
        latitude: 13.7563,
        longitude: 100.5018,
        altitude: 15.2,
        accuracy: 3.5,
        timestamp: DateTime(2026, 9, 13, 11, 45),
        isFallback: false,
      );

      final json = original.toJson();
      final restored = GeoLocationData.fromJson(json);

      expect(restored.latitude, equals(original.latitude));
      expect(restored.longitude, equals(original.longitude));
      expect(restored.altitude, equals(original.altitude));
      expect(restored.accuracy, equals(original.accuracy));
      expect(restored.isFallback, isFalse);
    });

    test('SoilReading includes GPS metadata in CSV row', () {
      final loc = GeoLocationData(
        latitude: 12.608321,
        longitude: 102.115432,
        altitude: 43.1,
        timestamp: DateTime.now(),
      );

      final reading = SoilReading.mock(
        temp: 28.5,
        moist: 55.0,
        ec: 500,
        phVal: 6.5,
      ).copyWith(location: loc);

      expect(reading.latitude, equals(12.608321));
      expect(reading.longitude, equals(102.115432));
      expect(reading.altitude, equals(43.1));

      final csvRow = reading.toCsvRow();
      expect(SoilReading.csvHeaders, contains('Latitude'));
      expect(SoilReading.csvHeaders, contains('Longitude'));
      expect(SoilReading.csvHeaders, contains('Altitude (m)'));
      expect(csvRow[9], equals('12.608321'));
      expect(csvRow[10], equals('102.115432'));
      expect(csvRow[11], equals('43.1'));
    });
  });
}
