import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/localization/language_provider.dart';
import '../../data/models/soil_dataset_item.dart';
import '../../data/services/soil_dataset_service.dart';
import '../../data/services/soil_report_service.dart';
import '../../data/services/soil_gis_contour_service.dart';
import '../../data/services/soil_tile_service.dart';

enum GisLayer { healthScore, ph, moisture, ec, npk }

class SoilGisMapScreen extends StatefulWidget {
  const SoilGisMapScreen({super.key});

  @override
  State<SoilGisMapScreen> createState() => _SoilGisMapScreenState();
}

class _SoilGisMapScreenState extends State<SoilGisMapScreen> with SingleTickerProviderStateMixin {
  late final SoilReportService _reportService;
  late final MapController _mapController;

  List<SoilDatasetItem> _geotaggedItems = [];
  bool _isLoading = true;
  GisLayer _currentLayer = GisLayer.healthScore;
  BasemapType _currentBasemap = BasemapType.googleHybrid;
  bool _showContour = true;
  bool _is3DView = false;
  double _rotation = 0.0;
  SoilDatasetItem? _selectedItem;

  // Bounding box
  double _minLat = 0.0, _maxLat = 0.0;
  double _minLng = 0.0, _maxLng = 0.0;
  LatLng _centerPoint = const LatLng(12.6500, 102.1100);

  // Live GPS tracking
  LatLng? _userLiveLocation;
  bool _isLocatingLiveGps = false;

  // Cached Contour computation
  SoilContourResult? _contourResult;

  @override
  void initState() {
    super.initState();
    _reportService = SoilReportService();
    _mapController = MapController();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final allItems = await SoilDatasetService.getAllDatasetItems();
    final items = allItems.where((e) => e.hasGps).toList();

    if (items.isNotEmpty) {
      double minLat = items.first.latitude;
      double maxLat = items.first.latitude;
      double minLng = items.first.longitude;
      double maxLng = items.first.longitude;

      for (final it in items) {
        if (it.latitude < minLat) minLat = it.latitude;
        if (it.latitude > maxLat) maxLat = it.latitude;
        if (it.longitude < minLng) minLng = it.longitude;
        if (it.longitude > maxLng) maxLng = it.longitude;
      }

      // Add minimum margin if bounds are too tight (~270 meters)
      const minDelta = 0.0025;
      if ((maxLat - minLat).abs() < minDelta) {
        minLat -= minDelta / 2;
        maxLat += minDelta / 2;
      }
      if ((maxLng - minLng).abs() < minDelta) {
        minLng -= minDelta / 2;
        maxLng += minDelta / 2;
      }

      _minLat = minLat;
      _maxLat = maxLat;
      _minLng = minLng;
      _maxLng = maxLng;
      _centerPoint = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    }

    _recomputeContour(items);

    setState(() {
      _geotaggedItems = items;
      _isLoading = false;
    });

    if (items.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(_centerPoint, 16.5);
        } catch (_) {}
      });
    }
  }

  double _getMetricValue(SoilDatasetItem item, GisLayer layer) {
    switch (layer) {
      case GisLayer.healthScore:
        final phOk = item.ph >= 5.5 && item.ph <= 6.5;
        final moistOk = item.moisture >= 30 && item.moisture <= 65;
        final ecOk = item.ec <= 1200;
        int score = 40;
        if (phOk) score += 20;
        if (moistOk) score += 20;
        if (ecOk) score += 20;
        return score.toDouble();
      case GisLayer.ph:
        return item.ph;
      case GisLayer.moisture:
        return item.moisture;
      case GisLayer.ec:
        return item.ec.toDouble();
      case GisLayer.npk:
        return (item.nitrogen + item.phosphorus + item.potassium).toDouble();
    }
  }

  Color _getColorForValue(double val, GisLayer layer) {
    switch (layer) {
      case GisLayer.healthScore:
        if (val >= 75) return const Color(0xFF10B981);
        if (val >= 50) return Colors.amber;
        return Colors.redAccent;
      case GisLayer.ph:
        if (val < 5.0) return Colors.redAccent;
        if (val <= 6.5) return const Color(0xFF10B981);
        return Colors.blueAccent;
      case GisLayer.moisture:
        if (val < 30) return Colors.amber;
        if (val <= 65) return const Color(0xFF06B6D4);
        return const Color(0xFF3B82F6);
      case GisLayer.ec:
        if (val < 800) return const Color(0xFF10B981);
        if (val <= 1500) return Colors.orangeAccent;
        return Colors.redAccent;
      case GisLayer.npk:
        if (val > 90) return const Color(0xFF10B981);
        if (val > 50) return Colors.amber;
        return Colors.orangeAccent;
    }
  }

  Color _getItemColor(SoilDatasetItem item) {
    final val = _getMetricValue(item, _currentLayer);
    return _getColorForValue(val, _currentLayer);
  }

  void _recomputeContour(List<SoilDatasetItem> items) {
    if (items.isEmpty) {
      _contourResult = null;
      return;
    }

    _contourResult = SoilGisContourService.generateContour(
      items: items,
      minLat: _minLat,
      maxLat: _maxLat,
      minLng: _minLng,
      maxLng: _maxLng,
      valueExtractor: (it) => _getMetricValue(it, _currentLayer),
      resolution: 36,
      contourCount: 5,
    );
  }

  void _onLayerChanged(GisLayer layer) {
    setState(() {
      _currentLayer = layer;
      _recomputeContour(_geotaggedItems);
    });
  }

  void _resetNorth() {
    _mapController.rotate(0);
    setState(() => _rotation = 0.0);
  }

  Future<void> _fetchAndZoomToLiveGps() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    setState(() => _isLocatingLiveGps = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F766E),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
            ),
            const SizedBox(width: 10),
            Text(lang.t('fetchingGps')),
          ],
        ),
      ),
    );

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location service disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      final livePoint = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _userLiveLocation = livePoint;
        _isLocatingLiveGps = false;
      });

      _mapController.move(livePoint, 18.5);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF059669),
          content: Text(
            '${lang.t('gpsAcquired')}: ${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)} (±${pos.accuracy.toStringAsFixed(1)}m)',
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLocatingLiveGps = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('GPS Error: $e'),
        ),
      );
    }
  }

  void _showGpsLocationSelector() {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.58,
          minChildSize: 0.35,
          maxChildSize: 0.88,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.explore, color: Colors.cyanAccent, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        lang.t('selectGpsLocation'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Option 1: Live Device GPS
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _fetchAndZoomToLiveGps();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0284C7).withValues(alpha: 0.25),
                            const Color(0xFF0369A1).withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0284C7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.my_location, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.t('currentDeviceGps'),
                                  style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _userLiveLocation != null
                                      ? '${_userLiveLocation!.latitude.toStringAsFixed(6)}, ${_userLiveLocation!.longitude.toStringAsFixed(6)}'
                                      : 'ค้นหาและซูมไปยังตำแหน่งดาวเทียมที่ยืนอยู่จริง',
                                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.cyanAccent, size: 14),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Option 2: Center All Plots
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _mapController.move(_centerPoint, 16.5);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFF059669),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.filter_center_focus, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.t('centerAllPlots'),
                                  style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'กึ่งกลางพิกัดเฉลี่ย: ${_centerPoint.latitude.toStringAsFixed(6)}, ${_centerPoint.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  Text(
                    '${lang.t('soilSamplePoints')} (${_geotaggedItems.length})',
                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Option 3: List of All Geotagged Soil Points
                  ..._geotaggedItems.map((item) {
                    final color = _getItemColor(item);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          final pos = LatLng(item.latitude, item.longitude);
                          _mapController.move(pos, 18.5);
                          setState(() => _selectedItem = item);
                          _showSampleDetailSheet(item);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: color.withValues(alpha: 0.35)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 4),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.sampleId,
                                      style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '📍 ${item.latitude.toStringAsFixed(6)}, ${item.longitude.toStringAsFixed(6)} (Alt: ${item.altitude.toStringAsFixed(1)}m)',
                                      style: const TextStyle(color: Colors.white60, fontSize: 10.5),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'pH ${item.ph.toStringAsFixed(1)} | ${item.moisture.toStringAsFixed(0)}%',
                                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _exportGeoJson() async {
    if (_geotaggedItems.isEmpty) return;
    final file = await _reportService.exportGeoJson(_geotaggedItems);
    if (!mounted) return;
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0D9488),
        content: Text('${lang.t('exportGeoJson')}: ${file.path.split('/').last}'),
        action: SnackBarAction(
          label: lang.t('share'),
          textColor: Colors.white,
          onPressed: () => SoilDatasetService.shareDataFile(file.path),
        ),
      ),
    );
  }

  Future<void> _exportKml() async {
    if (_geotaggedItems.isEmpty) return;
    final file = await _reportService.exportKml(_geotaggedItems);
    if (!mounted) return;
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0D9488),
        content: Text('${lang.t('exportKml')}: ${file.path.split('/').last}'),
        action: SnackBarAction(
          label: lang.t('share'),
          textColor: Colors.white,
          onPressed: () => SoilDatasetService.shareDataFile(file.path),
        ),
      ),
    );
  }

  void _showSampleDetailSheet(SoilDatasetItem item) {
    setState(() => _selectedItem = item);
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.sampleId,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${item.latitude.toStringAsFixed(6)}, ${item.longitude.toStringAsFixed(6)} (Alt: ${item.altitude.toStringAsFixed(1)}m)',
                          style: const TextStyle(color: Colors.cyanAccent, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981)),
                    ),
                    child: Text(
                      item.mediaType.toUpperCase(),
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Parameters Grid
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildMetricBadge('pH', item.ph.toStringAsFixed(2), Colors.orangeAccent),
                  _buildMetricBadge('Moisture', '${item.moisture.toStringAsFixed(1)}%', Colors.lightBlueAccent),
                  _buildMetricBadge('EC', '${item.ec.toStringAsFixed(0)} µS', Colors.amberAccent),
                  _buildMetricBadge('N', '${item.nitrogen.toStringAsFixed(1)} mg', Colors.purpleAccent),
                  _buildMetricBadge('P', '${item.phosphorus.toStringAsFixed(1)} mg', Colors.cyanAccent),
                  _buildMetricBadge('K', '${item.potassium.toStringAsFixed(1)} mg', Colors.tealAccent),
                  _buildMetricBadge('Temp', '${item.temperature.toStringAsFixed(1)}°C', Colors.pinkAccent),
                ],
              ),
              const SizedBox(height: 20),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.description, size: 18),
                      label: Text(lang.t('generateCertificate'), style: const TextStyle(fontSize: 12.5)),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _reportService.generateAndShareCertificate(item);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.cyanAccent,
                        side: const BorderSide(color: Colors.cyanAccent),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.share, size: 18),
                      label: Text(lang.t('share'), style: const TextStyle(fontSize: 12.5)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        SoilDatasetService.shareItem(item);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricBadge(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTileLayer() {
    switch (_currentBasemap) {
      case BasemapType.googleHybrid:
        return TileLayer(
          urlTemplate: 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}',
          userAgentPackageName: 'com.agriphysics.soil_app',
          maxNativeZoom: 19,
          maxZoom: 20,
        );
      case BasemapType.esriSatellite:
        return TileLayer(
          urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          userAgentPackageName: 'com.agriphysics.soil_app',
          maxNativeZoom: 18,
          maxZoom: 20,
        );
      case BasemapType.street:
        return TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.agriphysics.soil_app',
          maxNativeZoom: 19,
          maxZoom: 20,
        );
      case BasemapType.offlineGrid:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    // Build Polylines for Connecting Survey Tracks
    final polylines = <Polyline>[];
    if (_geotaggedItems.length > 1) {
      polylines.add(
        Polyline(
          points: _geotaggedItems.map((e) => LatLng(e.latitude, e.longitude)).toList(),
          color: Colors.cyanAccent.withValues(alpha: 0.65),
          strokeWidth: 2.2,
        ),
      );
    }

    // Build Polylines for Contour Isolines
    if (_showContour && _contourResult != null && _contourResult!.geoSegments.isNotEmpty) {
      for (final seg in _contourResult!.geoSegments) {
        final color = _getColorForValue(seg.level, _currentLayer);
        polylines.add(
          Polyline(
            points: [seg.start, seg.end],
            color: color.withValues(alpha: 0.95),
            strokeWidth: 2.4,
          ),
        );
      }
    }

    // Build Markers for Geotagged Points
    final markers = _geotaggedItems.map((item) {
      final color = _getItemColor(item);
      final isSelected = _selectedItem?.sampleId == item.sampleId;
      final sampleNumber = item.sampleId.split('_').last;

      return Marker(
        point: LatLng(item.latitude, item.longitude),
        width: 70,
        height: 60,
        child: GestureDetector(
          onTap: () => _showSampleDetailSheet(item),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pin icon with glow
              Container(
                width: isSelected ? 24 : 18,
                height: isSelected ? 24 : 18,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.8),
                      blurRadius: isSelected ? 12 : 6,
                      spreadRadius: isSelected ? 3 : 1,
                    ),
                  ],
                ),
                child: isSelected
                    ? const Center(child: Icon(Icons.check, color: Colors.white, size: 12))
                    : null,
              ),
              const SizedBox(height: 2),
              // Sample Number Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withValues(alpha: 0.7), width: 1),
                ),
                child: Text(
                  sampleNumber,
                  style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    // Add Live User Location Marker if available
    if (_userLiveLocation != null) {
      markers.add(
        Marker(
          point: _userLiveLocation!,
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withValues(alpha: 0.8),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF070E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1726),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.t('gisMapTitle'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              '${lang.t('totalSamplePoints')}: ${_geotaggedItems.length}',
              style: const TextStyle(fontSize: 11, color: Colors.cyanAccent),
            ),
          ],
        ),
        actions: [
          // 2D / 3D Perspective Toggle Button
          IconButton(
            tooltip: _is3DView ? lang.t('view2D') : lang.t('view3D'),
            icon: Icon(
              _is3DView ? Icons.view_in_ar : Icons.layers_outlined,
              color: _is3DView ? Colors.orangeAccent : Colors.white70,
            ),
            onPressed: () => setState(() => _is3DView = !_is3DView),
          ),

          // Basemap Selector Menu
          PopupMenuButton<BasemapType>(
            icon: const Icon(Icons.layers, color: Colors.cyanAccent),
            tooltip: lang.t('basemap'),
            color: const Color(0xFF1E293B),
            onSelected: (type) => setState(() => _currentBasemap = type),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: BasemapType.googleHybrid,
                child: Row(
                  children: [
                    Icon(Icons.satellite_alt, color: _currentBasemap == BasemapType.googleHybrid ? Colors.cyanAccent : Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    Text(lang.t('basemapGoogleHybrid'), style: TextStyle(color: _currentBasemap == BasemapType.googleHybrid ? Colors.cyanAccent : Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: BasemapType.esriSatellite,
                child: Row(
                  children: [
                    Icon(Icons.public, color: _currentBasemap == BasemapType.esriSatellite ? Colors.cyanAccent : Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    Text(lang.t('basemapEsri'), style: TextStyle(color: _currentBasemap == BasemapType.esriSatellite ? Colors.cyanAccent : Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: BasemapType.street,
                child: Row(
                  children: [
                    Icon(Icons.map, color: _currentBasemap == BasemapType.street ? Colors.cyanAccent : Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    Text(lang.t('basemapStreet'), style: TextStyle(color: _currentBasemap == BasemapType.street ? Colors.cyanAccent : Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: BasemapType.offlineGrid,
                child: Row(
                  children: [
                    Icon(Icons.grid_on, color: _currentBasemap == BasemapType.offlineGrid ? Colors.cyanAccent : Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    Text(lang.t('basemapOffline'), style: TextStyle(color: _currentBasemap == BasemapType.offlineGrid ? Colors.cyanAccent : Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),

          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadData,
          ),

          // Export GeoJSON / KML
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download, color: Colors.cyanAccent),
            color: const Color(0xFF1E293B),
            onSelected: (val) {
              if (val == 'geojson') _exportGeoJson();
              if (val == 'kml') _exportKml();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'geojson',
                child: Row(
                  children: [
                    const Icon(Icons.public, color: Colors.cyanAccent, size: 18),
                    const SizedBox(width: 8),
                    Text(lang.t('exportGeoJson'), style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'kml',
                child: Row(
                  children: [
                    const Icon(Icons.map, color: Colors.greenAccent, size: 18),
                    const SizedBox(width: 8),
                    Text(lang.t('exportKml'), style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : _geotaggedItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off, size: 54, color: Colors.white24),
                      const SizedBox(height: 12),
                      Text(lang.t('noGpsData'), style: const TextStyle(color: Colors.white60)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Layer Selection Chips
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      color: const Color(0xFF0F1C2E),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildLayerChip(GisLayer.healthScore, lang.t('layerHealthScore')),
                            const SizedBox(width: 6),
                            _buildLayerChip(GisLayer.ph, lang.t('layerPh')),
                            const SizedBox(width: 6),
                            _buildLayerChip(GisLayer.moisture, lang.t('layerMoisture')),
                            const SizedBox(width: 6),
                            _buildLayerChip(GisLayer.ec, lang.t('layerEc')),
                            const SizedBox(width: 6),
                            _buildLayerChip(GisLayer.npk, lang.t('layerNpk')),
                          ],
                        ),
                      ),
                    ),

                    // Google Maps Interactive 3D Canvas
                    Expanded(
                      child: Stack(
                        children: [
                          // 3D Perspective Tilt Transform
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                            transform: _is3DView
                                ? (Matrix4.identity()
                                  ..setEntry(3, 2, 0.0012)
                                  ..rotateX(36.0 * math.pi / 180.0))
                                : Matrix4.identity(),
                            transformAlignment: Alignment.center,
                            child: FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _centerPoint,
                                initialZoom: 16.5,
                                minZoom: 3.0,
                                maxZoom: 20.0,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.all, // Zoom, Pan, Two-finger Rotate, Double-tap zoom
                                ),
                                onPositionChanged: (pos, hasGesture) {
                                  if (pos.rotation != _rotation) {
                                    setState(() => _rotation = pos.rotation);
                                  }
                                },
                              ),
                              children: [
                                _buildTileLayer(),
                                PolylineLayer(polylines: polylines),
                                MarkerLayer(markers: markers),
                              ],
                            ),
                          ),

                          // Floating Overlay: Contour Toggle
                          Positioned(
                            top: 14,
                            left: 14,
                            child: _buildGlassToggle(
                              icon: Icons.waves,
                              label: lang.t('toggleContour'),
                              active: _showContour,
                              onTap: () => setState(() => _showContour = !_showContour),
                            ),
                          ),

                          // Dynamic Compass & North HUD
                          Positioned(
                            top: 14,
                            right: 14,
                            child: GestureDetector(
                              onTap: _resetNorth,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Transform.rotate(
                                  angle: -(_rotation * math.pi / 180.0),
                                  child: const Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('N', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                      Icon(Icons.navigation, color: Colors.cyanAccent, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Zoom In / Zoom Out / GPS Coordinate Selector Floating Controls
                          Positioned(
                            right: 14,
                            bottom: 60,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FloatingActionButton.small(
                                  heroTag: 'zoom_in',
                                  backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.85),
                                  foregroundColor: Colors.cyanAccent,
                                  onPressed: () {
                                    final currentZoom = _mapController.camera.zoom;
                                    _mapController.move(_mapController.camera.center, currentZoom + 1);
                                  },
                                  child: const Icon(Icons.add, size: 20),
                                ),
                                const SizedBox(height: 8),
                                FloatingActionButton.small(
                                  heroTag: 'zoom_out',
                                  backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.85),
                                  foregroundColor: Colors.cyanAccent,
                                  onPressed: () {
                                    final currentZoom = _mapController.camera.zoom;
                                    _mapController.move(_mapController.camera.center, currentZoom - 1);
                                  },
                                  child: const Icon(Icons.remove, size: 20),
                                ),
                                const SizedBox(height: 8),
                                // Circle GPS Coordinate Selector Button
                                FloatingActionButton.small(
                                  heroTag: 'recenter',
                                  backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.85),
                                  foregroundColor: Colors.greenAccent,
                                  tooltip: lang.t('selectGpsLocation'),
                                  onPressed: _showGpsLocationSelector,
                                  child: _isLocatingLiveGps
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent),
                                        )
                                      : const Icon(Icons.my_location, size: 18),
                                ),
                              ],
                            ),
                          ),

                          // Bottom Tip
                          Positioned(
                            bottom: 12,
                            left: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.touch_app, color: Colors.cyanAccent, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    lang.t('selectPinToView'),
                                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildGlassToggle({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0F766E).withValues(alpha: 0.85) : Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? Colors.cyanAccent : Colors.white24,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? Colors.cyanAccent : Colors.white60, size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerChip(GisLayer layer, String label) {
    final isSelected = _currentLayer == layer;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label, style: TextStyle(fontSize: 11.5, color: isSelected ? Colors.black : Colors.white70)),
      selectedColor: Colors.cyanAccent,
      backgroundColor: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onSelected: (_) => _onLayerChanged(layer),
    );
  }
}
