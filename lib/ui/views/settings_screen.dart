import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:usb_serial/usb_serial.dart';

import '../../core/constants/sensor_constants.dart';
import '../../core/localization/language_provider.dart';
import '../../data/services/usb_sensor_service.dart';
import '../viewmodels/soil_sensor_viewmodel.dart';
import '../widgets/ai_model_details_sheet.dart';
import '../../data/services/google_drive_sync_service.dart';

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

  List<UsbDevice> _detectedDevices = [];
  bool _isScanningUsb = false;

  // Google Drive Cloud Sync state
  GoogleDriveSyncStatus? _driveSyncStatus;
  bool _isSyncingDrive = false;
  final TextEditingController _webhookUrlController = TextEditingController();
  bool _showWebhookConfig = false;

  @override
  void initState() {
    super.initState();
    final vm = context.read<SoilSensorViewModel>();
    _selectedBaud = vm.baudRate;
    _scanUsbHardware();
    _loadDriveSyncStatus();
  }

  @override
  void dispose() {
    _webhookUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadDriveSyncStatus() async {
    final status = await GoogleDriveSyncService.getSyncStatus();
    if (mounted) {
      setState(() {
        _driveSyncStatus = status;
        if (_webhookUrlController.text.isEmpty && status.webhookUrl.isNotEmpty) {
          _webhookUrlController.text = status.webhookUrl;
        }
      });
    }
  }

  Future<void> _performGoogleDriveBackup(SoilSensorViewModel vm, LanguageProvider lang) async {
    setState(() => _isSyncingDrive = true);
    final success = await GoogleDriveSyncService.backupAllDatasetsToDrive(currentReadings: vm.history);
    await _loadDriveSyncStatus();
    if (mounted) {
      setState(() => _isSyncingDrive = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F766E),
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              const Icon(Icons.cloud_done, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  success
                      ? '${lang.t('syncSuccess')} (โปรดเลือก "บันทึกไปยังไดรฟ์" ในหน้าต่างแชร์)'
                      : 'เตรียมชุดข้อมูล Google Drive เรียบร้อย',
                  style: const TextStyle(color: Colors.white, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _performMediaSync(LanguageProvider lang) async {
    setState(() => _isSyncingDrive = true);
    final success = await GoogleDriveSyncService.syncMediaGalleryToDrive();
    await _loadDriveSyncStatus();
    if (mounted) {
      setState(() => _isSyncingDrive = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: success ? const Color(0xFF0F766E) : const Color(0xFF334155),
          duration: const Duration(seconds: 4),
          content: Text(
            success
                ? '${lang.t('syncSuccess')} (ภาพ/วิดีโอแปลงดิน)'
                : 'ไม่พบไฟล์ภาพหรือวิดีโอในคลังสำหรับสำรองข้อมูล',
            style: const TextStyle(color: Colors.white, fontSize: 12.5),
          ),
        ),
      );
    }
  }

  Future<void> _performWebhookSync(SoilSensorViewModel vm, LanguageProvider lang) async {
    final url = _webhookUrlController.text.trim();
    if (url.isEmpty || !url.startsWith('http')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.amber,
          content: Text('กรุณาระบุ URL ของ Google Apps Script Webhook ที่ถูกต้อง', style: TextStyle(color: Colors.black)),
        ),
      );
      return;
    }

    setState(() => _isSyncingDrive = true);
    await GoogleDriveSyncService.saveConfig(webhookUrl: url);
    final success = await GoogleDriveSyncService.syncViaWebhook(
      webhookUrl: url,
      history: vm.history,
    );
    await _loadDriveSyncStatus();
    if (mounted) {
      setState(() => _isSyncingDrive = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: success ? const Color(0xFF0F766E) : Colors.redAccent.shade700,
          content: Text(
            success ? 'ยิงข้อมูลเข้าสู่ Google Drive Webhook สำเร็จแล้ว!' : 'การเชื่อมต่อ Webhook ล้มเหลว กรุณาตรวจสอบ URL',
            style: const TextStyle(color: Colors.white, fontSize: 12.5),
          ),
        ),
      );
    }
  }

  Future<void> _scanUsbHardware() async {
    if (!mounted) return;
    setState(() => _isScanningUsb = true);
    try {
      final vm = context.read<SoilSensorViewModel>();
      final devices = await vm
          .getAvailableUsbDevices()
          .timeout(const Duration(milliseconds: 300), onTimeout: () => []);
      if (mounted) {
        setState(() {
          _detectedDevices = devices;
          _isScanningUsb = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isScanningUsb = false);
    }
  }

  Future<void> _downloadOrSharePdfManual({bool shareImmediately = false}) async {
    final lang = context.read<LanguageProvider>();
    setState(() => _isExportingPdf = true);

    try {
      const assetPath = 'assets/docs/JC_Digital_Soil_AI_Beginner_Guide.pdf';
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();

      Directory? targetDir;
      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          targetDir = downloadDir;
        } else {
          targetDir = await getExternalStorageDirectory();
        }
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }
      targetDir ??= await getTemporaryDirectory();

      final targetFile = File('${targetDir.path}/JC_Digital_Soil_AI_Beginner_Guide.pdf');
      await targetFile.writeAsBytes(bytes, flush: true);

      if (mounted) {
        setState(() {
          _savedPdfPath = targetFile.path;
          _isExportingPdf = false;
        });
      }

      if (shareImmediately) {
        await Share.shareXFiles(
          [XFile(targetFile.path)],
          text: lang.t('userManualTitle'),
          subject: 'JC Digital Soil AI Beginner Guide PDF',
        );
      } else {
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
                      '${lang.t('pdfDownloadSuccess')}: ${targetFile.path.split('/').last}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: lang.t('openPdfAction'),
                textColor: Colors.cyanAccent,
                onPressed: () {
                  Share.shareXFiles(
                    [XFile(targetFile.path)],
                    text: lang.t('userManualTitle'),
                  );
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExportingPdf = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade900,
            content: Text('${lang.t('pdfDownloadError')}: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SoilSensorViewModel>();
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0C1017),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.t('sensorConfig'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const Text(
              'Sensor & Hardware Config',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white70,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF131A24),
        elevation: 2,
        actions: [
          // Connection Status Indicator Badge in AppBar
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusBgColor(vm.status),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getStatusBorderColor(vm.status), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _getStatusColor(vm.status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _getStatusText(vm.status, lang),
                  style: TextStyle(
                    color: _getStatusColor(vm.status),
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            children: [
              // =========================================================
              // 1. HERO CARD: LIVE HARDWARE STATUS & USB BUS MONITOR
              // =========================================================
              _buildLiveHardwareStatusCard(vm, lang),

              const SizedBox(height: 16),

              // =========================================================
              // 2. USB OTG HARDWARE DETECTOR & DIAGNOSTIC ASSISTANT
              // =========================================================
              _buildUsbHardwareDetectorCard(vm, lang),

              const SizedBox(height: 16),

              // =========================================================
              // 3. SERIAL INTERFACE & MODBUS RTU CONFIGURATION
              // =========================================================
              _buildModbusConfigurationCard(vm, lang),

              const SizedBox(height: 16),

              // =========================================================
              // 4. REAL-TIME DATA STREAM & TRAFFIC INSPECTOR
              // =========================================================
              _buildTrafficInspectorCard(vm, lang),

              const SizedBox(height: 16),

              // =========================================================
              // 5. DEEP LEARNING MODEL (PINN CALIBRATION)
              // =========================================================
              _buildAiModelCard(vm, lang),

              const SizedBox(height: 16),

              // =========================================================
              // 6. ACTION CONTROLS & DIAGNOSTIC BUTTONS
              // =========================================================
              _buildActionButtons(vm, lang),

              const SizedBox(height: 20),

              // =========================================================
              // 7. GOOGLE DRIVE CLOUD SYNC & AUTO-BACKUP
              // =========================================================
              _buildGoogleDriveSyncCard(vm, lang),

              const SizedBox(height: 20),

              // =========================================================
              // 8. USER MANUAL PDF DOWNLOAD & HANDBOOK SECTION
              // =========================================================
              _buildPdfHandbookCard(lang),

              const SizedBox(height: 20),

              // =========================================================
              // 9. OPTIMIZATION & PINOUT REFERENCE
              // =========================================================
              _buildPinoutAndOptimizationGuide(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. Hero Card: Live Hardware Status & USB Bus Health
  // -------------------------------------------------------------
  Widget _buildLiveHardwareStatusCard(SoilSensorViewModel vm, LanguageProvider lang) {
    final statusColor = _getStatusColor(vm.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF162130),
            const Color(0xFF0F1722),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.usb, color: statusColor, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'USB-OTG Hardware Bus',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getStatusText(vm.status, lang),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Quick Connect / Reconnect Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor.withValues(alpha: 0.2),
                  foregroundColor: statusColor,
                  side: BorderSide(color: statusColor, width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(
                  vm.status == UsbConnectionStatus.connected ? 'เชื่อมต่อแล้ว' : 'เชื่อมต่อ OTG',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  await _scanUsbHardware();
                  final ok = await vm.connectUsb(baud: _selectedBaud);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: ok ? Colors.teal.shade900 : Colors.red.shade900,
                        content: Text(
                          ok
                              ? 'เชื่อมต่อหัววัดสำเร็จที่ความเร็ว $_selectedBaud bps'
                              : 'No USB device detected. Please check Type-C OTG.',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),

          // Bus Metrics: Baud Rate, Polling Rate, TX/RX packets
          Row(
            children: [
              _buildBusMetric(
                label: 'Baud Rate',
                value: '${vm.baudRate} bps',
                icon: Icons.speed,
                color: Colors.cyanAccent,
              ),
              _buildBusMetric(
                label: 'ความถี่อ่านค่า',
                value: '${vm.pollingIntervalMs} ms',
                icon: Icons.timer,
                color: Colors.amberAccent,
              ),
              _buildBusMetric(
                label: 'Tx / Rx Packets',
                value: '${vm.txCount} / ${vm.rxByteCount}B',
                icon: Icons.sync_alt,
                color: vm.hasReceivedValidReading ? Colors.greenAccent : Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0D131C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 12),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white60, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. USB OTG Hardware Detector & Diagnostic Card
  // -------------------------------------------------------------
  Widget _buildUsbHardwareDetectorCard(SoilSensorViewModel vm, LanguageProvider lang) {
    final hasDevices = _detectedDevices.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131A24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasDevices ? Colors.tealAccent.withValues(alpha: 0.4) : Colors.amberAccent.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      hasDevices ? Icons.devices_other : Icons.usb_off,
                      color: hasDevices ? Colors.cyanAccent : Colors.amberAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'การตรวจจับฮาร์ดแวร์ USB (OTG Detection)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: _isScanningUsb
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                      )
                    : const Icon(Icons.sync, color: Colors.cyanAccent),
                tooltip: 'สแกนพอร์ต USB ใหม่',
                onPressed: _isScanningUsb ? null : _scanUsbHardware,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // If USB Devices are detected
          if (hasDevices) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF003B46).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: _detectedDevices.map((d) {
                  final vid = d.vid ?? 0;
                  final pid = d.pid ?? 0;
                  final vidHex = '0x${vid.toRadixString(16).padLeft(4, '0').toUpperCase()}';
                  final pidHex = '0x${pid.toRadixString(16).padLeft(4, '0').toUpperCase()}';
                  final chipName = _identifyUsbChip(vid, pid, d.productName);

                  return Row(
                    children: [
                      const Icon(Icons.memory, color: Colors.greenAccent, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chipName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'VID: $vidHex | PID: $pidHex  •  Device ID: ${d.deviceId}',
                              style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade900,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'พร้อมใช้งาน',
                          style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ] else ...[
            // When NO USB device detected: Comprehensive Diagnostic Advice Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade900.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ไม่พบอุปกรณ์ USB บนพอร์ต Type-C (No USB Device Detected)',
                          style: TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'แม้จะเปิดสวิตช์ OTG ในมือถือแล้ว อุปกรณ์อาจยังไม่ปรากฏเนื่องจากสาเหตุดังนี้:',
                    style: TextStyle(color: Colors.white70, fontSize: 11.5),
                  ),
                  const SizedBox(height: 8),

                  _buildTroubleItem(
                    step: '1',
                    title: 'OPPO / ColorOS ปิด OTG อัตโนมัติทุก 10 นาที',
                    detail: 'หากไม่มีการส่งข้อมูลนานเกิน 10 นาที หรือมีการถอดสายออก ระบบ ColorOS จะปิดฟังก์ชัน OTG อัตโนมัติเพื่อประหยัดแบตเตอรี่\n👉 วิธีแก้: เข้าไปที่ การตั้งค่า (Settings) > การตั้งค่าเพิ่มเติม (Additional Settings) > เปิด [การเชื่อมต่อ OTG] อีกครั้ง',
                  ),
                  const SizedBox(height: 6),

                  _buildTroubleItem(
                    step: '2',
                    title: 'ไฟเลี้ยงหัววัดตกชั่วขณะ (Inrush Current / Power Sag)',
                    detail: 'หัววัดดิน 8-in-1 มีวงจรแปลงไฟ DC-DC ภายใน ขณะเสียบสายเสี้ยววินาทีแรกอาจดึงกระแสกระชาก ทำให้ระบบมือถือตัดไฟ VBUS ชั่วคราว\n👉 วิธีแก้: เสียบสาย Type-C ให้แน่นสนิท รอ 1 วินาทีให้ไฟนิ่ง แล้วกดปุ่ม "สแกน USB ใหม่" ด้านล่าง',
                  ),
                  const SizedBox(height: 6),

                  _buildTroubleItem(
                    step: '3',
                    title: 'เคสโทรศัพท์ขวางหัวต่อ Type-C (Loose Contact)',
                    detail: 'เคสมือถือที่หนาอาจทำให้หัวแปลง Type-C เสียบไม่ลึกสุด ขาพิน CC/Data จึงไม่สัมผัสกัน\n👉 วิธีแก้: ลองถอดเคสมือถือออก แล้วเสียบหัวแปลง Type-C ให้แน่นสนิท',
                  ),
                  const SizedBox(height: 6),

                  _buildTroubleItem(
                    step: '4',
                    title: 'การอนุญาตสิทธิ์การเข้าถึง USB (Android Permission)',
                    detail: 'เมื่อเสียบสาย หากมีหน้าต่างระบบเด้งถาม "Allow SOIL AI ANALYZER to access USB device?" ให้ติ๊กถูกที่ [x] Always open / Always allow แล้วกด ตกลง (OK)',
                  ),

                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.radar, size: 16),
                      label: const Text(
                        '🔍 สแกนและลองเชื่อมต่อใหม่อีกครั้ง (Retry Scan)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        await _scanUsbHardware();
                        await vm.connectUsb(baud: _selectedBaud);
                      },
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

  Widget _buildTroubleItem({required String step, required String title, required String detail}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Colors.amberAccent,
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: const TextStyle(color: Colors.black, fontSize: 10.5, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 1),
              Text(
                detail,
                style: const TextStyle(color: Colors.white70, fontSize: 10.5, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _identifyUsbChip(int vid, int pid, String? productName) {
    if (vid == 0x1A86 || vid == 6790) return 'Qinheng CH340 / CH341 (USB-RS485)';
    if (vid == 0x10C4 || vid == 4292) return 'Silicon Labs CP2102 / CP2104';
    if (vid == 0x0403 || vid == 1027) return 'FTDI FT232R / FT232H';
    if (vid == 0x067B || vid == 1659) return 'Prolific PL2303';
    return productName ?? 'USB Serial Adapter (0x${vid.toRadixString(16)}:0x${pid.toRadixString(16)})';
  }

  // -------------------------------------------------------------
  // 3. Serial Interface & Modbus RTU Card
  // -------------------------------------------------------------
  Widget _buildModbusConfigurationCard(SoilSensorViewModel vm, LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131A24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.settings_input_composite, color: Color(0xFF00FFFF), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'การตั้งค่าสื่อสาร Modbus RTU & ความเร็ว (Baud Rate)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Baud Rate Chip Buttons
          const Text(
            'เลือกความเร็วสื่อสาร (Baud Rate):',
            style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildBaudChip(
                label: '4800 bps\n(ค่ามาตรฐาน)',
                baud: 4800,
                isSelected: vm.baudRate == 4800,
                onTap: () {
                  setState(() => _selectedBaud = 4800);
                  vm.switchBaudRate(4800);
                },
              ),
              const SizedBox(width: 8),
              _buildBaudChip(
                label: '9600 bps\n(ความเร็วสูง)',
                baud: 9600,
                isSelected: vm.baudRate == 9600,
                onTap: () {
                  setState(() => _selectedBaud = 9600);
                  vm.switchBaudRate(9600);
                },
              ),
              const SizedBox(width: 8),
              _buildBaudChip(
                label: '19200 bps\n(พิเศษ)',
                baud: 19200,
                isSelected: vm.baudRate == 19200,
                onTap: () {
                  setState(() => _selectedBaud = 19200);
                  vm.switchBaudRate(19200);
                },
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Colors.white10),

          // Auto-Connect & Auto-Baud switches
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Auto-Connect OTG (เชื่อมต่ออัตโนมัติ)',
              style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'เชื่อมต่อเซนเซอร์ทันทีเมื่อเปิดแอป หรือเมื่อเสียบสาย USB OTG (Hotplug)',
              style: TextStyle(color: Colors.white60, fontSize: 11.5),
            ),
            value: vm.isAutoConnectEnabled,
            activeThumbColor: Colors.greenAccent,
            onChanged: (val) => vm.toggleAutoConnect(val),
          ),

          const Divider(color: Colors.white10),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Auto-Baud Rate Detection (ค้นหาความเร็วอัตโนมัติ)',
              style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'สลับค้นหา 4800 / 9600 bps ให้อัตโนมัติเมื่อยังไม่พบข้อมูลตอบกลับ',
              style: TextStyle(color: Colors.white60, fontSize: 11.5),
            ),
            value: vm.isAutoBaudActive,
            activeThumbColor: Colors.cyanAccent,
            onChanged: (val) => vm.toggleAutoBaud(val),
          ),

          const Divider(color: Colors.white10),

          // Polling Rate Selector
          const Text(
            'ความถี่การอ่านค่าเรียลไทม์ (Polling Rate):',
            style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPollingChip(
                title: '350 ms',
                subtitle: '⚡ Turbo (~2.8Hz)',
                interval: 350,
                currentInterval: vm.pollingIntervalMs,
                onTap: () => vm.setPollingInterval(350),
              ),
              const SizedBox(width: 8),
              _buildPollingChip(
                title: '400 ms',
                subtitle: '⏱️ เร็ว (~2.5Hz)',
                interval: 400,
                currentInterval: vm.pollingIntervalMs,
                onTap: () => vm.setPollingInterval(400),
              ),
              const SizedBox(width: 8),
              _buildPollingChip(
                title: '1000 ms',
                subtitle: '🍃 ประหยัด (1Hz)',
                interval: 1000,
                currentInterval: vm.pollingIntervalMs,
                onTap: () => vm.setPollingInterval(1000),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Colors.white10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Modbus Slave ID:', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text('0x0$_slaveId (Default: 1)', style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 4,
            children: const [
              Text('Framing & Parity:', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text('8-N-1 (Half-Duplex RS485)', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBaudChip({
    required String label,
    required int baud,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.2) : const Color(0xFF0D131C),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.cyanAccent : Colors.white12,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.cyanAccent : Colors.white70,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPollingChip({
    required String title,
    required String subtitle,
    required int interval,
    required int currentInterval,
    required VoidCallback onTap,
  }) {
    final isSelected = currentInterval == interval;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.18) : const Color(0xFF0D131C),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.cyanAccent : Colors.white12,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.cyanAccent : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: isSelected ? Colors.cyanAccent : Colors.white60,
                  fontSize: 9.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 4. Traffic Inspector & Hex Stream Monitor
  // -------------------------------------------------------------
  Widget _buildTrafficInspectorCard(SoilSensorViewModel vm, LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131A24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.terminal, color: Colors.cyanAccent, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Live Telemetry & Modbus Diagnostics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 4,
            children: [
              const Text('สถานะข้อมูลเซนเซอร์:', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
              Text(
                vm.hasReceivedValidReading
                    ? '● ได้รับข้อมูลปกติ (Valid CRC)'
                    : (vm.rxByteCount > 0 ? '● ได้รับไบต์ แต่ยังไม่ครบเฟรม' : '○ ยังไม่มีข้อมูลตอบกลับ'),
                style: TextStyle(
                  color: vm.hasReceivedValidReading
                      ? Colors.greenAccent
                      : (vm.rxByteCount > 0 ? Colors.amberAccent : Colors.redAccent),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF090D13),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.arrow_upward, color: Colors.cyanAccent, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'TX Request: ${vm.lastTxHex}',
                      style: const TextStyle(color: Colors.cyanAccent, fontFamily: 'monospace', fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.arrow_downward, color: Colors.greenAccent, size: 12),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'RX Stream:  ${vm.lastRxHex}',
                        style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 5. Deep Learning Model (PINN Calibration)
  // -------------------------------------------------------------
  Widget _buildAiModelCard(SoilSensorViewModel vm, LanguageProvider lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131A24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Color(0xFF00FFAA), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Deep Learning Model (PINN Calibration)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'AI Sensor Error Compensation',
              style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'ชดเชยค่าความชื้นและอุณหภูมิผิดพลาดด้วย JC-SoilNet PINN',
              style: TextStyle(color: Colors.white60, fontSize: 11.5),
            ),
            value: vm.isAiCalibrationEnabled,
            activeThumbColor: const Color(0xFF00FFAA),
            onChanged: (val) => vm.toggleAiCalibration(val),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 6. Action Controls & Buttons
  // -------------------------------------------------------------
  Widget _buildActionButtons(SoilSensorViewModel vm, LanguageProvider lang) {
    return Column(
      children: [
        // Reconnect Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00838F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 3,
            ),
            icon: const Icon(Icons.usb, size: 20),
            label: const Text(
              'Reconnect USB Probe (เชื่อมต่อใหม่)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              await _scanUsbHardware();
              final ok = await vm.connectUsb(baud: _selectedBaud);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: ok ? Colors.teal.shade900 : Colors.red.shade900,
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
        ),

        const SizedBox(height: 10),

        // AI Diagnostics Sheet Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.cyanAccent,
              side: const BorderSide(color: Colors.cyanAccent),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.analytics_outlined, size: 19),
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
        ),

        const SizedBox(height: 10),

        // Demo Simulation Mode Toggle
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.amberAccent,
              side: const BorderSide(color: Colors.amberAccent),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: Icon(
              vm.isSimulationMode ? Icons.stop : Icons.play_arrow,
              size: 19,
            ),
            label: Text(
              vm.isSimulationMode ? 'Stop Demo Simulation' : 'Start Demo Simulation Stream',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => vm.toggleSimulation(),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 7. Google Drive Cloud Sync & Auto-Backup Card
  // -------------------------------------------------------------
  Widget _buildGoogleDriveSyncCard(SoilSensorViewModel vm, LanguageProvider lang) {
    final lastSync = _driveSyncStatus?.lastSyncTime;
    final lastSyncStr = lastSync != null
        ? '${lastSync.year}-${lastSync.month.toString().padLeft(2, '0')}-${lastSync.day.toString().padLeft(2, '0')} ${lastSync.hour.toString().padLeft(2, '0')}:${lastSync.minute.toString().padLeft(2, '0')}'
        : lang.t('neverSynced');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F2338),
            Color(0xFF0A1926),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Icon + Title & Sync Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_sync, color: Colors.cyanAccent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.t('googleDriveSyncTitle'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lang.t('googleDriveSyncSubtitle'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Status Badge Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF131D28),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Icon(
                  _driveSyncStatus?.lastSyncSuccess == true
                      ? Icons.check_circle
                      : Icons.history,
                  color: _driveSyncStatus?.lastSyncSuccess == true
                      ? Colors.greenAccent
                      : Colors.white38,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  '${lang.t('lastSyncTime')}: ',
                  style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                ),
                Expanded(
                  child: Text(
                    lastSyncStr,
                    style: TextStyle(
                      color: _driveSyncStatus?.lastSyncSuccess == true
                          ? Colors.greenAccent
                          : Colors.white70,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_isSyncingDrive)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.cyanAccent,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Primary Button: Sync All Datasets to Drive (CSV & Manifest)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 3,
              ),
              icon: const Icon(Icons.drive_folder_upload, size: 20),
              label: Text(
                lang.t('syncAllDatasetsToDrive'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: _isSyncingDrive ? null : () => _performGoogleDriveBackup(vm, lang),
            ),
          ),

          const SizedBox(height: 10),

          // Secondary Button: Sync Photos & Videos
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.tealAccent,
                side: const BorderSide(color: Colors.tealAccent, width: 1.1),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.photo_library_outlined, size: 19),
              label: Text(
                lang.t('syncMediaToDrive'),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
              ),
              onPressed: _isSyncingDrive ? null : () => _performMediaSync(lang),
            ),
          ),

          const SizedBox(height: 12),

          // Tip box with guidance
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.cyan.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.cyan.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.amberAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lang.t('directDriveBackupTip'),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Collapsible Webhook Config
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: Colors.cyanAccent.shade100,
              ),
              icon: Icon(
                _showWebhookConfig ? Icons.expand_less : Icons.expand_more,
                size: 16,
              ),
              label: Text(
                _showWebhookConfig ? 'ซ่อนการตั้งค่า Webhook' : 'ตั้งค่า Webhook URL (ทางเลือก)',
                style: const TextStyle(fontSize: 11),
              ),
              onPressed: () => setState(() => _showWebhookConfig = !_showWebhookConfig),
            ),
          ),

          if (_showWebhookConfig) ...[
            const SizedBox(height: 6),
            TextField(
              controller: _webhookUrlController,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                labelText: lang.t('googleDriveWebhookUrl'),
                labelStyle: const TextStyle(color: Colors.white60, fontSize: 11),
                hintText: 'https://script.google.com/macros/s/.../exec',
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 11),
                filled: true,
                fillColor: const Color(0xFF131D28),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  lang.t('syncNow'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: _isSyncingDrive ? null : () => _performWebhookSync(vm, lang),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 8. User Manual PDF Download & Academic Handbook Card
  // -------------------------------------------------------------
  Widget _buildPdfHandbookCard(LanguageProvider lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'คู่มือการใช้งานและเอกสารวิชาการ (User Manual & Academic Handbook)',
          style: TextStyle(
            color: Colors.greenAccent,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF131A24),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4), width: 1.0),
          ),
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
                    ),
                    child: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 26),
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
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'คู่มือฉบับสมบูรณ์ (LaTeX / PDF 66 หน้า) ครอบคลุมฮาร์ดแวร์ Modbus RTU, โมเดล PINN Deep Learning, ซอร์สโค้ด และผลวิจัยแปลงจริง',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11.5, height: 1.3),
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
                              child: const Text('PDF 1.5 MB', style: TextStyle(color: Colors.cyanAccent, fontSize: 9.5, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.white24, width: 0.7),
                              ),
                              child: const Text('มาตรฐาน RBRU', style: TextStyle(color: Colors.amberAccent, fontSize: 9.5, fontWeight: FontWeight.bold)),
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
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
                      label: const Text('เปิดอ่าน / ส่งต่อ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
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
      ],
    );
  }

  // -------------------------------------------------------------
  // 8. Pinout & Optimization Guide
  // -------------------------------------------------------------
  Widget _buildPinoutAndOptimizationGuide() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F151F),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.25)),
      ),
      child: const Text(
        '📌 ข้อมูลการต่อสายสัญญาณเซนเซอร์ดิน 8-in-1 (RS485 Pinout Reference):\n'
        '• สายสีน้ำตาล (VCC): ไฟเลี้ยง +5V ถึง +12V DC\n'
        '• สายสีดำ (GND): กราวด์ 0V\n'
        '• สายสีเหลือง (A+ / 485+): สัญญาณข้อมูล A\n'
        '• สายสีน้ำเงิน (B- / 485-): สัญญาณข้อมูล B\n\n'
        '💡 สำหรับสมาร์ตโฟน OPPO / Realme / Vivo:\n'
        'หากเสียบสายแล้วไม่พบอุปกรณ์ ให้ตรวจเช็กใน [การตั้งค่า > การตั้งค่าเพิ่มเติม > การเชื่อมต่อ OTG] ว่าระบบตัดปิดอัตโนมัติ 10 นาทีหรือไม่',
        style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.45),
      ),
    );
  }

  // Helpers
  Color _getStatusColor(UsbConnectionStatus s) {
    switch (s) {
      case UsbConnectionStatus.connected:
        return Colors.greenAccent;
      case UsbConnectionStatus.connecting:
        return Colors.cyanAccent;
      case UsbConnectionStatus.error:
        return Colors.redAccent;
      case UsbConnectionStatus.disconnected:
        return Colors.amberAccent;
      case UsbConnectionStatus.simulating:
        return Colors.purpleAccent;
    }
  }

  Color _getStatusBgColor(UsbConnectionStatus s) {
    return _getStatusColor(s).withValues(alpha: 0.15);
  }

  Color _getStatusBorderColor(UsbConnectionStatus s) {
    return _getStatusColor(s).withValues(alpha: 0.6);
  }

  String _getStatusText(UsbConnectionStatus s, LanguageProvider lang) {
    switch (s) {
      case UsbConnectionStatus.connected:
        return lang.t('connected');
      case UsbConnectionStatus.connecting:
        return lang.t('connecting');
      case UsbConnectionStatus.error:
        return 'ข้อผิดพลาด';
      case UsbConnectionStatus.disconnected:
        return lang.t('disconnected');
      case UsbConnectionStatus.simulating:
        return 'จำลองข้อมูล (Simulating)';
    }
  }
}
