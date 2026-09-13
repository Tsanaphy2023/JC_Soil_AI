import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:soil_app/data/models/soil_dataset_item.dart';
import 'package:soil_app/data/services/soil_report_service.dart';

void main() {
  late Directory tempDir;
  late SoilReportService reportService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('soil_report_test_');
    reportService = SoilReportService(
      dataDirProvider: () async {
        final dir = Directory('${tempDir.path}/data');
        if (!await dir.exists()) await dir.create(recursive: true);
        return dir;
      },
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SoilReportService Tests', () {
    final sampleItem = SoilDatasetItem(
      sampleId: 'SAMPLE_TEST_001',
      timestamp: DateTime(2026, 9, 13, 10, 0, 0),
      mediaType: 'image',
      filePath: '/dummy/soil.jpg',
      fileName: 'soil.jpg',
      latitude: 12.6083,
      longitude: 102.1154,
      altitude: 45.0,
      temperature: 28.5,
      moisture: 42.0,
      conductivity: 650,
      ph: 6.2,
      nitrogen: 35,
      phosphorus: 25,
      potassium: 50,
      fertility: 180,
    );

    test('generates A4 Soil Health Certificate HTML with correct parameters and recommendations', () async {
      final certFile = await reportService.generateSoilCertificate(sampleItem);

      expect(await certFile.exists(), isTrue);
      final html = await certFile.readAsString();

      expect(html, contains('JC SOIL AI ANALYZER | SciRBRU AgriPhysics'));
      expect(html, contains('SAMPLE_TEST_001'));
      expect(html, contains('12.608300'));
      expect(html, contains('102.115400'));
      expect(html, contains('6.20')); // pH
      expect(html, contains('42.0 %')); // Moisture
      expect(html, contains('650 µS/cm')); // EC
      expect(html, contains('SOIL HEALTH SCORE'));
      expect(html, contains('ใบสั่งสูตรปุ๋ยเฉพาะแปลง'));
    });

    test('exports GeoJSON FeatureCollection correctly with coordinates and metadata', () async {
      final items = [sampleItem];
      final geoJsonFile = await reportService.exportGeoJson(items);

      expect(await geoJsonFile.exists(), isTrue);
      final content = await geoJsonFile.readAsString();
      final data = jsonDecode(content);

      expect(data['type'], 'FeatureCollection');
      expect(data['features'], isNotEmpty);
      final feature = data['features'][0];
      expect(feature['type'], 'Feature');
      expect(feature['geometry']['type'], 'Point');
      expect(feature['geometry']['coordinates'][0], 102.1154); // Longitude first in GeoJSON
      expect(feature['geometry']['coordinates'][1], 12.6083); // Latitude second
      expect(feature['properties']['sampleId'], 'SAMPLE_TEST_001');
      expect(feature['properties']['ph'], 6.2);
    });

    test('exports KML Document correctly for Google Earth', () async {
      final items = [sampleItem];
      final kmlFile = await reportService.exportKml(items);

      expect(await kmlFile.exists(), isTrue);
      final content = await kmlFile.readAsString();

      expect(content, contains('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(content, contains('<kml xmlns="http://www.opengis.net/kml/2.2">'));
      expect(content, contains('<name>SAMPLE_TEST_001</name>'));
      expect(content, contains('<coordinates>102.1154,12.6083,45.0</coordinates>'));
      expect(content, contains('JC SOIL AI SURVEY POINT'));
    });
  });
}
