import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/soil_dataset_item.dart';

class ContourSegment {
  final Offset start;
  final Offset end;
  final double level;

  const ContourSegment({
    required this.start,
    required this.end,
    required this.level,
  });
}

class LatLngContourSegment {
  final LatLng start;
  final LatLng end;
  final double level;

  const LatLngContourSegment({
    required this.start,
    required this.end,
    required this.level,
  });
}

class SoilContourResult {
  final List<List<double>> grid;
  final List<ContourSegment> segments;
  final List<LatLngContourSegment> geoSegments;
  final double minVal;
  final double maxVal;
  final List<double> levels;

  SoilContourResult({
    required this.grid,
    required this.segments,
    required this.geoSegments,
    required this.minVal,
    required this.maxVal,
    required this.levels,
  });
}

class SoilGisContourService {
  static const int defaultResolution = 36; // 36x36 grid for smooth 60fps interpolation

  /// Computes IDW (Inverse Distance Weighting) matrix and Marching Squares contour segments.
  static SoilContourResult generateContour({
    required List<SoilDatasetItem> items,
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    required double Function(SoilDatasetItem) valueExtractor,
    int resolution = defaultResolution,
    int contourCount = 5,
  }) {
    if (items.isEmpty) {
      return SoilContourResult(
        grid: [],
        segments: [],
        geoSegments: [],
        minVal: 0,
        maxVal: 0,
        levels: [],
      );
    }

    // 1. Extract values & compute min/max
    final values = items.map(valueExtractor).toList();
    double minVal = values.reduce(math.min);
    double maxVal = values.reduce(math.max);

    // If all values are identical or delta too small, expand slightly for contours
    if ((maxVal - minVal).abs() < 0.001) {
      minVal -= 0.5;
      maxVal += 0.5;
    }

    // 2. Generate Contour Levels
    final step = (maxVal - minVal) / (contourCount + 1);
    final levels = <double>[];
    for (int i = 1; i <= contourCount; i++) {
      levels.add(minVal + (i * step));
    }

    // 3. IDW Grid Calculation (Normalized 0.0 to 1.0 coordinates)
    final grid = List.generate(
      resolution,
      (_) => List<double>.filled(resolution, 0.0),
    );

    final lngDelta = maxLng - minLng;
    final latDelta = maxLat - minLat;

    // Precalculate item normalized coordinates
    final itemPoints = items.map((it) {
      final nx = lngDelta > 0 ? (it.longitude - minLng) / lngDelta : 0.5;
      final ny = latDelta > 0 ? 1.0 - ((it.latitude - minLat) / latDelta) : 0.5;
      return {'x': nx, 'y': ny, 'val': valueExtractor(it)};
    }).toList();

    const power = 2.0; // Standard IDW power
    const epsilon = 1e-6;

    for (int r = 0; r < resolution; r++) {
      final gy = r / (resolution - 1);
      for (int c = 0; c < resolution; c++) {
        final gx = c / (resolution - 1);

        double weightSum = 0.0;
        double weightedValSum = 0.0;
        bool exactMatch = false;

        for (final pt in itemPoints) {
          final dx = gx - pt['x']!;
          final dy = gy - pt['y']!;
          final distSq = (dx * dx) + (dy * dy);

          if (distSq < epsilon) {
            grid[r][c] = pt['val']!;
            exactMatch = true;
            break;
          }

          final w = 1.0 / math.pow(distSq, power / 2.0);
          weightSum += w;
          weightedValSum += w * pt['val']!;
        }

        if (!exactMatch) {
          grid[r][c] = weightSum > 0 ? (weightedValSum / weightSum) : minVal;
        }
      }
    }

    // 4. Marching Squares Algorithm to generate Contour Segments
    final segments = <ContourSegment>[];

    for (final lvl in levels) {
      for (int r = 0; r < resolution - 1; r++) {
        for (int c = 0; c < resolution - 1; c++) {
          final tl = grid[r][c];
          final tr = grid[r][c + 1];
          final br = grid[r + 1][c + 1];
          final bl = grid[r + 1][c];

          final cX0 = c / (resolution - 1);
          final cX1 = (c + 1) / (resolution - 1);
          final cY0 = r / (resolution - 1);
          final cY1 = (r + 1) / (resolution - 1);

          int squareCase = 0;
          if (tl >= lvl) squareCase |= 8;
          if (tr >= lvl) squareCase |= 4;
          if (br >= lvl) squareCase |= 2;
          if (bl >= lvl) squareCase |= 1;

          if (squareCase == 0 || squareCase == 15) continue;

          Offset interpTop() {
            final t = (tr - tl).abs() > epsilon ? (lvl - tl) / (tr - tl) : 0.5;
            return Offset(cX0 + t * (cX1 - cX0), cY0);
          }

          Offset interpRight() {
            final t = (br - tr).abs() > epsilon ? (lvl - tr) / (br - tr) : 0.5;
            return Offset(cX1, cY0 + t * (cY1 - cY0));
          }

          Offset interpBottom() {
            final t = (br - bl).abs() > epsilon ? (lvl - bl) / (br - bl) : 0.5;
            return Offset(cX0 + t * (cX1 - cX0), cY1);
          }

          Offset interpLeft() {
            final t = (bl - tl).abs() > epsilon ? (lvl - tl) / (bl - tl) : 0.5;
            return Offset(cX0, cY0 + t * (cY1 - cY0));
          }

          switch (squareCase) {
            case 1:
            case 14:
              segments.add(ContourSegment(start: interpLeft(), end: interpBottom(), level: lvl));
              break;
            case 2:
            case 13:
              segments.add(ContourSegment(start: interpBottom(), end: interpRight(), level: lvl));
              break;
            case 3:
            case 12:
              segments.add(ContourSegment(start: interpLeft(), end: interpRight(), level: lvl));
              break;
            case 4:
            case 11:
              segments.add(ContourSegment(start: interpTop(), end: interpRight(), level: lvl));
              break;
            case 5:
              segments.add(ContourSegment(start: interpLeft(), end: interpTop(), level: lvl));
              segments.add(ContourSegment(start: interpBottom(), end: interpRight(), level: lvl));
              break;
            case 6:
            case 9:
              segments.add(ContourSegment(start: interpTop(), end: interpBottom(), level: lvl));
              break;
            case 7:
            case 8:
              segments.add(ContourSegment(start: interpLeft(), end: interpTop(), level: lvl));
              break;
            case 10:
              segments.add(ContourSegment(start: interpTop(), end: interpRight(), level: lvl));
              segments.add(ContourSegment(start: interpLeft(), end: interpBottom(), level: lvl));
              break;
          }
        }
      }
    }

    // 5. Convert Normalized Segments to Real Geographic Coordinates (LatLng)
    final geoSegments = segments.map((seg) {
      final startLon = minLng + (seg.start.dx * lngDelta);
      final startLat = minLat + ((1.0 - seg.start.dy) * latDelta);
      final endLon = minLng + (seg.end.dx * lngDelta);
      final endLat = minLat + ((1.0 - seg.end.dy) * latDelta);

      return LatLngContourSegment(
        start: LatLng(startLat, startLon),
        end: LatLng(endLat, endLon),
        level: seg.level,
      );
    }).toList();

    return SoilContourResult(
      grid: grid,
      segments: segments,
      geoSegments: geoSegments,
      minVal: minVal,
      maxVal: maxVal,
      levels: levels,
    );
  }
}
