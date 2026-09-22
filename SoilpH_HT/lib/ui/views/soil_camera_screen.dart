import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/ph_colors.dart';
import '../../data/services/soil_dataset_service.dart';
import '../viewmodels/ph_monitor_viewmodel.dart';
import 'soil_dataset_gallery_screen.dart';

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
  bool _isCapturing = false;
  FlashMode _flashMode = FlashMode.off;
  int _savedCount = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _refreshCount();
  }

  Future<void> _refreshCount() async {
    final count = await SoilDatasetService.getSampleCount();
    if (mounted) setState(() => _savedCount = count);
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      _selectedCameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;

      await _setupController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      debugPrint('[SoilCameraScreen] Camera init error: $e');
    }
  }

  Future<void> _setupController(CameraDescription camera) async {
    await _cameraController?.dispose();

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      await controller.setFlashMode(_flashMode);
      if (mounted) {
        setState(() {
          _cameraController = controller;
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('[SoilCameraScreen] Controller setup error: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    final newMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await _cameraController!.setFlashMode(newMode);
      setState(() => _flashMode = newMode);
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _setupController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    final vm = context.read<PhMonitorViewModel>();

    try {
      Uint8List imageBytes;
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final xFile = await _cameraController!.takePicture();
        imageBytes = await xFile.readAsBytes();
      } else {
        // Fallback for emulator without camera
        imageBytes = Uint8List(0);
      }

      if (imageBytes.isNotEmpty) {
        final record = await vm.captureAndSaveSoilPhoto(imageBytes);
        await _refreshCount();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: PhColors.cardBg,
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: PhColors.neonGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'บันทึกภาพพร้อม HUD & GPS แล้ว: ${record.id}',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: PhColors.neonRed,
            content: Text('เกิดข้อผิดพลาดในการบันทึกภาพ: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PhMonitorViewModel>();
    final result = vm.calibratedResult;
    final location = vm.currentLocation;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview (Responsive Auto-Fitting without overflow or distortion)
          if (_isCameraInitialized && _cameraController != null)
            ClipRect(
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _cameraController!.value.previewSize?.height ?? MediaQuery.of(context).size.width,
                    height: _cameraController!.value.previewSize?.width ?? MediaQuery.of(context).size.height,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
            )
          else
            Container(
              color: const Color(0xFF0F172A),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt, size: 56, color: Colors.white38),
                    SizedBox(height: 12),
                    Text(
                      'กำลังเปิดกล้อง AI Vision...\n(หรือกำลังทำงานบนโหมดจำลอง)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          // 2. Center Cyber Reticle (Auto-scale with smartphone screen size)
          LayoutBuilder(
            builder: (context, constraints) {
              final reticleSize = (constraints.maxWidth * 0.55).clamp(160.0, 240.0);
              return Center(
                child: Container(
                  width: reticleSize,
                  height: reticleSize,
                  decoration: BoxDecoration(
                    border: Border.all(color: PhColors.neonCyan.withOpacity(0.5), width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.add, size: 36, color: PhColors.neonGreen),
                      Positioned(
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '[ + ] SOIL pH TARGET',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: PhColors.neonCyan,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 3. Top Header Bar (Branding, GPS, Flash, Close)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 12,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🌱 SoilpH-HT AI Vision',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: PhColors.neonGreen,
                          ),
                        ),
                        Text(
                          location.summary,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.85),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _flashMode == FlashMode.torch ? Icons.flash_on : Icons.flash_off,
                      color: _flashMode == FlashMode.torch ? PhColors.neonAmber : Colors.white70,
                    ),
                    onPressed: _toggleFlash,
                  ),
                  if (_cameras.length > 1)
                    IconButton(
                      icon: const Icon(Icons.flip_camera_ios, color: Colors.white70),
                      onPressed: _switchCamera,
                    ),
                ],
              ),
            ),
          ),

          // 4. Bottom HUD Panel & Shutter Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black, Colors.black87, Colors.transparent],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Live Telemetry Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: PhColors.surface.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: PhColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              'pH ${result.phCalibrated.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: PhColors.getColorForPh(result.phCalibrated),
                              ),
                            ),
                            Text(
                              'Δ ${result.deltaPhTotal > 0 ? '+' : ''}${result.deltaPhTotal.toStringAsFixed(2)} PINN',
                              style: const TextStyle(fontSize: 10, color: Colors.white70),
                            ),
                          ],
                        ),
                        Container(width: 1, height: 28, color: PhColors.cardBorder),
                        Column(
                          children: [
                            Text(
                              '${result.rawReading.temperature.toStringAsFixed(1)}°C',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: PhColors.neonAmber,
                              ),
                            ),
                            const Text('อุณหภูมิ T', style: TextStyle(fontSize: 10, color: Colors.white60)),
                          ],
                        ),
                        Container(width: 1, height: 28, color: PhColors.cardBorder),
                        Column(
                          children: [
                            Text(
                              '${result.rawReading.moisture.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: PhColors.neonCyan,
                              ),
                            ),
                            const Text('ความชื้น H', style: TextStyle(fontSize: 10, color: Colors.white60)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Shutter Button & Gallery Shortcut
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery button
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SoilDatasetGalleryScreen()),
                          ).then((_) => _refreshCount());
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: PhColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: PhColors.cardBorder),
                              ),
                              child: const Icon(Icons.photo_library, color: Colors.white),
                            ),
                            if (_savedCount > 0)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: PhColors.neonGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$_savedCount',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Big Shutter Button
                      GestureDetector(
                        onTap: _isCapturing ? null : _capturePhoto,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            color: _isCapturing ? Colors.grey : PhColors.neonGreen,
                            boxShadow: [
                              BoxShadow(
                                color: PhColors.neonGreen.withOpacity(0.5),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: _isCapturing
                              ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.black,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.camera, size: 36, color: Colors.black),
                        ),
                      ),

                      // Placeholder to balance spacing
                      const SizedBox(width: 48),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
