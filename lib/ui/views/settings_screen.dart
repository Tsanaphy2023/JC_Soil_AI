import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    _selectedBaud = context.read<SoilSensorViewModel>().baudRate;
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
                          'Auto-Baud Rate Detection',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        subtitle: const Text(
                          'สลับค้นหาความเร็ว 4800 / 9600 อัตโนมัติเมื่อไม่พบข้อมูล',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        value: vm.isAutoBaudActive,
                        activeColor: Colors.cyanAccent,
                        onChanged: (val) => vm.toggleAutoBaud(val),
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
                          Text(
                            '8-N-1 (Half-Duplex RS485)',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
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
                          Text(
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

              // Section 5: Troubleshooting Guide for Real Sensor Hardware
              const Text(
                'ข้อแนะนำในการเชื่อมต่อเซนเซอร์จริง (Troubleshooting)',
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
                  '1. เปิดใช้งาน OTG บนสมาร์ตโฟน:\n'
                  '   มือถือระบบ Android (เช่น Oppo, Vivo, Realme, Xiaomi) ต้องเข้าไปที่การตั้งค่า (Settings) -> การตั้งค่าเพิ่มเติม (Additional Settings) -> เปิด "การเชื่อมต่อ OTG" (OTG Connection: ON)\n\n'
                  '2. ตรวจสอบความเร็ว Baud Rate:\n'
                  '   หัววัดคุณภาพดิน 7-in-1 / 8-in-1 ส่วนใหญ่ถูกโปรแกรมมาจากโรงงานด้วยความเร็ว 4800 bps หรือ 9600 bps หากค่าไม่ขึ้น ให้กดปุ่ม [9600 bps] ด้านบน\n\n'
                  '3. การเชื่อมต่อสายสัญญาณ RS485:\n'
                  '   • สายสีน้ำตาล (VCC): ไฟเลี้ยง +5V ถึง +12V DC\n'
                  '   • สายสีดำ (GND): กราวด์ 0V\n'
                  '   • สายสีเหลือง (A+ / 485+): สัญญาณข้อมูล A\n'
                  '   • สายสีน้ำเงิน (B- / 485-): สัญญาณข้อมูล B\n\n'
                  '4. ปักหัววัดลงในดินที่มีความชื้น เพื่อให้เซนเซอร์วัดค่าได้ครบทุกพารามิเตอร์',
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
