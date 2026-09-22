import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/ph_colors.dart';
import '../../core/services/multi_color_space_service.dart';
import '../../core/services/optical_ph_estimator.dart';
import '../../data/services/soil_dataset_service.dart';
import '../viewmodels/ph_monitor_viewmodel.dart';
import '../widgets/interactive_roi_selector.dart';
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

  // โหมดการทำงาน (Live Video Real-Time vs Still Photo)
  bool _isLiveAnalysisEnabled = true;
  bool _isProcessingFrame = false;
  bool _isStreaming = false;
  DateTime _lastFrameProcessedTime = DateTime.now();

  // สถานะการเลือกพื้นที่ ROI
  RoiShape _currentRoiShape = RoiShape.rectangle;
  RoiData? _currentRoiData;

  // ผลการวิเคราะห์สีและค่า pH เชิงแสง
  MultiColorMetric? _liveColorMetric;
  PhComparisonResult? _comparisonResult;

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
      debugPrint('[SoilCameraScreen] Camera init error $e');
    }
  }

  Future<void> _setupController(CameraDescription camera) async {
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
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await controller.initialize();
      await controller.setFlashMode(_flashMode);
      if (mounted) {
        setState(() {
          _cameraController = controller;
          _isCameraInitialized = true;
        });

        if (_isLiveAnalysisEnabled) {
          _startLiveAnalysisStream();
        }
      }
    } catch (e) {
      debugPrint('[SoilCameraScreen] Controller setup error $e');
    }
  }

  void _startLiveAnalysisStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_isStreaming) return;

    try {
      _isStreaming = true;
      _cameraController!.startImageStream((CameraImage image) {
        final now = DateTime.now();
        // ประมวลผลเฟรมทุกๆ 150 ms เพื่อความลื่นไหลระดับ 60 FPS ของ UI
        if (_isProcessingFrame || now.difference(_lastFrameProcessedTime).inMilliseconds < 150) {
          return;
        }

        _isProcessingFrame = true;
        _lastFrameProcessedTime = now;
        _analyzeCameraFrame(image);
      });
    } catch (e) {
      debugPrint('[SoilCameraScreen] Start stream error $e');
      _isStreaming = false;
    }
  }

  Future<void> _stopLiveAnalysisStream() async {
    if (_cameraController != null && _isStreaming) {
      try {
        await _cameraController!.stopImageStream();
      } catch (_) {}
      _isStreaming = false;
    }
  }

  void _analyzeCameraFrame(CameraImage image) {
    try {
      if (!mounted) {
        _isProcessingFrame = false;
        return;
      }

      final vm = Provider.of<PhMonitorViewModel>(context, listen: false);
      final double sensorPh = vm.calibratedResult.phCalibrated;

      final int width = image.width;
      final int height = image.height;

      // แปลงพิกัด ROI บนหน้าจอเป็นพิกัดใน Image Frame
      final renderBox = context.findRenderObject() as RenderBox?;
      final screenSize = renderBox?.size ?? const Size(400, 800);

      final roi = _currentRoiData;
      int centerX = width ~/ 2;
      int centerY = height ~/ 2;
      int sampleRadius = 24;

      if (roi != null) {
        // อัตราส่วนการแปลงขนาดจอภาพเป็นขนาดภาพจากเซนเซอร์กล้อง
        final scaleX = width / screenSize.width;
        final scaleY = height / screenSize.height;
        centerX = (roi.center.dx * scaleX).toInt().clamp(10, width - 10);
        centerY = (roi.center.dy * scaleY).toInt().clamp(10, height - 10);

        if (roi.shape == RoiShape.circle) {
          sampleRadius = (roi.radius * scaleX * 0.4).toInt().clamp(8, 60);
        } else {
          sampleRadius = (roi.width * scaleX * 0.25).toInt().clamp(8, 60);
        }
      }

      // สุ่มตัวอย่างพิกเซลในพื้นที่ ROI จาก YUV420 Planes
      final planeY = image.planes[0];
      final planeU = image.planes[1];
      final planeV = image.planes[2];

      final uvRowStride = planeU.bytesPerRow;
      final uvPixelStride = planeU.bytesPerPixel ?? 1;

      int totalR = 0;
      int totalG = 0;
      int totalB = 0;
      int count = 0;

      final int startY = (centerY - sampleRadius).clamp(0, height - 1);
      final int endY = (centerY + sampleRadius).clamp(0, height - 1);
      final int startX = (centerX - sampleRadius).clamp(0, width - 1);
      final int endX = (centerX + sampleRadius).clamp(0, width - 1);

      // ก้าวข้ามพิกเซลทีละ 2 เพื่อความรวดเร็วในการประมวลผล
      for (int y = startY; y <= endY; y += 2) {
        final int yOffset = y * planeY.bytesPerRow;
        final int uvYOffset = (y ~/ 2) * uvRowStride;

        for (int x = startX; x <= endX; x += 2) {
          final int yVal = planeY.bytes[yOffset + x];
          final int uvIndex = uvYOffset + (x ~/ 2) * uvPixelStride;

          final int uVal = planeU.bytes[uvIndex];
          final int vVal = planeV.bytes[uvIndex];

          // สูตรแปลง YUV เป็น RGB (ITU-R BT.601)
          int r = (yVal + (1.402 * (vVal - 128))).round();
          int g = (yVal - (0.344136 * (uVal - 128)) - (0.714136 * (vVal - 128))).round();
          int b = (yVal + (1.772 * (uVal - 128))).round();

          totalR += r.clamp(0, 255);
          totalG += g.clamp(0, 255);
          totalB += b.clamp(0, 255);
          count++;
        }
      }

      if (count > 0 && mounted) {
        final int avgR = totalR ~/ count;
        final int avgG = totalG ~/ count;
        final int avgB = totalB ~/ count;

        final metric = MultiColorSpaceService.fromRgb(avgR, avgG, avgB);
        final comparison = OpticalPhEstimator.compare(
          currentMetric: metric,
          sensorPh: sensorPh,
        );

        setState(() {
          _liveColorMetric = metric;
          _comparisonResult = comparison;
        });
      }
    } catch (e) {
      debugPrint('[SoilCameraScreen] Frame processing error $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  Future<void> _toggleLiveAnalysis() async {
    setState(() {
      _isLiveAnalysisEnabled = !_isLiveAnalysisEnabled;
    });

    if (_isLiveAnalysisEnabled) {
      _startLiveAnalysisStream();
    } else {
      await _stopLiveAnalysisStream();
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
      // หยุด Image Stream ชั่วคราวก่อนจับภาพนิ่ง
      final wasStreaming = _isStreaming;
      if (wasStreaming) {
        await _stopLiveAnalysisStream();
      }

      Uint8List imageBytes;
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final xFile = await _cameraController!.takePicture();
        imageBytes = await xFile.readAsBytes();
      } else {
        imageBytes = Uint8List(0);
      }

      // เริ่ม Image Stream ใหม่อีกครั้งถ้าเปิดโหมด Live
      if (wasStreaming && _isLiveAnalysisEnabled) {
        _startLiveAnalysisStream();
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
                  const Icon(Icons.check_circle_rounded, color: PhColors.neonGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'บันทึกภาพพร้อมข้อมูลเปรียบเทียบและ GPS แล้ว (${record.id})',
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
            content: Text('เกิดข้อผิดพลาดในการบันทึกภาพ $e'),
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
    final comparison = _comparisonResult;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. กล้องถ่ายภาพสด (Camera Preview)
          if (_isCameraInitialized && _cameraController != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? 1,
                  height: _cameraController!.value.previewSize?.width ?? 1,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: PhColors.neonGreen),
            ),

          // 2. ตัวเลือกพื้นที่วิเคราะห์ ROI (Interactive Multi-Shape ROI Overlay)
          Positioned.fill(
            child: InteractiveRoiSelector(
              currentShape: _currentRoiShape,
              activeColor: comparison != null ? comparison.statusColor : PhColors.neonCyan,
              onShapeChanged: (shape) {
                setState(() => _currentRoiShape = shape);
              },
              onRoiUpdated: (roi) {
                _currentRoiData = roi;
              },
            ),
          ),

          // 3. แถบควบคุมด้านบน (Top Action Bar)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ปุ่มย้อนกลับ
                  _buildCircleBtn(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),

                  // ป้ายแสดงสถานะ Live Analysis
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isLiveAnalysisEnabled
                          ? const Color(0xE60A0F1D)
                          : Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isLiveAnalysisEnabled ? PhColors.neonGreen : Colors.white24,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isLiveAnalysisEnabled ? PhColors.neonGreen : Colors.grey,
                            boxShadow: _isLiveAnalysisEnabled
                                ? [
                                    BoxShadow(
                                      color: PhColors.neonGreen.withValues(alpha: 0.8),
                                      blurRadius: 6,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isLiveAnalysisEnabled ? 'LIVE VISION' : 'STILL MODE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: _isLiveAnalysisEnabled ? PhColors.neonGreen : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // กลุ่มปุ่มควบคุมกล้อง (สลับโหมด Live, แฟลช, สลับกล้องหน้าหลัง)
                  Row(
                    children: [
                      _buildCircleBtn(
                        icon: _isLiveAnalysisEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                        color: _isLiveAnalysisEnabled ? PhColors.neonGreen : Colors.white70,
                        onTap: _toggleLiveAnalysis,
                      ),
                      const SizedBox(width: 8),
                      _buildCircleBtn(
                        icon: _flashMode == FlashMode.torch ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        color: _flashMode == FlashMode.torch ? PhColors.neonAmber : Colors.white70,
                        onTap: _toggleFlash,
                      ),
                      if (_cameras.length > 1) ...[
                        const SizedBox(width: 8),
                        _buildCircleBtn(
                          icon: Icons.flip_camera_ios_rounded,
                          onTap: _switchCamera,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 4. แผงวิเคราะห์และเปรียบเทียบค่าแบบเรียลไทม์ (Live Sensor vs. Vision HUD Panel)
          Positioned(
            left: 14,
            right: 14,
            bottom: 16,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // กล่องเปรียบเทียบค่าเซนเซอร์โพรบกับค่าวิเคราะห์จากกล้อง
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xF00A0F1D), // Cyber Dark
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: comparison != null ? comparison.statusColor.withValues(alpha: 0.6) : PhColors.cardBorder,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // หัวข้อและสถานะความสอดคล้อง
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.compare_arrows_rounded, color: PhColors.neonCyan, size: 18),
                                const SizedBox(width: 6),
                                const Text(
                                  'เปรียบเทียบเซนเซอร์และภาพถ่าย Live',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            if (comparison != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: comparison.statusColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: comparison.statusColor, width: 1),
                                ),
                                child: Text(
                                  'Δ ${comparison.deltaPh.toStringAsFixed(2)} pH',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: comparison.statusColor,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // คอลัมน์คู่แสดงค่า Sensor pH เทียบกับ Vision Optical pH
                        Row(
                          children: [
                            // ฝั่งซ้าย ค่าจากเซนเซอร์โพรบ
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: PhColors.surface.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: PhColors.neonCyan.withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('เซนเซอร์โพรบ (Probe)', style: TextStyle(fontSize: 10, color: Colors.white60)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${result.phCalibrated.toStringAsFixed(2)} pH',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: PhColors.getColorForPh(result.phCalibrated),
                                      ),
                                    ),
                                    Text(
                                      'T ${result.rawReading.temperature.toStringAsFixed(1)}°C | H ${result.rawReading.moisture.toStringAsFixed(1)}%',
                                      style: const TextStyle(fontSize: 9, color: Colors.white54),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            // ฝั่งขวา ค่าจากการวิเคราะห์ภาพถ่าย Live
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: PhColors.surface.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: comparison != null ? comparison.statusColor.withValues(alpha: 0.4) : PhColors.cardBorder,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('ภาพถ่าย Live (Vision)', style: TextStyle(fontSize: 10, color: Colors.white60)),
                                        if (_liveColorMetric != null)
                                          Container(
                                            width: 12,
                                            height: 12,
                                            decoration: BoxDecoration(
                                              color: _liveColorMetric!.toColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 1),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      comparison != null
                                          ? '${comparison.visionPh.toStringAsFixed(2)} pH'
                                          : 'กำลังประมวลผล',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: comparison != null
                                            ? PhColors.getColorForPh(comparison.visionPh)
                                            : Colors.white38,
                                      ),
                                    ),
                                    Text(
                                      _liveColorMetric != null
                                          ? 'H ${_liveColorMetric!.hue.toStringAsFixed(0)}° | L* ${_liveColorMetric!.labL.toStringAsFixed(0)}'
                                          : 'สแกนพื้นที่เป้าหมาย',
                                      style: const TextStyle(fontSize: 9, color: Colors.white54),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (comparison != null) ...[
                          const SizedBox(height: 8),
                          // แถบประเมินระดับความสอดคล้อง
                          Row(
                            children: [
                              Icon(Icons.verified_rounded, size: 13, color: comparison.statusColor),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  comparison.agreementStatus,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: comparison.statusColor,
                                  ),
                                ),
                              ),
                              
                                Text(
                                  'GPS ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                                  style: const TextStyle(fontSize: 9, color: Colors.white38),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ปุ่มถ่ายภาพ บันทึก และคลังข้อมูล
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // ปุ่มคลังภาพ
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SoilDatasetGalleryScreen()),
                          ).then((_) => _refreshCount());
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: PhColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: PhColors.cardBorder),
                              ),
                              child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 24),
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

                      // ปุ่มชัตเตอร์ถ่ายภาพพร้อม HUD ข้อมูล
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
                                color: PhColors.neonGreen.withValues(alpha: 0.5),
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
                              : const Icon(Icons.camera_alt_rounded, size: 34, color: Colors.black),
                        ),
                      ),

                      // ป้ายแสดงจำนวนแถบสีอ้างอิงมาตรฐาน
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: PhColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: PhColors.cardBorder),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('7 TIERS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: PhColors.neonAmber)),
                            const Text('TABLE 2.3', style: TextStyle(fontSize: 8, color: Colors.white54)),
                          ],
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
    );
  }

  Widget _buildCircleBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}
