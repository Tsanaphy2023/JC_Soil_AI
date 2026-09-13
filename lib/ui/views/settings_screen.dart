import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/sensor_constants.dart';
import '../viewmodels/soil_sensor_viewmodel.dart';
import '../widgets/ai_model_details_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedBaud = SensorConstants.defaultBaudRate;
  final int _slaveId = SensorConstants.defaultSlaveId;
  bool _isExportingPdf = false;
  String? _savedPdfPath;

  @override
  void initState() {
    super.initState();
    _selectedBaud = context.read<SoilSensorViewModel>().baudRate;
  }

  Future<void> _downloadOrSharePdfManual({bool shareImmediately = false}) async {
    setState(() => _isExportingPdf = true);
    try {
      final byteData = await rootBundle.load('assets/docs/JC_Digital_Soil_AI_Beginner_Guide.pdf');
      final bytes = byteData.buffer.asUint8List();

      File targetFile;
      try {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (Platform.isAndroid && await downloadDir.exists()) {
          targetFile = File('${downloadDir.path}/JC_Digital_Soil_AI_Beginner_Guide.pdf');
        } else {
          final docsDir = await getApplicationDocumentsDirectory();
          targetFile = File('${docsDir.path}/JC_Digital_Soil_AI_Beginner_Guide.pdf');
        }
      } catch (_) {
        final tmpDir = Directory.systemTemp;
        targetFile = File('${tmpDir.path}/JC_Digital_Soil_AI_Beginner_Guide.pdf');
      }

      await targetFile.writeAsBytes(bytes, flush: true);
      setState(() {
        _isExportingPdf = false;
        _savedPdfPath = targetFile.path;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.teal.shade900,
          duration: const Duration(seconds: 6),
          content: Text(
            'บันทึกคู่มือ PDF สำเร็จ!\nจัดเก็บไว้ที่: ${targetFile.path}',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          action: SnackBarAction(
            label: 'เปิด / แชร์',
            textColor: Colors.cyanAccent,
            onPressed: () {
              Share.shareXFiles(
                [XFile(targetFile.path)],
                text: 'คู่มือการใช้งานระบบ JC Digital Soil AI Analyzer (ฉบับสมบูรณ์ PDF)',
              );
            },
          ),
        ),
      );

      if (shareImmediately) {
        await Share.shareXFiles(
          [XFile(targetFile.path)],
          text: 'คู่มือการใช้งานระบบ JC Digital Soil AI Analyzer (ฉบับสมบูรณ์ PDF)',
        );
      }
    } catch (e) {
      setState(() => _isExportingPdf = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade900,
          content: Text('เกิดข้อผิดพลาดในการดาวน์โหลดคู่มือ: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SoilSensorViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Sensor & Hardware Config',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.cardSurface,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Section 1: USB Serial Configuration
              const Text(
                'USB Serial Interface (Modbus RTU)',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                color: AppColors.cardSurface,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Baud Selector
                      const Text(
                        'เลือกความเร็วสื่อสาร (Baud Rate):',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: vm.baudRate == 4800 ? Colors.cyanAccent.shade700 : Colors.white10,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                setState(() => _selectedBaud = 4800);
                                vm.switchBaudRate(4800);
                              },
                              child: const Text('4800 bps (ค่ามาตรฐาน)'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: vm.baudRate == 9600 ? Colors.cyanAccent.shade700 : Colors.white10,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                setState(() => _selectedBaud = 9600);
                                vm.switchBaudRate(9600);
                              },
                              child: const Text('9600 bps (ความเร็วสูง)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Baud Rate อื่นๆ:',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          DropdownButton<int>(
                            value: _selectedBaud,
                            dropdownColor: AppColors.cardSurface,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            items: SensorConstants.supportedBaudRates.map((b) {
                              return DropdownMenuItem<int>(
                                value: b,
                                child: Text('$b bps'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedBaud = val);
                                vm.switchBaudRate(val);
                              }
                            },
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Auto-Connect OTG (เชื่อมต่ออัตโนมัติ)',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'เชื่อมต่อเซนเซอร์ทันทีเมื่อเปิดแอป หรือเมื่อเสียบสาย USB OTG (Hotplug)',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        value: vm.isAutoConnectEnabled,
                        activeColor: Colors.greenAccent,
                        onChanged: (val) => vm.toggleAutoConnect(val),
                      ),
                      const Divider(color: Colors.white10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Auto-Baud Rate Detection',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        subtitle: const Text(
                          'สลับค้นหาความเร็ว 4800 / 9600 อัตโนมัติใน 0.8 วินาทีเมื่อไม่พบข้อมูล',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        value: vm.isAutoBaudActive,
                        activeColor: Colors.cyanAccent,
                        onChanged: (val) => vm.toggleAutoBaud(val),
                      ),
                      const Divider(color: Colors.white10),
                      const Text(
                        'ความถี่การอ่านค่าเรียลไทม์ (Polling Rate):',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: vm.pollingIntervalMs == 350 ? Colors.cyanAccent.withValues(alpha: 0.2) : Colors.transparent,
                                side: BorderSide(color: vm.pollingIntervalMs == 350 ? Colors.cyanAccent : Colors.white24),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              onPressed: () => vm.setPollingInterval(350),
                              child: const Text('350 ms\n(Turbo ~2.8Hz)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: vm.pollingIntervalMs == 400 ? Colors.cyanAccent.withValues(alpha: 0.2) : Colors.transparent,
                                side: BorderSide(color: vm.pollingIntervalMs == 400 ? Colors.cyanAccent : Colors.white24),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              onPressed: () => vm.setPollingInterval(400),
                              child: const Text('400 ms\n(Fast ~2.5Hz)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: vm.pollingIntervalMs == 1000 ? Colors.cyanAccent.withValues(alpha: 0.2) : Colors.transparent,
                                side: BorderSide(color: vm.pollingIntervalMs == 1000 ? Colors.cyanAccent : Colors.white24),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              onPressed: () => vm.setPollingInterval(1000),
                              child: const Text('1000 ms\n(Standard 1Hz)', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Modbus Slave ID:',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          Text(
                            '0x0$_slaveId (1)',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Protocol Framing:',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          Flexible(
                            child: Text(
                              '8-N-1 (Half-Duplex RS485)',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Section 2: Real-time Diagnostics / Traffic Monitor
              const Text(
                'Live Telemetry & Modbus Diagnostics',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                color: AppColors.cardSurface,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('สถานะข้อมูลเซนเซอร์:', style: TextStyle(color: Colors.white70)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              vm.hasReceivedValidReading
                                  ? '● ได้รับข้อมูลปกติ (Valid CRC)'
                                  : (vm.rxByteCount > 0 ? '● ได้รับไบต์ แต่ยังไม่ครบเฟรม' : '○ ยังไม่มีข้อมูลตอบกลับ'),
                              style: TextStyle(
                                color: vm.hasReceivedValidReading
                                    ? Colors.greenAccent
                                    : (vm.rxByteCount > 0 ? Colors.amberAccent : Colors.redAccent),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Tx Frames: ${vm.txCount}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          Text('Rx Bytes: ${vm.rxByteCount} B', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Last TX: ${vm.lastTxHex}',
                              style: const TextStyle(color: Colors.cyanAccent, fontFamily: 'monospace', fontSize: 11),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Last RX: ${vm.lastRxHex}',
                              style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Section 3: AI PINN Calibration Model Config
              const Text(
                'Deep Learning Model (PINN Calibration)',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                color: AppColors.cardSurface,
                child: SwitchListTile(
                  title: const Text(
                    'AI Sensor Error Compensation',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'ชดเชยค่าความชื้นและอุณหภูมิผิดพลาดด้วย JC-SoilNet PINN',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  value: vm.isAiCalibrationEnabled,
                  activeColor: Colors.cyanAccent,
                  onChanged: (val) => vm.toggleAiCalibration(val),
                  secondary: const Icon(Icons.auto_awesome, color: Colors.cyanAccent),
                ),
              ),

              const SizedBox(height: 16),

              // Section 4: Connection Actions
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.headerGradientStart,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.usb),
                label: const Text('Reconnect USB Probe (เชื่อมต่อใหม่)'),
                onPressed: () async {
                  final ok = await vm.connectUsb(baud: _selectedBaud);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'USB Probe Connected at $_selectedBaud bps'
                              : 'No USB device detected. Please check Type-C OTG.',
                        ),
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 10),

              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.cyanAccent,
                  side: const BorderSide(color: Colors.cyanAccent),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('View AI Model Diagnostics & Delta Table'),
                onPressed: () {
                  AiModelDetailsSheet.show(
                    context,
                    calibrationResult: vm.calibrationResult,
                    isAiActive: vm.isAiCalibrationEnabled,
                    onToggleAi: (val) => vm.toggleAiCalibration(val),
                  );
                },
              ),

              const SizedBox(height: 10),

              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amberAccent,
                  side: const BorderSide(color: Colors.amberAccent),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                icon: Icon(
                  vm.isSimulationMode ? Icons.stop : Icons.play_arrow,
                ),
                label: Text(
                  vm.isSimulationMode
                      ? 'Stop Demo Simulation'
                      : 'Start Demo Simulation Stream',
                ),
                onPressed: () => vm.toggleSimulation(),
              ),

              const SizedBox(height: 20),

              // Section 5: User Manual & Academic Handbook Download
              const Text(
                'คู่มือการใช้งานและเอกสารวิชาการ (User Manual & Academic Handbook)',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                color: AppColors.cardSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.greenAccent.withValues(alpha: 0.4),
                    width: 1.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE53935), Color(0xFFC62828)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'JC Digital Soil AI Beginner Guide',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'คู่มือฉบับสมบูรณ์ (LaTeX / PDF 60 หน้า) ครอบคลุมฮาร์ดแวร์ Modbus RTU, โมเดล PINN Deep Learning, ซอร์สโค้ด และผลวิจัยแปลงจริง',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black45,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.white24, width: 0.7),
                                      ),
                                      child: const Text(
                                        'PDF 1.5 MB',
                                        style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black45,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.white24, width: 0.7),
                                      ),
                                      child: const Text(
                                        'มาตรฐาน RBRU',
                                        style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: _isExportingPdf
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.download, size: 18),
                              label: Text(
                                _isExportingPdf ? 'กำลังดาวน์โหลด...' : 'ดาวน์โหลดคู่มือ PDF',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                              ),
                              onPressed: _isExportingPdf ? null : () => _downloadOrSharePdfManual(shareImmediately: false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.cyanAccent,
                                side: const BorderSide(color: Colors.cyanAccent),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.share, size: 18),
                              label: const Text(
                                'เปิดอ่าน / ส่งต่อ',
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                              ),
                              onPressed: _isExportingPdf ? null : () => _downloadOrSharePdfManual(shareImmediately: true),
                            ),
                          ),
                        ],
                      ),
                      if (_savedPdfPath != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.5), width: 0.8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'บันทึกแล้วที่: $_savedPdfPath',
                                  style: const TextStyle(color: Colors.greenAccent, fontSize: 11),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Section 6: Optimization & Troubleshooting Guide
              const Text(
                'เทคนิคการเชื่อมต่อและการปรับความเร็วเรียลไทม์ (Optimization Guide)',
                style: TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  '1. ระบบเชื่อมต่ออัตโนมัติ (Instant Auto-Connect & Hotplug):\n'
                  '   แอปได้รับการตั้งค่าระบบ Auto-Connect และ Hotplug Listener ไว้ล่วงหน้า เมื่อเปิดแอป หรือเมื่อเสียบหัววัด Type-C เข้ากับสมาร์ตโฟน ระบบจะค้นหาพอร์ต USB และเชื่อมต่อทันทีโดยอัตโนมัติโดยไม่ต้องกดปุ่มใดๆ\n\n'
                  '2. การอนุญาต USB ถาวร (Bypass Permission Dialog):\n'
                  '   เมื่อ Android แสดงหน้าต่าง "Allow SOIL AI ANALYZER to access USB device?" ให้ทำเครื่องหมายถูกที่ช่อง [Always open / Always allow...] เพื่อให้ระบบจดจำหัววัดและเชื่อมต่อในเสี้ยววินาทีทุกครั้งที่เสียบสาย\n\n'
                  '3. เปิดใช้งาน OTG บนสมาร์ตโฟน (สำหรับแบรนด์ Oppo, Vivo, Realme, Xiaomi):\n'
                  '   สมาร์ตโฟนบางรุ่นปิดไฟเลี้ยงพอร์ต OTG อัตโนมัติ ให้ไปที่ การตั้งค่า (Settings) -> การตั้งค่าเพิ่มเติม (System/Additional) -> เปิด "OTG Connection" ให้เป็น ON\n\n'
                  '4. เทคนิคความเร็วและการแสดงผลแบบเรียลไทม์ (Real-Time Optimization):\n'
                  '   • ปรับ Polling Rate เป็น 350 ms หรือ 400 ms เพื่อให้อัตราอัปเดตหน้าจออยู่ที่ ~2.5 - 2.8 ครั้งต่อวินาที\n'
                  '   • ระบบ Fast Auto-Baud จะค้นหาและจับคู่ความเร็ว 4800 bps / 9600 bps ให้อัตโนมัติภายในเวลาไม่ถึง 1 วินาที\n'
                  '   • ไบต์ข้อมูล Modbus RTU จะถูกถอดรหัสผ่าน Sliding Window CRC-16 ในระดับ Stream Buffer โดยไม่มี delay ที่เปล่าประโยชน์\n\n'
                  '5. การต่อสายสัญญาณ RS485 เข้ากับหัววัด 7-in-1 / 8-in-1:\n'
                  '   • สายสีน้ำตาล (VCC): ไฟเลี้ยง +5V ถึง +12V DC\n'
                  '   • สายสีดำ (GND): กราวด์ 0V\n'
                  '   • สายสีเหลือง (A+ / 485+): สัญญาณข้อมูล A\n'
                  '   • สายสีน้ำเงิน (B- / 485-): สัญญาณข้อมูล B',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
