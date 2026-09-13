import 'package:flutter_test/flutter_test.dart';
import 'package:soil_app/data/models/soil_dataset_item.dart';
import 'package:soil_app/data/services/soil_gis_contour_service.dart';
import 'package:soil_app/data/services/soil_tile_service.dart';

void main() {
  group('SoilGisContourService Geostatistics Tests', () {
    test('generateContour handles empty items gracefully', () {
      final res = SoilGisContourService.generateContour(
        items: [],
        minLat: 12.0,
        maxLat: 12.1,
        minLng: 102.0,
        maxLng: 102.1,
        valueExtractor: (it) => it.ph,
      );

      expect(res.grid.isEmpty, isTrue);
      expect(res.segments.isEmpty, isTrue);
    });

    test('generateContour computes smooth IDW matrix and contour lines for field samples', () {
      final items = [
        SoilDatasetItem(
          sampleId: 'SOIL_001',
          filePath: '/test/p1.jpg',
          fileName: 'p1.jpg',
          mediaType: 'photo',
          timestamp: DateTime.now(),
          latitude: 12.6500,
          longitude: 102.1100,
          altitude: 45.0,
          temperature: 28.5,
          moisture: 35.0,
          conductivity: 450,
          ph: 5.2,
          nitrogen: 25,
          phosphorus: 15,
          potassium: 40,
          fertility: 1,
        ),
        SoilDatasetItem(
          sampleId: 'SOIL_002',
          filePath: '/test/p2.jpg',
          fileName: 'p2.jpg',
          mediaType: 'photo',
          timestamp: DateTime.now(),
          latitude: 12.6550,
          longitude: 102.1150,
          altitude: 46.0,
          temperature: 29.0,
          moisture: 55.0,
          conductivity: 820,
          ph: 6.8,
          nitrogen: 45,
          phosphorus: 25,
          potassium: 60,
          fertility: 2,
        ),
        SoilDatasetItem(
          sampleId: 'SOIL_003',
          filePath: '/test/p3.jpg',
          fileName: 'p3.jpg',
          mediaType: 'photo',
          timestamp: DateTime.now(),
          latitude: 12.6520,
          longitude: 102.1180,
          altitude: 45.5,
          temperature: 28.8,
          moisture: 42.0,
          conductivity: 610,
          ph: 6.0,
          nitrogen: 35,
          phosphorus: 20,
          potassium: 50,
          fertility: 2,
        ),
      ];

      final res = SoilGisContourService.generateContour(
        items: items,
        minLat: 12.6480,
        maxLat: 12.6580,
        minLng: 102.1080,
        maxLng: 102.1200,
        valueExtractor: (it) => it.ph,
        resolution: 20,
        contourCount: 4,
      );

      expect(res.grid.length, equals(20));
      expect(res.grid[0].length, equals(20));
      expect(res.levels.length, equals(4));
      expect(res.minVal, lessThanOrEqualTo(5.2));
      expect(res.maxVal, greaterThanOrEqualTo(6.8));
      // Each cell in IDW grid must be bounded by minVal and maxVal
      for (final row in res.grid) {
        for (final val in row) {
          expect(val, greaterThanOrEqualTo(res.minVal - 0.01));
          expect(val, lessThanOrEqualTo(res.maxVal + 0.01));
        }
      }
      expect(res.segments.isNotEmpty, isTrue);
    });
  });

  group('SoilTileService Slippy Map Tests', () {
    test('converts Lat/Lng to Web Mercator Tile coordinates correctly', () {
      const lat = 12.6500;
      const lon = 102.1100;
      const z = 16;

      final tileX = SoilTileService.lon2tileX(lon, z);
      final tileY = SoilTileService.lat2tileY(lat, z);

      expect(tileX, greaterThan(0));
      expect(tileY, greaterThan(0));

      final recoveredLon = SoilTileService.tileX2lon(tileX, z);
      final recoveredLat = SoilTileService.tileY2lat(tileY, z);

      expect((recoveredLon - lon).abs(), lessThan(0.02));
      expect((recoveredLat - lat).abs(), lessThan(0.02));
    });

    test('getOptimalZoom selects close zoom for agricultural plots', () {
      final zoomClose = SoilTileService.getOptimalZoom(12.6500, 12.6520, 102.1100, 102.1120);
      expect(zoomClose, greaterThanOrEqualTo(16));

      final zoomWide = SoilTileService.getOptimalZoom(12.0, 13.0, 101.0, 102.0);
      expect(zoomWide, lessThan(15));
    });

    test('getTileUrl returns valid Google Hybrid, Esri and OSM endpoints', () {
      final googleHybridUrl = SoilTileService.getTileUrl(BasemapType.googleHybrid, 16, 51350, 30340);
      expect(googleHybridUrl, contains('mt1.google.com/vt/lyrs=y&x=51350&y=30340&z=16'));

      final esriUrl = SoilTileService.getTileUrl(BasemapType.esriSatellite, 16, 51350, 30340);
      expect(esriUrl, contains('ArcGIS/rest/services/World_Imagery/MapServer/tile/16/30340/51350'));

      final streetUrl = SoilTileService.getTileUrl(BasemapType.street, 16, 51350, 30340);
      expect(streetUrl, contains('tile.openstreetmap.org/16/51350/30340.png'));
    });
  });
}
