import 'dart:math' as math;
import 'package:flutter/material.dart';
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

class _SoilGisMapScreenState extends State<SoilGisMapScreen> {
  late final SoilReportService _reportService;

  List<SoilDatasetItem> _geotaggedItems = [];
  bool _isLoading = true;
  GisLayer _currentLayer = GisLayer.healthScore;
  BasemapType _currentBasemap = BasemapType.satellite;
  bool _showContour = true;
  bool _showHeatmap = true;
  SoilDatasetItem? _selectedItem;

  // Bounding box
  double _minLat = 0.0, _maxLat = 0.0;
  double _minLng = 0.0, _maxLng = 0.0;

  // Cached Contour computation
  SoilContourResult? _contourResult;

  @override
  void initState() {
    super.initState();
    _reportService = SoilReportService();
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
    }

    _recomputeContour(items);

    setState(() {
      _geotaggedItems = items;
      _isLoading = false;
    });
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

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

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
          // Basemap Selector Menu
          PopupMenuButton<BasemapType>(
            icon: const Icon(Icons.layers, color: Colors.cyanAccent),
            tooltip: lang.t('basemap'),
            color: const Color(0xFF1E293B),
            onSelected: (type) => setState(() => _currentBasemap = type),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: BasemapType.satellite,
                child: Row(
                  children: [
                    Icon(Icons.satellite_alt, color: _currentBasemap == BasemapType.satellite ? Colors.cyanAccent : Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    Text(lang.t('basemapSatellite'), style: TextStyle(color: _currentBasemap == BasemapType.satellite ? Colors.cyanAccent : Colors.white, fontSize: 13)),
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

                    // Interactive Map Canvas with Basemap & Contours
                    Expanded(
                      child: Stack(
                        children: [
                          InteractiveViewer(
                            boundaryMargin: const EdgeInsets.all(120),
                            minScale: 0.5,
                            maxScale: 6.0,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final canvasWidth = constraints.maxWidth;
                                final canvasHeight = constraints.maxHeight;

                                return CustomPaint(
                                  size: Size(canvasWidth, canvasHeight),
                                  painter: _SoilGisPainter(
                                    items: _geotaggedItems,
                                    minLat: _minLat,
                                    maxLat: _maxLat,
                                    minLng: _minLng,
                                    maxLng: _maxLng,
                                    currentLayer: _currentLayer,
                                    basemap: _currentBasemap,
                                    showContour: _showContour,
                                    showHeatmap: _showHeatmap,
                                    contourResult: _contourResult,
                                    selectedItem: _selectedItem,
                                    colorGetter: _getItemColor,
                                    valueColorGetter: (v) => _getColorForValue(v, _currentLayer),
                                    onTileLoaded: () {
                                      if (mounted) setState(() {});
                                    },
                                  ),
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTapUp: (details) {
                                      _handleCanvasTap(details.localPosition, canvasWidth, canvasHeight);
                                    },
                                  ),
                                );
                              },
                            ),
                          ),

                          // Floating Overlay Controls: Contour & Heatmap Toggles
                          Positioned(
                            top: 14,
                            left: 14,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildGlassToggle(
                                  icon: Icons.waves,
                                  label: lang.t('toggleContour'),
                                  active: _showContour,
                                  onTap: () => setState(() => _showContour = !_showContour),
                                ),
                                const SizedBox(height: 8),
                                _buildGlassToggle(
                                  icon: Icons.blur_on,
                                  label: lang.t('toggleHeatmap'),
                                  active: _showHeatmap,
                                  onTap: () => setState(() => _showHeatmap = !_showHeatmap),
                                ),
                              ],
                            ),
                          ),

                          // Compass & North HUD
                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                              ),
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('N', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                  Icon(Icons.navigation, color: Colors.cyanAccent, size: 16),
                                ],
                              ),
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

  void _handleCanvasTap(Offset localPos, double width, double height) {
    const padding = 40.0;
    final drawW = width - (padding * 2);
    final drawH = height - (padding * 2);

    final lngDelta = _maxLng - _minLng;
    final latDelta = _maxLat - _minLat;

    SoilDatasetItem? tappedItem;
    double closestDist = 32.0; // hit target radius

    for (final item in _geotaggedItems) {
      final normX = lngDelta > 0 ? (item.longitude - _minLng) / lngDelta : 0.5;
      final normY = latDelta > 0 ? 1.0 - ((item.latitude - _minLat) / latDelta) : 0.5;

      final px = padding + (normX * drawW);
      final py = padding + (normY * drawH);

      final dist = math.sqrt(math.pow(localPos.dx - px, 2) + math.pow(localPos.dy - py, 2));
      if (dist < closestDist) {
        closestDist = dist;
        tappedItem = item;
      }
    }

    if (tappedItem != null) {
      _showSampleDetailSheet(tappedItem);
    }
  }
}

class _SoilGisPainter extends CustomPainter {
  final List<SoilDatasetItem> items;
  final double minLat, maxLat, minLng, maxLng;
  final GisLayer currentLayer;
  final BasemapType basemap;
  final bool showContour;
  final bool showHeatmap;
  final SoilContourResult? contourResult;
  final SoilDatasetItem? selectedItem;
  final Color Function(SoilDatasetItem) colorGetter;
  final Color Function(double) valueColorGetter;
  final VoidCallback onTileLoaded;

  _SoilGisPainter({
    required this.items,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
    required this.currentLayer,
    required this.basemap,
    required this.showContour,
    required this.showHeatmap,
    required this.contourResult,
    required this.selectedItem,
    required this.colorGetter,
    required this.valueColorGetter,
    required this.onTileLoaded,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base Dark Background
    final bgPaint = Paint()..color = const Color(0xFF070E17);
    canvas.drawRect(Offset.zero & size, bgPaint);

    const padding = 40.0;
    final drawW = size.width - (padding * 2);
    final drawH = size.height - (padding * 2);

    final lngDelta = maxLng - minLng;
    final latDelta = maxLat - minLat;

    // 2. Render Slippy Basemap Tiles (Satellite or Street)
    if (basemap != BasemapType.offlineGrid && lngDelta > 0 && latDelta > 0) {
      final tiles = SoilTileService.getTilesForBounds(
        minLat: minLat,
        maxLat: maxLat,
        minLng: minLng,
        maxLng: maxLng,
      );

      for (final tile in tiles) {
        final cached = SoilTileService.getCachedTile(basemap, tile);
        if (cached != null) {
          final leftNorm = (tile.minLng - minLng) / lngDelta;
          final rightNorm = (tile.maxLng - minLng) / lngDelta;
          final topNorm = 1.0 - ((tile.maxLat - minLat) / latDelta);
          final bottomNorm = 1.0 - ((tile.minLat - minLat) / latDelta);

          final destRect = Rect.fromLTRB(
            padding + leftNorm * drawW,
            padding + topNorm * drawH,
            padding + rightNorm * drawW,
            padding + bottomNorm * drawH,
          );

          final srcRect = Rect.fromLTWH(0, 0, cached.width.toDouble(), cached.height.toDouble());
          canvas.drawImageRect(cached, srcRect, destRect, Paint());
        } else {
          // Request tile for background fetch
          SoilTileService.requestTile(
            type: basemap,
            tile: tile,
            onLoaded: onTileLoaded,
          );
        }
      }

      // Add a subtle dark vignette to enhance pins and contours over satellite
      final vignettePaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Offset.zero & size, vignettePaint);
    } else {
      // Offline Grid Lines
      final gridPaint = Paint()
        ..color = const Color(0xFF1E293B).withValues(alpha: 0.45)
        ..strokeWidth = 1.0;

      const gridDivs = 8;
      for (int i = 0; i <= gridDivs; i++) {
        final x = (size.width / gridDivs) * i;
        final y = (size.height / gridDivs) * i;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    // 3. Render Continuous IDW Surface Heatmap Layer
    if (showHeatmap && contourResult != null && contourResult!.grid.isNotEmpty) {
      final res = contourResult!.grid.length;
      final cellW = drawW / (res - 1);
      final cellH = drawH / (res - 1);
      final isRealMap = basemap != BasemapType.offlineGrid;

      for (int r = 0; r < res - 1; r++) {
        for (int c = 0; c < res - 1; c++) {
          final val = contourResult!.grid[r][c];
          final color = valueColorGetter(val);

          final cellRect = Rect.fromLTWH(
            padding + (c * cellW),
            padding + (r * cellH),
            cellW + 0.8, // slight overlap to prevent seams
            cellH + 0.8,
          );

          final heatPaint = Paint()
            ..color = color.withValues(alpha: isRealMap ? 0.38 : 0.48)
            ..style = PaintingStyle.fill;

          canvas.drawRect(cellRect, heatPaint);
        }
      }
    }

    // 4. Render Marching Squares Contour Isolines
    if (showContour && contourResult != null && contourResult!.segments.isNotEmpty) {
      final contourLinePaint = Paint()
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;

      final haloLinePaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.6)
        ..strokeWidth = 3.2
        ..style = PaintingStyle.stroke;

      int segIdx = 0;
      for (final seg in contourResult!.segments) {
        final p1 = Offset(
          padding + seg.start.dx * drawW,
          padding + seg.start.dy * drawH,
        );
        final p2 = Offset(
          padding + seg.end.dx * drawW,
          padding + seg.end.dy * drawH,
        );

        final color = valueColorGetter(seg.level);

        // Halo under line for high contrast
        canvas.drawLine(p1, p2, haloLinePaint);

        // Core contour line
        contourLinePaint.color = color;
        canvas.drawLine(p1, p2, contourLinePaint);

        // Draw Contour Level Label occasionally
        if (segIdx % 16 == 0) {
          final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
          final textSpan = TextSpan(
            text: seg.level.toStringAsFixed(1),
            style: TextStyle(
              color: Colors.white,
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              backgroundColor: Colors.black.withValues(alpha: 0.75),
            ),
          );
          final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
          tp.paint(canvas, Offset(mid.dx - (tp.width / 2), mid.dy - (tp.height / 2)));
        }
        segIdx++;
      }
    }

    // 5. Connecting Survey Path
    if (items.length > 1) {
      final pathPaint = Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.4)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;

      final path = Path();
      for (int i = 0; i < items.length; i++) {
        final it = items[i];
        final normX = lngDelta > 0 ? (it.longitude - minLng) / lngDelta : 0.5;
        final normY = latDelta > 0 ? 1.0 - ((it.latitude - minLat) / latDelta) : 0.5;
        final px = padding + (normX * drawW);
        final py = padding + (normY * drawH);

        if (i == 0) {
          path.moveTo(px, py);
        } else {
          path.lineTo(px, py);
        }
      }
      canvas.drawPath(path, pathPaint);
    }

    // 6. Draw Survey Pin Points
    for (final item in items) {
      final normX = lngDelta > 0 ? (item.longitude - minLng) / lngDelta : 0.5;
      final normY = latDelta > 0 ? 1.0 - ((item.latitude - minLat) / latDelta) : 0.5;

      final px = padding + (normX * drawW);
      final py = padding + (normY * drawH);

      final color = colorGetter(item);
      final isSelected = selectedItem?.sampleId == item.sampleId;

      // Glow halo
      final haloPaint = Paint()
        ..color = color.withValues(alpha: isSelected ? 0.6 : 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(Offset(px, py), isSelected ? 24 : 16, haloPaint);

      // Core Pin Circle
      final corePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), isSelected ? 9.0 : 6.5, corePaint);

      // Contrast white border
      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(px, py), isSelected ? 9.0 : 6.5, borderPaint);

      // Pin Label Badge
      final sampleNumber = item.sampleId.split('_').last;
      final textSpan = TextSpan(
        text: sampleNumber,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(color: Colors.black, blurRadius: 3),
          ],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      // Label background pill
      final labelBgRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(px, py + 15),
          width: textPainter.width + 6,
          height: textPainter.height + 3,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(labelBgRect, Paint()..color = Colors.black.withValues(alpha: 0.75));
      textPainter.paint(canvas, Offset(px - (textPainter.width / 2), py + 9.5));
    }
  }

  @override
  bool shouldRepaint(covariant _SoilGisPainter oldDelegate) {
    return oldDelegate.currentLayer != currentLayer ||
        oldDelegate.basemap != basemap ||
        oldDelegate.showContour != showContour ||
        oldDelegate.showHeatmap != showHeatmap ||
        oldDelegate.contourResult != contourResult ||
        oldDelegate.selectedItem != selectedItem ||
        oldDelegate.items.length != items.length;
  }
}
