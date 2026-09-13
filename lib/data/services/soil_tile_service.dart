import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';

enum BasemapType {
  satellite,
  street,
  offlineGrid,
}

class MapTileInfo {
  final int x;
  final int y;
  final int z;
  final double minLng;
  final double maxLng;
  final double minLat;
  final double maxLat;

  const MapTileInfo({
    required this.x,
    required this.y,
    required this.z,
    required this.minLng,
    required this.maxLng,
    required this.minLat,
    required this.maxLat,
  });

  String get tileKey => '$z/$x/$y';
}

class SoilTileService {
  static final Map<String, ui.Image> _tileMemoryCache = {};
  static final Set<String> _loadingKeys = {};

  /// Convert Latitude, Longitude to Tile Coordinate X, Y at a given Zoom level
  static int lon2tileX(double lon, int z) {
    return ((lon + 180.0) / 360.0 * (1 << z)).floor();
  }

  static int lat2tileY(double lat, int z) {
    final latRad = lat * math.pi / 180.0;
    return ((1.0 - math.log(math.tan(latRad) + (1.0 / math.cos(latRad))) / math.pi) / 2.0 * (1 << z)).floor();
  }

  /// Tile to Longitude / Latitude bounds
  static double tileX2lon(int x, int z) {
    return x / (1 << z) * 360.0 - 180.0;
  }

  static double tileY2lat(int y, int z) {
    final n = math.pi - (2.0 * math.pi * y) / (1 << z);
    return 180.0 / math.pi * math.atan(0.5 * (math.exp(n) - math.exp(-n)));
  }

  /// Get tile info with exact geographic bounding box
  static MapTileInfo getTileInfo(int x, int y, int z) {
    final w = tileX2lon(x, z);
    final e = tileX2lon(x + 1, z);
    final n = tileY2lat(y, z);
    final s = tileY2lat(y + 1, z);
    return MapTileInfo(
      x: x,
      y: y,
      z: z,
      minLng: w,
      maxLng: e,
      minLat: s,
      maxLat: n,
    );
  }

  /// Get optimal Zoom level for plot bounding box
  static int getOptimalZoom(double minLat, double maxLat, double minLng, double maxLng) {
    final latDelta = (maxLat - minLat).abs();
    final lngDelta = (maxLng - minLng).abs();
    final maxDelta = math.max(latDelta, lngDelta);

    if (maxDelta > 2.0) return 8;
    if (maxDelta > 0.5) return 11;
    if (maxDelta > 0.1) return 13;
    if (maxDelta > 0.03) return 15;
    if (maxDelta > 0.008) return 16;
    if (maxDelta > 0.002) return 17;
    return 18; // Very close plot zoom (~150 meters)
  }

  /// Get URL for tile
  static String getTileUrl(BasemapType type, int z, int x, int y) {
    switch (type) {
      case BasemapType.satellite:
        // Esri ArcGIS World Imagery (Free high-resolution global satellite)
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/$z/$y/$x';
      case BasemapType.street:
        // OpenStreetMap Standard Tiles
        return 'https://tile.openstreetmap.org/$z/$x/$y.png';
      case BasemapType.offlineGrid:
        return '';
    }
  }

  /// Find all tiles intersecting the bounding box
  static List<MapTileInfo> getTilesForBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    int? overrideZoom,
  }) {
    final z = overrideZoom ?? getOptimalZoom(minLat, maxLat, minLng, maxLng);

    final minX = lon2tileX(minLng, z);
    final maxX = lon2tileX(maxLng, z);
    final minY = lat2tileY(maxLat, z);
    final maxY = lat2tileY(minLat, z);

    final tiles = <MapTileInfo>[];
    for (int x = minX; x <= maxX; x++) {
      for (int y = minY; y <= maxY; y++) {
        tiles.add(getTileInfo(x, y, z));
      }
    }
    return tiles;
  }

  /// Preload a tile into memory cache
  static void requestTile({
    required BasemapType type,
    required MapTileInfo tile,
    required VoidCallback onLoaded,
  }) {
    if (type == BasemapType.offlineGrid) return;
    final url = getTileUrl(type, tile.z, tile.x, tile.y);
    final cacheKey = '${type.name}_${tile.tileKey}';

    if (_tileMemoryCache.containsKey(cacheKey) || _loadingKeys.contains(cacheKey)) {
      return;
    }

    _loadingKeys.add(cacheKey);

    final imageProvider = NetworkImage(url, headers: const {
      'User-Agent': 'JC_Soil_AI_Precision_Agriphysics/1.0',
    });

    final stream = imageProvider.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        _tileMemoryCache[cacheKey] = info.image;
        _loadingKeys.remove(cacheKey);
        onLoaded();
        stream.removeListener(listener);
      },
      onError: (dynamic error, StackTrace? stackTrace) {
        _loadingKeys.remove(cacheKey);
        stream.removeListener(listener);
      },
    );

    stream.addListener(listener);
  }

  static ui.Image? getCachedTile(BasemapType type, MapTileInfo tile) {
    final cacheKey = '${type.name}_${tile.tileKey}';
    return _tileMemoryCache[cacheKey];
  }
}
