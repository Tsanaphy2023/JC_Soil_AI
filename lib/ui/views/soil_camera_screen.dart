import "../widgets/interactive_roi_selector.dart";
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/localization/language_provider.dart';
import '../../data/services/multi_color_space_service.dart';
import '../../data/services/soil_dataset_service.dart';
import '../../data/services/usb_sensor_service.dart';
import '../../domain/models/soil_multimodal_deep_model.dart';
import '../viewmodels/soil_sensor_viewmodel.dart';
import 'soil_dataset_gallery_screen.dart';

enum CameraCaptureMode { photo, video }
enum HudDisplayMode { sensor8in1, multimodalAi }

class SoilCameraScreen extends StatefulWidget {
  const SoilCameraScreen({super.key});

  @override
  State<SoilCameraScreen> createState() => _SoilCameraScreenState();
}

class _SoilCameraScreenState extends State<SoilCameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isProcessingCapture = false;

  CameraCaptureMode _captureMode = CameraCaptureMode.photo;
  HudDisplayMode _hudMode = HudDisplayMode.multimodalAi;
  bool _isRecordingVideo = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  bool _isAudioEnabled = true;

  int _savedDatasetCount = 0;
  RoiShape _currentRoiShape = RoiShape.rectangle;
  Map<String, dynamic> _currentRoiData = {};

  // ตัวแปรควบคุมการวิเคราะห์สด (Live Multimodal Stream Analysis)
  bool _isStreaming = false;
  bool _isProcessingFrame = false;
  DateTime _lastFrameTime = DateTime.now();
  MultiColorMetric? _currentVisionMetric;
  MultimodalInferenceResult? _currentMultimodalResult;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _refreshDatasetCount();
  }

  Future<void> _refreshDatasetCount() async {
    final count = await SoilDatasetService.getSampleCount();
    if (mounted) setState(() => _savedDatasetCount = count);
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        debugPrint('[SoilCameraScreen] No cameras found on device');
        return;
      }

      _selectedCameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;

      await _setupCameraController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      debugPrint('[SoilCameraScreen] Error initializing cameras $e');
    }
  }

  Future<void> _setupCameraController(CameraDescription camera) async {
    if (_isStreaming && _cameraController != null) {
      try {
        await _cameraController!.stopImageStream();
      } catch (_) {}
      _isStreaming = false;
    }

    await _cameraController?.dispose();

    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: _isAudioEnabled,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _cameraController = controller;
          _isCameraInitialized = true;
        });

        // เริ่มวิเคราะห์เฟรมกล้องสดถ้าไม่ได้กำลังบันทึกวิดีโอ
        if (!_isRecordingVideo) {
          _startLiveStreamAnalysis();
        }
      }
    } catch (e) {
      debugPrint('[SoilCameraScreen] Camera setup error $e');
    }
  }

  void _startLiveStreamAnalysis() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_isStreaming || _isRecordingVideo) return;

    try {
      _isStreaming = true;
      _cameraController!.startImageStream((CameraImage image) {
        final now = DateTime.now();
        // วิเคราะห์ทุก 160 ms เพื่อรักษาความลื่นไหล 60 FPS
        if (_isProcessingFrame || now.difference(_lastFrameTime).inMilliseconds < 160) {
          return;
        }

        _isProcessingFrame = true;
        _lastFrameTime = now;
        _processLiveFrame(image);
      });
    } catch (e) {
      debugPrint('[SoilCameraScreen] Stream error $e');
      _isStreaming = false;
    }
  }

  Future<void> _stopLiveStreamAnalysis() async {
    if (_cameraController != null && _isStreaming) {
      try {
        await _cameraController!.stopImageStream();
      } catch (_) {}
      _isStreaming = false;
    }
  }

  void _processLiveFrame(CameraImage image) {
    try {
      if (!mounted) {
        _isProcessingFrame = false;
        return;
      }

      final vm = Provider.of<SoilSensorViewModel>(context, listen: false);
      final sensorReading = vm.calibrationResult.calibratedReading;

      final int width = image.width;
      final int height = image.height;

      // คำนวณพิกัดกึ่งกลางและขนาดของพื้นที่ ROI
      final renderBox = context.findRenderObject() as RenderBox?;
      final screenSize = renderBox?.size ?? const Size(400, 800);

      int centerX = width ~/ 2;
      int centerY = height ~/ 2;
      int sampleRadius = 24;

      if (_currentRoiData.isNotEmpty) {
        final scaleX = width / screenSize.width;
        final scaleY = height / screenSize.height;

        final double cX = (_currentRoiData['centerX'] as num?)?.toDouble() ?? (screenSize.width / 2);
        final double cY = (_currentRoiData['centerY'] as num?)?.toDouble() ?? (screenSize.height * 0.4);
        centerX = (cX * scaleX).toInt().clamp(10, width - 10);
        centerY = (cY * scaleY).toInt().clamp(10, height - 10);

        final double w = (_currentRoiData['width'] as num?)?.toDouble() ?? 200.0;
        sampleRadius = (w * scaleX * 0.25).toInt().clamp(8, 60);
      }

      final planeY = image.planes[0];
      final planeU = image.planes[1];
      final planeV = image.planes[2];

      final uvRowStride = planeU.bytesPerRow;
      final uvPixelStride = planeU.bytesPerPixel ?? 1;

      int totalR = 0;
      int totalG = 0;
      int totalB = 0;
      int pixelCount = 0;

      final int startY = (centerY - sampleRadius).clamp(0, height - 1);
      final int endY = (centerY + sampleRadius).clamp(0, height - 1);
      final int startX = (centerX - sampleRadius).clamp(0, width - 1);
      final int endX = (centerX + sampleRadius).clamp(0, width - 1);

      for (int y = startY; y <= endY; y += 2) {
        final int yOffset = y * planeY.bytesPerRow;
        final int uvYOffset = (y ~/ 2) * uvRowStride;

        for (int x = startX; x <= endX; x += 2) {
          final int yVal = planeY.bytes[yOffset + x];
          final int uvIndex = uvYOffset + (x ~/ 2) * uvPixelStride;

          final int uVal = planeU.bytes[uvIndex];
          final int vVal = planeV.bytes[uvIndex];

          // สูตรแปลงมาตรฐาน YUV420 to RGB (ITU-R BT.601)
          int r = (yVal + (1.402 * (vVal - 128))).round();
          int g = (yVal - (0.344136 * (uVal - 128)) - (0.714136 * (vVal - 128))).round();
          int b = (yVal + (1.772 * (uVal - 128))).round();

          totalR += r.clamp(0, 255);
          totalG += g.clamp(0, 255);
          totalB += b.clamp(0, 255);
          pixelCount++;
        }
      }

      if (pixelCount > 0 && mounted) {
        final int avgR = totalR ~/ pixelCount;
        final int avgG = totalG ~/ pixelCount;
        final int avgB = totalB ~/ pixelCount;

        final metric = MultiColorSpaceService.fromRgb(avgR, avgG, avgB);
        final inference = SoilMultimodalDeepModel.infer(
          visionMetric: metric,
          sensorReading: sensorReading,
        );

        setState(() {
          _currentVisionMetric = metric;
          _currentMultimodalResult = inference;
        });
      }
    } catch (e) {
      debugPrint('[SoilCameraScreen] Frame analysis error $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  Future<void> _toggleAudio() async {
    final lang = context.read<LanguageProvider>();
    if (_isRecordingVideo) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(lang.currentLanguage == AppLanguage.chinese
              ? '请在切换声音模式前先停止录制视频'
              : (lang.currentLanguage == AppLanguage.english
                  ? 'Please stop video recording before toggling audio mode'
                  : 'กรุณาหยุดบันทึกวิดีโอก่อนเปลี่ยนโหมดเสียง')),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isAudioEnabled = !_isAudioEnabled;
      _isCameraInitialized = false;
    });

    if (_cameras.isNotEmpty) {
      await _setupCameraController(_cameras[_selectedCameraIndex]);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _isAudioEnabled ? Colors.teal.shade900 : Colors.blueGrey.shade900,
          content: Row(
            children: [
              Icon(
                _isAudioEnabled ? Icons.mic : Icons.mic_off,
                color: _isAudioEnabled ? Colors.greenAccent : Colors.orangeAccent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isAudioEnabled ? lang.t('micOnDesc') : lang.t('micOffDesc'),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    setState(() => _isCameraInitialized = false);
    await _setupCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _capturePhoto(SoilSensorViewModel vm) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessingCapture) return;

    final lang = context.read<LanguageProvider>();
    setState(() => _isProcessingCapture = true);

    try {
      final wasStreaming = _isStreaming;
      if (wasStreaming) {
        await _stopLiveStreamAnalysis();
      }

      final photo = await _cameraController!.takePicture();

      if (wasStreaming && mounted && !_isRecordingVideo) {
        _startLiveStreamAnalysis();
      }

      final savedPath = await SoilDatasetService.savePhotoSample(
        photo: photo,
        rawReading: vm.rawReading,
        calibrated: vm.calibrationResult,
        location: vm.currentLocation,
      );

      await _refreshDatasetCount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.teal.shade900,
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.greenAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${lang.t('photoSavedNotice')} (${savedPath.split('/').last})',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: lang.t('viewGallery'),
              textColor: Colors.cyanAccent,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SoilDatasetGalleryScreen()),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[SoilCameraScreen] Error taking photo $e');
    } finally {
      if (mounted) setState(() => _isProcessingCapture = false);
    }
  }

  Future<void> _toggleVideoRecording(SoilSensorViewModel vm) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    final lang = context.read<LanguageProvider>();
    if (_isRecordingVideo) {
      // หยุดการบันทึกวิดีโอ
      _recordingTimer?.cancel();
      try {
        final video = await _cameraController!.stopVideoRecording();
        final duration = _recordingSeconds;
        setState(() {
          _isRecordingVideo = false;
          _recordingSeconds = 0;
          _isProcessingCapture = true;
        });

        // เริ่มวิเคราะห์เฟรมกล้องสดอีกครั้ง
        if (mounted) {
          _startLiveStreamAnalysis();
        }

        final savedPath = await SoilDatasetService.saveVideoSample(
          video: video,
          rawReading: vm.rawReading,
          calibrated: vm.calibrationResult,
          durationSeconds: duration,
          location: vm.currentLocation,
        );

        await _refreshDatasetCount();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.teal.shade900,
              content: Text('${lang.t('videoSavedNotice')} (${duration}s) ${savedPath.split('/').last}'),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: lang.t('viewGallery'),
                textColor: Colors.cyanAccent,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SoilDatasetGalleryScreen()),
                  );
                },
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('[SoilCameraScreen] Error stopping video $e');
      } finally {
        if (mounted) setState(() => _isProcessingCapture = false);
      }
    } else {
      // เริ่มการบันทึกวิดีโอ
      try {
        await _stopLiveStreamAnalysis();
        await _cameraController!.startVideoRecording();
        setState(() {
          _isRecordingVideo = true;
          _recordingSeconds = 0;
        });
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() => _recordingSeconds++);
        });
      } catch (e) {
        debugPrint('[SoilCameraScreen] Error starting video $e');
      }
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final vm = context.watch<SoilSensorViewModel>();
    final reading = vm.displayReading;
    final location = vm.currentLocation;
    final aiResult = _currentMultimodalResult;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        bottom: true,
        child: Stack(
          children: [
            // 1. Live Camera Viewfinder or Fallback
            Positioned.fill(
              child: _isCameraInitialized && _cameraController != null
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _cameraController!.value.previewSize?.height ?? 1,
                        height: _cameraController!.value.previewSize?.width ?? 1,
                        child: CameraPreview(_cameraController!),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: Colors.cyanAccent),
                          const SizedBox(height: 16),
                          Text(
                            lang.currentLanguage == AppLanguage.chinese
                                ? '正在启动 AI 视觉摄像头...'
                                : (lang.currentLanguage == AppLanguage.english
                                    ? 'Starting AI Vision Camera...'
                                    : 'กำลังเปิดกล้อง AI Vision...'),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
            ),

            // 2. Interactive Multi-Shape ROI Targeting Overlay (Rectangle, Circle, Freehand Polygon) พร้อมแถบเกณฑ์เฉดสีตามคู่มือวิชาการ
            Positioned.fill(
              child: InteractiveRoiSelector(
                currentShape: _currentRoiShape,
                isRecording: _isRecordingVideo,
                livePh: aiResult?.visionPh ?? reading.ph,
                liveSom: aiResult?.soilOrganicMatterPct,
                liveNitrogen: aiResult?.predictedNitrogen ?? reading.nitrogen,
                livePhosphorus: aiResult?.predictedPhosphorus ?? reading.phosphorus,
                livePotassium: aiResult?.predictedPotassium ?? reading.potassium,
                liveColorMetric: _currentVisionMetric,
                liveStatusLabel: aiResult?.agronomicInsight,
                onShapeChanged: (shape) => setState(() => _currentRoiShape = shape),
                onRoiUpdated: (data) => _currentRoiData = data,
              ),
            ),

            // 3. Top HUD: Back Button, GPS Coordinates, Audio Toggle, and Probe Status
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              right: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text(
                                '🌱 JC SOIL AI ANALYZER  |  SciRBRU AgriPhysics',
                                style: TextStyle(
                                  color: Color(0xFF00FFFF),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.amberAccent, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location.formattedCoordinates,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.terrain, color: Colors.cyanAccent, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                '${lang.t('altitude')} ${location.formattedAltitude} (MSL)',
                                style: const TextStyle(color: Colors.cyanAccent, fontSize: 10.5),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: vm.status == UsbConnectionStatus.connected
                                      ? Colors.green.withValues(alpha: 0.3)
                                      : Colors.amber.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  vm.status == UsbConnectionStatus.connected ? lang.t('probeLive') : lang.t('demoOffline'),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: vm.status == UsbConnectionStatus.connected ? Colors.greenAccent : Colors.amberAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Audio Toggle Button (Mic On / External Noise Suppression)
                  CircleAvatar(
                    backgroundColor: _isAudioEnabled ? Colors.black54 : Colors.redAccent.withValues(alpha: 0.85),
                    child: IconButton(
                      tooltip: _isAudioEnabled ? lang.t('micOnDesc') : lang.t('micOffDesc'),
                      icon: Icon(
                        _isAudioEnabled ? Icons.mic : Icons.mic_off,
                        color: _isAudioEnabled ? Colors.greenAccent : Colors.white,
                        size: 20,
                      ),
                      onPressed: _toggleAudio,
                    ),
                  ),
                ],
              ),
            ),

            // 4. Live Recording Indicator (When in Video Mode)
            if (_isRecordingVideo)
              Positioned(
                top: MediaQuery.of(context).padding.top + 70,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fiber_manual_record, color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'REC ${_recordingSeconds.toString().padLeft(2, '0')}s',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 1,
                          height: 12,
                          color: Colors.white38,
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _isAudioEnabled ? Icons.mic : Icons.mic_off,
                          color: _isAudioEnabled ? Colors.greenAccent : Colors.yellowAccent,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isAudioEnabled ? lang.t('micOn') : lang.t('micOff'),
                          style: TextStyle(
                            color: _isAudioEnabled ? Colors.white : Colors.yellowAccent,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 5. Bottom HUD: Switchable between Sensor 8-in-1 and Multimodal AI Deep Learning
            Positioned(
              left: 12,
              right: 12,
              bottom: 116,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xF20A0F1D), // Cyber Dark
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _hudMode == HudDisplayMode.multimodalAi
                        ? (aiResult?.statusColor ?? Colors.cyanAccent).withValues(alpha: 0.6)
                        : Colors.cyanAccent.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Bar with Mode Toggle Tab
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _hudMode == HudDisplayMode.multimodalAi ? Icons.psychology_rounded : Icons.sensors_rounded,
                              size: 16,
                              color: _hudMode == HudDisplayMode.multimodalAi ? Colors.cyanAccent : Colors.greenAccent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _hudMode == HudDisplayMode.multimodalAi
                                  ? 'AI MULTIMODAL VISION FUSION'
                                  : 'PHYSICAL SENSOR 8-IN-1',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        // Switch HUD Mode Button
                        InkWell(
                          onTap: () {
                            setState(() {
                              _hudMode = _hudMode == HudDisplayMode.multimodalAi
                                  ? HudDisplayMode.sensor8in1
                                  : HudDisplayMode.multimodalAi;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24, width: 0.8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _hudMode == HudDisplayMode.multimodalAi ? 'ดูเซนเซอร์ 8-in-1' : 'ดู AI Vision',
                                  style: const TextStyle(fontSize: 9.5, color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 3),
                                const Icon(Icons.swap_horiz_rounded, size: 13, color: Colors.cyanAccent),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const Divider(color: Colors.white12, height: 10),

                    // Content View A: Multimodal AI Deep Learning Analysis
                    if (_hudMode == HudDisplayMode.multimodalAi && aiResult != null) ...[
                      Row(
                        children: [
                          // Col 1: Sensor pH vs Vision pH (Side by Side)
                          Expanded(
                            flex: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF131B2E),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('เปรียบเทียบ pH (Sensor / Vision)', style: TextStyle(fontSize: 8.5, color: Colors.white60)),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${aiResult.sensorPh.toStringAsFixed(2)} pH',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                                      ),
                                      const Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.white38),
                                      Text(
                                        '${aiResult.visionPh.toStringAsFixed(2)} pH',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: aiResult.statusColor),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Δ ${aiResult.deltaPh.toStringAsFixed(2)} pH | สอดคล้อง ${(aiResult.consistencyScore * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(fontSize: 8.5, color: aiResult.statusColor, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Col 2: Soil Organic Matter SOM (%)
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF131B2E),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('อินทรียวัตถุ SOM', style: TextStyle(fontSize: 8.5, color: Colors.white60)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${aiResult.soilOrganicMatterPct.toStringAsFixed(1)} %',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)),
                                  ),
                                  Text(
                                    aiResult.soilOrganicMatterPct >= 3.0 ? 'ดินสมบูรณ์สูง' : (aiResult.soilOrganicMatterPct >= 1.8 ? 'ดินปานกลาง' : 'ดินอินทรีย์ต่ำ'),
                                    style: const TextStyle(fontSize: 8.5, color: Colors.white54),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Col 3: Live Color Swatch & Metrics
                          if (_currentVisionMetric != null)
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF131B2E),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: _currentVisionMetric!.toColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.2),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _currentVisionMetric!.hexString,
                                    style: const TextStyle(fontSize: 7.5, color: Colors.white70, fontFamily: 'monospace'),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Predicted NPK Fusion Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildHudChip('AI N (ไนโตรเจน)', '${aiResult.predictedNitrogen} mg/kg', const Color(0xFFFF7043)),
                          _buildHudChip('AI P (ฟอสฟอรัส)', '${aiResult.predictedPhosphorus} mg/kg', const Color(0xFF42A5F5)),
                          _buildHudChip('AI K (โพแทสเซียม)', '${aiResult.predictedPotassium} mg/kg', const Color(0xFFAB47BC)),
                          _buildHudChip('ความชื้น VWC', '${reading.moisture.toStringAsFixed(1)}%', Colors.cyanAccent),
                        ],
                      ),
                    ] else ...[
                      // Content View B: Standard 8-in-1 Sensor Telemetry
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildHudChip(lang.t('moisture'), '${reading.moisture.toStringAsFixed(1)} %', Colors.blueAccent),
                          _buildHudChip(lang.t('temperature'), '${reading.temperature.toStringAsFixed(1)} °C', Colors.amberAccent),
                          _buildHudChip('EC', '${reading.conductivity}', Colors.purpleAccent),
                          _buildHudChip('pH', reading.ph.toStringAsFixed(2), Colors.greenAccent),
                        ],
                      ),
                      const Divider(color: Colors.white12, height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildHudChip(lang.t('nitrogen'), '${reading.nitrogen} mg/kg', Colors.cyanAccent),
                          _buildHudChip(lang.t('phosphorus'), '${reading.phosphorus} mg/kg', Colors.orangeAccent),
                          _buildHudChip(lang.t('potassium'), '${reading.potassium} mg/kg', Colors.pinkAccent),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // 6. Camera Controls: Mode Selector, Big Shutter Button, Switch Camera
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Mode Selector (Photo / Video)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_isRecordingVideo) return;
                          setState(() => _captureMode = CameraCaptureMode.photo);
                        },
                        child: Text(
                          lang.t('photoMode'),
                          style: TextStyle(
                            color: _captureMode == CameraCaptureMode.photo ? Colors.cyanAccent : Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: () {
                          if (_isRecordingVideo) return;
                          setState(() => _captureMode = CameraCaptureMode.video);
                        },
                        child: Text(
                          lang.t('videoMode'),
                          style: TextStyle(
                            color: _captureMode == CameraCaptureMode.video ? Colors.redAccent : Colors.white54,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Action Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Dataset Samples Gallery Shortcut Button
                      GestureDetector(
                        onTap: () async {
                          if (_isRecordingVideo) return;
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SoilDatasetGalleryScreen()),
                          );
                          _refreshDatasetCount();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Icons.photo_library, color: Colors.white70, size: 24),
                              if (_savedDatasetCount > 0)
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.cyanAccent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$_savedDatasetCount',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Big Shutter Button
                      GestureDetector(
                        onTap: _isProcessingCapture
                            ? null
                            : () {
                                if (_captureMode == CameraCaptureMode.photo) {
                                  _capturePhoto(vm);
                                } else {
                                  _toggleVideoRecording(vm);
                                }
                              },
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _captureMode == CameraCaptureMode.video ? Colors.redAccent : Colors.cyanAccent,
                              width: 3.5,
                            ),
                            color: _isRecordingVideo
                                ? Colors.red
                                : (_captureMode == CameraCaptureMode.video ? Colors.redAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Center(
                            child: _isProcessingCapture
                                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                : Icon(
                                    _captureMode == CameraCaptureMode.video
                                        ? (_isRecordingVideo ? Icons.stop : Icons.videocam)
                                        : Icons.camera_alt,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                          ),
                        ),
                      ),

                      // Switch Camera Button
                      IconButton(
                        icon: const Icon(Icons.flip_camera_android, color: Colors.white70, size: 26),
                        onPressed: _isRecordingVideo ? null : _switchCamera,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHudChip(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 9.0),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
        ),
      ],
    );
  }
}
