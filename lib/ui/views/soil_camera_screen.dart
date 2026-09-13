import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/localization/language_provider.dart';
import '../../data/services/soil_dataset_service.dart';
import '../../data/services/usb_sensor_service.dart';
import '../viewmodels/soil_sensor_viewmodel.dart';
import 'soil_dataset_gallery_screen.dart';

enum CameraCaptureMode { photo, video }

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
  bool _isRecordingVideo = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  bool _isAudioEnabled = true;

  int _savedDatasetCount = 0;

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

      // Default to back camera
      _selectedCameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;

      await _setupCameraController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      debugPrint('[SoilCameraScreen] Error initializing cameras: $e');
    }
  }

  Future<void> _setupCameraController(CameraDescription camera) async {
    await _cameraController?.dispose();

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: _isAudioEnabled,
    );

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _cameraController = controller;
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('[SoilCameraScreen] Camera setup error: $e');
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
      final photo = await _cameraController!.takePicture();
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
                    '${lang.t('photoSavedNotice')}: ${savedPath.split('/').last}',
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
      debugPrint('[SoilCameraScreen] Error taking photo: $e');
    } finally {
      if (mounted) setState(() => _isProcessingCapture = false);
    }
  }

  Future<void> _toggleVideoRecording(SoilSensorViewModel vm) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    final lang = context.read<LanguageProvider>();
    if (_isRecordingVideo) {
      // Stop Recording
      _recordingTimer?.cancel();
      try {
        final video = await _cameraController!.stopVideoRecording();
        final duration = _recordingSeconds;
        setState(() {
          _isRecordingVideo = false;
          _recordingSeconds = 0;
          _isProcessingCapture = true;
        });

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
              content: Text('${lang.t('videoSavedNotice')} (${duration}s): ${savedPath.split('/').last}'),
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
        debugPrint('[SoilCameraScreen] Error stopping video: $e');
      } finally {
        if (mounted) setState(() => _isProcessingCapture = false);
      }
    } else {
      // Start Recording
      try {
        await _cameraController!.startVideoRecording();
        setState(() {
          _isRecordingVideo = true;
          _recordingSeconds = 0;
        });
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() => _recordingSeconds++);
        });
      } catch (e) {
        debugPrint('[SoilCameraScreen] Error starting video: $e');
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

            // 2. Targeting HUD Crosshair Overlay
            Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isRecordingVideo ? Colors.redAccent.withValues(alpha: 0.8) : Colors.cyanAccent.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Corner accents
                    Positioned(
                      top: 4,
                      left: 8,
                      child: Text(
                        lang.t('soilTargetZone'),
                        style: TextStyle(
                          color: _isRecordingVideo ? Colors.redAccent : Colors.cyanAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Center(
                      child: Icon(
                        Icons.filter_center_focus,
                        size: 40,
                        color: (_isRecordingVideo ? Colors.redAccent : Colors.cyanAccent).withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
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
                          Row(
                            children: const [
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
                                '${lang.t('altitude')}: ${location.formattedAltitude} (MSL)',
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

            // 5. Bottom HUD: Real-Time Sensor Telemetry Overlay
            Positioned(
              left: 12,
              right: 12,
              bottom: 120,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildHudChip(lang.t('moisture'), '${reading.moisture.toStringAsFixed(1)} %', Colors.blueAccent),
                        _buildHudChip(lang.t('temperature'), '${reading.temperature.toStringAsFixed(1)} °C', Colors.amberAccent),
                        _buildHudChip('EC', '${reading.conductivity}', Colors.purpleAccent),
                        _buildHudChip('pH', reading.ph.toStringAsFixed(2), Colors.greenAccent),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildHudChip(lang.t('nitrogen'), '${reading.nitrogen} mg/kg', Colors.cyanAccent),
                        _buildHudChip(lang.t('phosphorus'), '${reading.phosphorus} mg/kg', Colors.orangeAccent),
                        _buildHudChip(lang.t('potassium'), '${reading.potassium} mg/kg', Colors.pinkAccent),
                      ],
                    ),
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
                        onTap: () => setState(() => _captureMode = CameraCaptureMode.photo),
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
                        onTap: () => setState(() => _captureMode = CameraCaptureMode.video),
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
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SoilDatasetGalleryScreen()),
                          );
                          _refreshDatasetCount();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.7)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withValues(alpha: 0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo_library, color: Colors.cyanAccent, size: 17),
                              const SizedBox(width: 4),
                              Text(
                                '$_savedDatasetCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Audio Mode Quick Toggle (Cut Ambient Noise / Voice Mic)
                      GestureDetector(
                        onTap: _toggleAudio,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isAudioEnabled ? Colors.black87 : Colors.red.shade900.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isAudioEnabled ? Colors.greenAccent.withValues(alpha: 0.7) : Colors.orangeAccent,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isAudioEnabled ? Icons.mic : Icons.mic_off,
                                color: _isAudioEnabled ? Colors.greenAccent : Colors.orangeAccent,
                                size: 17,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isAudioEnabled ? lang.t('micOn') : lang.t('micOff'),
                                style: TextStyle(
                                  color: _isAudioEnabled ? Colors.greenAccent : Colors.orangeAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
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
                        onPressed: _switchCamera,
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
          style: const TextStyle(color: Colors.white60, fontSize: 9.5),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
        ),
      ],
    );
  }
}
