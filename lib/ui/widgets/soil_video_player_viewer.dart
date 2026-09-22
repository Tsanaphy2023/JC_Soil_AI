import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../data/models/soil_dataset_item.dart';
import '../../data/models/soil_reading.dart';
import '../../data/services/multi_color_space_service.dart';
import '../../data/services/soil_dataset_service.dart';
import '../../domain/models/soil_multimodal_deep_model.dart';

/// In-App Video Player with Real-Time Synchronized Telemetry HUD Overlay
/// Displays soil research video samples with live GPS, 8-in-1 sensor metrics,
/// cyber targeting reticle, and AI PINN calibration banners directly on screen.
class SoilVideoPlayerViewer extends StatefulWidget {
  final SoilDatasetItem item;
  final bool isFullScreen;

  const SoilVideoPlayerViewer({
    super.key,
    required this.item,
    this.isFullScreen = false,
  });

  @override
  State<SoilVideoPlayerViewer> createState() => _SoilVideoPlayerViewerState();
}

class _SoilVideoPlayerViewerState extends State<SoilVideoPlayerViewer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showHud = true;
  bool _showControls = true;
  bool _isMuted = false;
  bool _showAiMultimodalView = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final file = File(widget.item.filePath);
      if (!await file.exists()) {
        setState(() {
          _hasError = true;
          _errorMessage = 'ไม่พบไฟล์วิดีโอ: ${widget.item.fileName}';
        });
        return;
      }

      final controller = VideoPlayerController.file(file);
      _controller = controller;

      await controller.initialize();
      controller.addListener(_videoListener);
      controller.setLooping(true);
      await controller.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'เกิดข้อผิดพลาดในการโหลดวิดีโอ: $e';
        });
      }
    }
  }

  void _videoListener() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _togglePlayPause() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
    setState(() {});
  }

  void _toggleMute() {
    if (_controller == null) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        padding: const EdgeInsets.all(20),
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 10),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800),
                onPressed: _initVideo,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('ลองใหม่อีกครั้ง'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.cyanAccent),
              SizedBox(height: 12),
              Text(
                'กำลังโหลดวิดีโอพร้อมข้อมูล Telemetry...',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Raw Video Stream
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio > 0
                    ? _controller!.value.aspectRatio
                    : 9 / 16,
                child: VideoPlayer(_controller!),
              ),
            ),

            // 2. Synchronized Telemetry HUD Layer (Can be toggled)
            if (_showHud) ...[
              // Top Branding & GPS Header Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopHeaderHud(),
              ),

              // Center Cyber Reticle
              _buildCenterReticle(),

              // Bottom 8-in-1 Telemetry Cards + AI PINN Calibration Banner
              Positioned(
                bottom: _showControls ? 74 : 12,
                left: 10,
                right: 10,
                child: _buildBottomTelemetryHud(),
              ),
            ],

            // 3. Playback Controls Bar
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildControlsBar(),
              ),
          ],
        ),
      ),
    );
  }

  /// Top HUD Bar: Branding + GPS + Alt + Timestamp + REC Status
  Widget _buildTopHeaderHud() {
    final item = widget.item;
    final lat = item.latitude;
    final lon = item.longitude;
    final alt = item.altitude;

    String gpsText = '📍 GPS: ${lat.toStringAsFixed(5)}° N, ${lon.toStringAsFixed(5)}° E';
    if (alt > 0) {
      gpsText += '  |  Alt: ${alt.toStringAsFixed(1)}m (MSL)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.88),
            Colors.black.withValues(alpha: 0.60),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // System Title
              const Expanded(
                child: Text(
                  '🌱 JC SOIL AI ANALYZER  |  SciRBRU AgriPhysics',
                  style: TextStyle(
                    color: Color(0xFF00FFFF),
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Playback Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.redAccent, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'VIDEO PLAYBACK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  gpsText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                item.formattedShortDate,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Center Targeting Reticle
  Widget _buildCenterReticle() {
    return IgnorePointer(
      child: Center(
        child: SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Reticle border brackets
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0x7700FFFF),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Center Crosshair
              const Icon(
                Icons.add,
                color: Color(0xAA00FFFF),
                size: 24,
              ),
              // Subtitle Tag
              Positioned(
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    '[ + ] SOIL TARGET ZONE',
                    style: TextStyle(
                      color: Color(0xCC00FFFF),
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom HUD: 8-in-1 Soil Parameters & AI PINN Calibration Banner
  Widget _buildBottomTelemetryHud() {
    final item = widget.item;

    final sensorReading = SoilReading(
      temperature: item.temperature,
      moisture: item.moisture,
      conductivity: item.conductivity,
      ph: item.ph,
      nitrogen: item.nitrogen,
      phosphorus: item.phosphorus,
      potassium: item.potassium,
      fertility: item.fertility,
      timestamp: item.timestamp,
    );
    final baselineVisionMetric = MultiColorSpaceService.fromRgb(125, 90, 65);
    final aiInference = SoilMultimodalDeepModel.infer(
      visionMetric: baselineVisionMetric,
      sensorReading: sensorReading,
    );

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xE00C1017),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _showAiMultimodalView ? aiInference.statusColor.withValues(alpha: 0.8) : const Color(0x6600FFFF),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title Bar with Mode Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    _showAiMultimodalView ? Icons.psychology_rounded : Icons.sensors_rounded,
                    size: 14,
                    color: _showAiMultimodalView ? Colors.cyanAccent : Colors.greenAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _showAiMultimodalView ? 'AI MULTIMODAL DEEP LEARNING' : 'TELEMETRY HUD (8-IN-1)',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _showAiMultimodalView = !_showAiMultimodalView),
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _showAiMultimodalView ? 'ดูเซนเซอร์ 8-in-1' : 'ดู AI ฟิวชัน',
                        style: const TextStyle(fontSize: 8.5, color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.swap_horiz, size: 11, color: Colors.cyanAccent),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (_showAiMultimodalView) ...[
            // Multimodal View
            Row(
              children: [
                _buildParamTile('Sensor pH', item.ph.toStringAsFixed(2), const Color(0xFFFFA726)),
                _buildParamTile('Vision pH', aiInference.visionPh.toStringAsFixed(2), aiInference.statusColor),
                _buildParamTile('อินทรียวัตถุ SOM', '${aiInference.soilOrganicMatterPct.toStringAsFixed(1)}%', const Color(0xFF00E5FF)),
                _buildParamTile('ความชื้น VWC', '${item.moisture.toStringAsFixed(1)}%', const Color(0xFF29B6F6)),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                _buildParamTile('AI Nitrogen', '${aiInference.predictedNitrogen} mg/kg', const Color(0xFFFF7043)),
                _buildParamTile('AI Phosphorus', '${aiInference.predictedPhosphorus} mg/kg', const Color(0xFF42A5F5)),
                _buildParamTile('AI Potassium', '${aiInference.predictedPotassium} mg/kg', const Color(0xFFAB47BC)),
                _buildParamTile('ความสอดคล้อง', '${(aiInference.consistencyScore * 100).toStringAsFixed(0)}%', aiInference.statusColor),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xCC002B36),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: aiInference.statusColor.withValues(alpha: 0.4), width: 0.7),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_rounded, color: aiInference.statusColor, size: 13),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      aiInference.agreementStatus,
                      style: TextStyle(
                        color: aiInference.statusColor,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
          // Row 1: Temp, Moisture, EC, pH
          Row(
            children: [
              _buildParamTile('ความชื้น', '${item.moisture.toStringAsFixed(1)}%', const Color(0xFF29B6F6)),
              _buildParamTile('อุณหภูมิ', '${item.temperature.toStringAsFixed(1)}°C', const Color(0xFF66BB6A)),
              _buildParamTile('EC', '${item.conductivity} µS', const Color(0xFFAB47BC)),
              _buildParamTile('pH', item.ph.toStringAsFixed(2), const Color(0xFFFFA726)),
            ],
          ),
          const SizedBox(height: 5),

          // Row 2: N, P, K, Fertility
          Row(
            children: [
              _buildParamTile('ไนโตรเจน (N)', '${item.nitrogen} mg/kg', const Color(0xFFEC407A)),
              _buildParamTile('ฟอสฟอรัส (P)', '${item.phosphorus} mg/kg', const Color(0xFF26C6DA)),
              _buildParamTile('โพแทสเซียม (K)', '${item.potassium} mg/kg', const Color(0xFF26A69A)),
              _buildParamTile('Fertility', '${item.fertility}', const Color(0xFFFF7043)),
            ],
          ),

          // Row 3: AI PINN Calibration Banner
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: const Color(0xCC003B46),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF00FFAA).withValues(alpha: 0.4), width: 0.7),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology, color: Color(0xFF00FFAA), size: 13),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'AI PINN: pH ${item.aiPh?.toStringAsFixed(2) ?? item.ph.toStringAsFixed(2)}  |  EC ${item.aiConductivity ?? item.conductivity}µS  |  Moist ${item.aiMoisture?.toStringAsFixed(1) ?? item.moisture.toStringAsFixed(1)}%'
                    '${item.aiConfidenceScore != null && item.aiConfidenceScore! > 0 ? " (${(item.aiConfidenceScore! * 100).toStringAsFixed(1)}%)" : ""}',
                    style: const TextStyle(
                      color: Color(0xFF00FFAA),
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          ],
        ],
      ),
    );
  }

  Widget _buildParamTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF161E28),
          borderRadius: BorderRadius.circular(4),
          border: Border(left: BorderSide(color: color, width: 2.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 8.5, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom Media Controls Bar
  Widget _buildControlsBar() {
    final controller = _controller!;
    final position = controller.value.position;
    final duration = controller.value.duration;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        border: const Border(top: BorderSide(color: Colors.white12, width: 0.8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timeline Slider
          Row(
            children: [
              Text(
                _formatDuration(position),
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace'),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    thumbColor: Colors.cyanAccent,
                    activeTrackColor: Colors.cyanAccent,
                    inactiveTrackColor: Colors.white24,
                  ),
                  child: Slider(
                    value: duration.inMilliseconds > 0
                        ? position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble())
                        : 0.0,
                    min: 0.0,
                    max: duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                    onChanged: (val) {
                      controller.seekTo(Duration(milliseconds: val.toInt()));
                    },
                  ),
                ),
              ),
              Text(
                _formatDuration(duration),
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace'),
              ),
            ],
          ),

          // Control Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Play / Pause
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    iconSize: 26,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: Colors.cyanAccent,
                    ),
                    onPressed: _togglePlayPause,
                  ),
                  const SizedBox(width: 14),

                  // Mute Toggle
                  IconButton(
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: _isMuted ? Colors.redAccent : Colors.white70,
                    ),
                    tooltip: _isMuted ? 'เปิดเสียง' : 'ปิดเสียง',
                    onPressed: _toggleMute,
                  ),
                  const SizedBox(width: 14),

                  // Replay from start
                  IconButton(
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.replay, color: Colors.white70),
                    tooltip: 'เล่นซ้ำตั้งแต่ต้น',
                    onPressed: () {
                      controller.seekTo(Duration.zero);
                      controller.play();
                    },
                  ),
                ],
              ),

              // Right Buttons: HUD Toggle & Share
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Toggle HUD Button
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showHud = !_showHud;
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _showHud ? Colors.teal.shade900 : Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _showHud ? Colors.cyanAccent : Colors.white30,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showHud ? Icons.layers : Icons.layers_clear,
                            color: _showHud ? Colors.cyanAccent : Colors.white60,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _showHud ? 'HUD แสดงผล' : 'HUD ซ่อน',
                            style: TextStyle(
                              color: _showHud ? Colors.cyanAccent : Colors.white60,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Share Video
                  IconButton(
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.share, color: Colors.cyanAccent),
                    tooltip: 'แชร์คลิปวิดีโอ',
                    onPressed: () async {
                      await SoilDatasetService.shareItem(widget.item);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
