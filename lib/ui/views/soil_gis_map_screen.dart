import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/localization/language_provider.dart';
import '../../data/models/soil_dataset_item.dart';
import '../../data/services/soil_dataset_service.dart';
import '../../data/services/soil_report_service.dart';

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
  SoilDatasetItem? _selectedItem;

  // Bounding box
  double _minLat = 0.0, _maxLat = 0.0;
  double _minLng = 0.0, _maxLng = 0.0;

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

      // Add minimum margin if bounds are too tight (e.g. single point or points close together)
      const minDelta = 0.0025; // ~270 meters
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

    setState(() {
      _geotaggedItems = items;
      _isLoading = false;
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

  Color _getColorForValue(SoilDatasetItem item) {
    switch (_currentLayer) {
      case GisLayer.healthScore:
        final score = item.ph >= 5.5 && item.ph <= 6.5 && item.moisture >= 30 && item.moisture <= 65 ? 85 : 45;
        return score >= 75 ? const Color(0xFF10B981) : (score >= 50 ? Colors.amber : Colors.redAccent);
      case GisLayer.ph:
        if (item.ph < 5.0) return Colors.redAccent;
        if (item.ph <= 6.5) return const Color(0xFF10B981);
        return Colors.blueAccent;
      case GisLayer.moisture:
        if (item.moisture < 30) return Colors.amber;
        if (item.moisture <= 65) return const Color(0xFF06B6D4);
        return const Color(0xFF3B82F6);
      case GisLayer.ec:
        if (item.ec < 800) return const Color(0xFF10B981);
        if (item.ec <= 1500) return Colors.orangeAccent;
        return Colors.redAccent;
      case GisLayer.npk:
        final total = item.nitrogen + item.phosphorus + item.potassium;
        if (total > 90) return const Color(0xFF10B981);
        if (total > 50) return Colors.amber;
        return Colors.orangeAccent;
    }
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadData,
          ),
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

                    // Interactive Field Canvas
                    Expanded(
                      child: Stack(
                        children: [
                          InteractiveViewer(
                            boundaryMargin: const EdgeInsets.all(100),
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
                                    selectedItem: _selectedItem,
                                    colorGetter: _getColorForValue,
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

                          // Compass and HUD overlay
                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
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
                                color: Colors.black.withValues(alpha: 0.7),
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

  Widget _buildLayerChip(GisLayer layer, String label) {
    final isSelected = _currentLayer == layer;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label, style: TextStyle(fontSize: 11.5, color: isSelected ? Colors.black : Colors.white70)),
      selectedColor: Colors.cyanAccent,
      backgroundColor: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      onSelected: (_) => setState(() => _currentLayer = layer),
    );
  }

  void _handleCanvasTap(Offset localPos, double width, double height) {
    const padding = 40.0;
    final drawW = width - (padding * 2);
    final drawH = height - (padding * 2);

    final lngDelta = _maxLng - _minLng;
    final latDelta = _maxLat - _minLat;

    SoilDatasetItem? tappedItem;
    double closestDist = 30.0; // hit target radius

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
  final SoilDatasetItem? selectedItem;
  final Color Function(SoilDatasetItem) colorGetter;

  _SoilGisPainter({
    required this.items,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
    required this.currentLayer,
    required this.selectedItem,
    required this.colorGetter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF070E17);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.4)
      ..strokeWidth = 1.0;

    const gridDivs = 8;
    for (int i = 0; i <= gridDivs; i++) {
      final x = (size.width / gridDivs) * i;
      final y = (size.height / gridDivs) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    const padding = 40.0;
    final drawW = size.width - (padding * 2);
    final drawH = size.height - (padding * 2);

    final lngDelta = maxLng - minLng;
    final latDelta = maxLat - minLat;

    // Draw Heat halos & Connecting survey path
    if (items.length > 1) {
      final pathPaint = Paint()
        ..color = const Color(0xFF0D9488).withValues(alpha: 0.3)
        ..strokeWidth = 1.8
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

    // Draw Points
    for (final item in items) {
      final normX = lngDelta > 0 ? (item.longitude - minLng) / lngDelta : 0.5;
      final normY = latDelta > 0 ? 1.0 - ((item.latitude - minLat) / latDelta) : 0.5;

      final px = padding + (normX * drawW);
      final py = padding + (normY * drawH);

      final color = colorGetter(item);
      final isSelected = selectedItem?.sampleId == item.sampleId;

      // Glow halo
      final haloPaint = Paint()
        ..color = color.withValues(alpha: isSelected ? 0.45 : 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(Offset(px, py), isSelected ? 22 : 15, haloPaint);

      // Core Pin Circle
      final corePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), isSelected ? 8.5 : 6.0, corePaint);

      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(px, py), isSelected ? 8.5 : 6.0, borderPaint);

      // Label on Pin
      final textSpan = TextSpan(
        text: item.sampleId.split('_').last,
        style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(px - (textPainter.width / 2), py + 9));
    }
  }

  @override
  bool shouldRepaint(covariant _SoilGisPainter oldDelegate) {
    return oldDelegate.currentLayer != currentLayer ||
        oldDelegate.selectedItem != selectedItem ||
        oldDelegate.items.length != items.length;
  }
}
