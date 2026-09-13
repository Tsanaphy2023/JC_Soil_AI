import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../data/services/soil_dataset_service.dart';
import '../../data/services/usb_sensor_service.dart';
import '../viewmodels/soil_sensor_viewmodel.dart';

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

  int _savedDatasetCount = 0;
  String? _lastSavedNotice;

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
      enableAudio: true,
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

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    setState(() => _isCameraInitialized = false);
    await _setupCameraController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _capturePhoto(SoilSensorViewModel vm) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessingCapture) return;

    setState(() => _isProcessingCapture = true);
    try {
      final photo = await _cameraController!.takePicture();
      final savedPath = await SoilDatasetService.savePhotoSample(
        photo: photo,
        rawReading: vm.rawReading,
        calibrated: vm.calibrationResult,
      );

      await _refreshDatasetCount();

      if (mounted) {
        setState(() {
          _lastSavedNotice = 'บันทึกภาพและพิกัด GPS สำหรับเทรนโมเดลสำเร็จ';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.teal.shade900,
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.greenAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'บันทึกภาพชุดข้อมูลเรียบร้อย: ${savedPath.split('/').last}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
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
        );

        await _refreshDatasetCount();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.teal.shade900,
              content: Text('บันทึกวิดีโอเรียบร้อย (${duration}s): ${savedPath.split('/').last}'),
              duration: const Duration(seconds: 3),
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
                        children: const [
                          CircularProgressIndicator(color: Colors.cyanAccent),
                          SizedBox(height: 16),
                          Text('กำลังเปิดกล้อง AI Vision...', style: TextStyle(color: Colors.white70)),
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
                        'SOIL TARGET ZONE',
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

            // 3. Top HUD: Back Button, GPS Coordinates, and Probe Status
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
                            children: [
                              const Icon(Icons.location_on, color: Colors.amberAccent, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                location?.formattedCoordinates ?? 'GPS กำลังระบุพิกัด...',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
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
                                'Alt: ${location?.formattedAltitude ?? '-'} (MSL)',
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
                                  vm.status == UsbConnectionStatus.connected ? 'PROBE LIVE' : 'DEMO/OFFLINE',
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
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
                        _buildHudChip('ความชื้น', '${reading.moisture.toStringAsFixed(1)} %', Colors.blueAccent),
                        _buildHudChip('อุณหภูมิ', '${reading.temperature.toStringAsFixed(1)} °C', Colors.amberAccent),
                        _buildHudChip('EC', '${reading.conductivity}', Colors.purpleAccent),
                        _buildHudChip('pH', reading.ph.toStringAsFixed(2), Colors.greenAccent),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildHudChip('ไนโตรเจน (N)', '${reading.nitrogen} mg/kg', Colors.cyanAccent),
                        _buildHudChip('ฟอสฟอรัส (P)', '${reading.phosphorus} mg/kg', Colors.orangeAccent),
                        _buildHudChip('โพแทสเซียม (K)', '${reading.potassium} mg/kg', Colors.pinkAccent),
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
                          'PHOTO (ภาพถ่าย)',
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
                          'VIDEO (วิดีโอ LIVE)',
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
                      // Dataset Samples Count Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.dataset, color: Colors.greenAccent, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '$_savedDatasetCount Samples',
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
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
                        icon: const Icon(Icons.flip_camera_android, color: Colors.white70, size: 28),
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
